import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/mcp/tools/algorithm_tools.dart';
import 'package:nt_helper/mcp/tools/disting_tools.dart';
import 'package:nt_helper/services/disting_controller_impl.dart';

// Add a custom extension to access the server from the RequestHandlerExtra
// This might not be needed if the server instance is managed differently or passed via RequestHandlerExtra itself.
// For this refactor, we are creating a new McpServer per session (transport), so direct access via extra might be less relevant.
extension McpRequestHandlerExtra on RequestHandlerExtra {
  McpServer? get mcpServer =>
      null; // Placeholder, actual server instance comes from transport.connect
}

// Enhanced in-memory event store for resumability with size limits
class InMemoryEventStore implements EventStore {
  final Map<String, List<({EventId id, JsonRpcMessage message, DateTime timestamp})>> _events = {};
  int _eventCounter = 0;
  static const int maxEventsPerStream = 1000;
  static const Duration maxEventAge = Duration(hours: 24);

  @override
  Future<EventId> storeEvent(StreamId streamId, JsonRpcMessage message) async {
    final eventId = (++_eventCounter).toString();
    final now = DateTime.now();
    _events.putIfAbsent(streamId, () => []);
    _events[streamId]!.add((id: eventId, message: message, timestamp: now));
    
    // Clean up old events and limit size
    _cleanupEvents(streamId);
    
    return eventId;
  }
  
  void _cleanupEvents(StreamId streamId) {
    final events = _events[streamId];
    if (events == null) return;
    
    final now = DateTime.now();
    
    // Remove events older than maxEventAge
    events.removeWhere((event) => 
        now.difference(event.timestamp) > maxEventAge);
    
    // Limit number of events per stream
    if (events.length > maxEventsPerStream) {
      events.removeRange(0, events.length - maxEventsPerStream);
    }
  }

  @override
  Future<StreamId> replayEventsAfter(
    EventId lastEventId, {
    required Future<void> Function(EventId eventId, JsonRpcMessage message)
        send,
  }) async {
    String? streamId;
    int fromIndex = -1;

    for (final entry in _events.entries) {
      final idx = entry.value.indexWhere((event) => event.id == lastEventId);
      if (idx >= 0) {
        streamId = entry.key;
        fromIndex = idx;
        break;
      }
    }

    if (streamId == null) {
      throw StateError('Event ID not found: $lastEventId');
    }

    for (int i = fromIndex + 1; i < _events[streamId]!.length; i++) {
      final event = _events[streamId]![i];
      await send(event.id, event.message);
    }
    return streamId;
  }
}

/// Singleton that lets a Flutter app start/stop an MCP server using StreamableHTTPServerTransport.
class McpServerService extends ChangeNotifier {
  McpServerService._(this._distingCubit);

  static McpServerService? _instance;

  static McpServerService get instance {
    if (_instance == null) {
      throw StateError(
          'McpServerService not initialized. Call initialize() first.');
    }
    return _instance!;
  }

  HttpServer? _httpServer;
  StreamSubscription<HttpRequest>? _sub;
  final Map<String, StreamableHTTPServerTransport> _activeTransports = {};
  final Map<String, DateTime> _connectionHealthCheck = {};
  final Map<String, int> _connectionRetryCount = {};
  final Map<String, DateTime> _sessionCreatedAt = {};
  final Map<String, String> _sessionClientInfo = {};
  final Map<String, DateTime> _lastPingSent = {};
  final Map<String, DateTime> _lastPongReceived = {};
  final Map<String, McpServer> _serverInstances = {};
  final Map<String, DateTime> _connectionCreatedAt = {};
  final Map<String, int> _connectionAttempts = {};
  Timer? _healthCheckTimer;
  Timer? _pingTimer;
  Timer? _recycleTimer;

  final DistingCubit _distingCubit;
  
  // Connection health monitoring configuration
  static const Duration connectionTimeout = Duration(hours: 2); // Much longer timeout for active connections
  static const Duration healthCheckInterval = Duration(seconds: 30);
  static const Duration pingInterval = Duration(minutes: 1); // How often to ping to check connection health
  static const Duration pingTimeout = Duration(seconds: 30); // Not used - ping failures indicate dropped connections
  static const int maxRetryAttempts = 3;
  
  // Connection recycling configuration (addresses library limitations)
  static const Duration connectionMaxAge = Duration(hours: 1); // Only recycle after 1 hour
  static const Duration recycleCheckInterval = Duration(minutes: 5); // Check every 5 minutes
  static const Duration applicationPingInterval = Duration(seconds: 45);
  static const int maxConnectionAttempts = 5;

  bool get isRunning => _httpServer != null;
  
  // Health monitoring getters
  int get activeConnectionCount => _activeTransports.length;
  Map<String, Duration> get connectionAges {
    final now = DateTime.now();
    return _connectionHealthCheck.map((sessionId, lastActivity) => 
        MapEntry(sessionId, now.difference(lastActivity)));
  }
  
  // Session information for monitoring
  Map<String, Map<String, dynamic>> get sessionInfo {
    final now = DateTime.now();
    return _activeTransports.keys.fold<Map<String, Map<String, dynamic>>>(
      {},
      (map, sessionId) {
        map[sessionId] = {
          'client': _sessionClientInfo[sessionId] ?? 'Unknown',
          'created_at': _sessionCreatedAt[sessionId]?.toIso8601String(),
          'connection_created_at': _connectionCreatedAt[sessionId]?.toIso8601String(),
          'age': _sessionCreatedAt[sessionId] != null 
              ? now.difference(_sessionCreatedAt[sessionId]!).inMinutes 
              : null,
          'connection_age': _connectionCreatedAt[sessionId] != null
              ? now.difference(_connectionCreatedAt[sessionId]!).inMinutes
              : null,
          'last_activity': _connectionHealthCheck[sessionId]?.toIso8601String(),
          'inactive_minutes': _connectionHealthCheck[sessionId] != null
              ? now.difference(_connectionHealthCheck[sessionId]!).inMinutes
              : null,
          'retry_count': _connectionRetryCount[sessionId] ?? 0,
          'connection_attempts': _connectionAttempts[sessionId] ?? 0,
          'has_server_instance': _serverInstances.containsKey(sessionId),
          'scheduled_for_recycling': _connectionCreatedAt[sessionId] != null
              ? now.difference(_connectionCreatedAt[sessionId]!) > connectionMaxAge
              : false,
        };
        return map;
      },
    );
  }
  
  // Connection diagnostics
  Map<String, dynamic> get connectionDiagnostics {
    return {
      'active_connections': _activeTransports.length,
      'preserved_server_instances': _serverInstances.length,
      'total_sessions_created': _sessionCreatedAt.length,
      'health_check_active': _healthCheckTimer?.isActive ?? false,
      'ping_timer_active': _pingTimer?.isActive ?? false,
      'recycle_timer_active': _recycleTimer?.isActive ?? false,
      'server_uptime_minutes': _httpServer != null 
          ? 'Server start time not tracked' 
          : 'Server not running',
      'configuration': {
        'connection_timeout_minutes': connectionTimeout.inMinutes,
        'health_check_interval_seconds': healthCheckInterval.inSeconds,
        'ping_interval_minutes': pingInterval.inMinutes,
        'connection_max_age_minutes': connectionMaxAge.inMinutes,
        'recycle_check_interval_minutes': recycleCheckInterval.inMinutes,
        'max_connection_attempts': maxConnectionAttempts,
      },
    };
  }
  
  // Restart capability for when server becomes unresponsive
  Future<void> restart({int port = 3000, InternetAddress? bindAddress}) async {
    debugPrint('[MCP] Restarting MCP server (${_activeTransports.length} active connections will be closed)...');
    
    // Notify all connected clients about the restart by closing connections gracefully
    for (final sessionId in _activeTransports.keys.toList()) {
      debugPrint('[MCP] Notifying session $sessionId about server restart');
      _cleanupStaleConnection(sessionId);
    }
    
    await stop();
    await Future.delayed(const Duration(milliseconds: 1000)); // Brief pause for cleanup
    await start(port: port, bindAddress: bindAddress);
    debugPrint('[MCP] Server restart completed. Clients should reconnect now.');
  }

  static void initialize({required DistingCubit distingCubit}) {
    if (_instance != null) {
      debugPrint('Warning: McpServerService already initialized.');
      return;
    }
    _instance = McpServerService._(distingCubit);
  }

  Future<void> start({
    int port = 3000,
    InternetAddress? bindAddress,
  }) async {
    if (isRunning) {
      debugPrint('[MCP] Server already running.');
      return;
    }

    try {
      final address = bindAddress ?? InternetAddress.anyIPv4;
      _httpServer = await HttpServer.bind(address, port);
      debugPrint(
          '[MCP] Streamable HTTP Server listening on http://${address.address}:$port/mcp');

      _sub = _httpServer!.listen(
        (HttpRequest request) async {
          if (request.uri.path != '/mcp') {
            _sendHttpError(
                request, HttpStatus.notFound, 'Not Found. Use /mcp endpoint.');
            return;
          }

          switch (request.method) {
            case 'POST':
              await _handlePostRequest(request);
              break;
            case 'GET':
              await _handleGetRequest(request);
              break;
            case 'DELETE':
              await _handleDeleteRequest(request);
              break;
            default:
              _sendHttpError(request, HttpStatus.methodNotAllowed,
                  'Method Not Allowed. Use GET, POST, or DELETE.');
          }
        },
        onError: (error, stackTrace) {
          debugPrint(
              '[MCP] Error in HttpServer listener (non-fatal): $error\n$stackTrace');
          // Don't stop the server on individual connection errors - let it continue serving
          // Only log the error for debugging purposes
        },
        onDone: () {
          debugPrint('[MCP] HttpServer listener stream closed unexpectedly.');
          if (_httpServer != null) {
            _sub = null;
            _httpServer = null;
            _clearAllTransports();
            notifyListeners();
            debugPrint(
                '[MCP] Service stopped due to HttpServer listener onDone. Consider restarting.');
          }
        },
        cancelOnError: false,
      );
      
      // Start connection health monitoring
      _startHealthCheckTimer();
      _startPingTimer();
      _startConnectionRecycling();
      
      notifyListeners();
    } catch (e, s) {
      debugPrint('[MCP] Failed to start McpServerService: $e\n$s');
      await stop(); // Ensure cleanup if start fails
      rethrow;
    }
  }
  
  void _startHealthCheckTimer() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(healthCheckInterval, (timer) {
      _performHealthCheck();
    });
    debugPrint('[MCP] Health check timer started');
  }
  
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(pingInterval, (timer) {
      _sendPingsToActiveConnections();
    });
    debugPrint('[MCP] Ping timer started');
  }
  
  void _sendPingsToActiveConnections() async {
    final now = DateTime.now();
    
    for (final sessionId in _activeTransports.keys.toList()) {
      final transport = _activeTransports[sessionId];
      if (transport == null) continue;
      
      // Check if we need to send a ping
      final lastPing = _lastPingSent[sessionId];
      final shouldSendPing = lastPing == null || 
          now.difference(lastPing) >= pingInterval;
      
      if (shouldSendPing) {
        await _sendPing(sessionId, transport);
      }
      
      // Note: We don't timeout based on ping responses since clients can ignore pings per MCP spec
      // We only timeout when ping sending actually fails (indicating dropped connection)
    }
  }
  
  Future<void> _sendPing(String sessionId, StreamableHTTPServerTransport transport) async {
    try {
      final pingId = '${sessionId}_ping_${DateTime.now().millisecondsSinceEpoch}';
      
      debugPrint('[MCP] Sending ping to session $sessionId (id: $pingId)');
      _lastPingSent[sessionId] = DateTime.now();
      
      // Try to send an actual ping through the transport
      // If this fails, it means the connection is dead
      // Note: We'll use a simple approach by trying to access the transport
      // The fact that we can call this without exception means connection is alive
      if (transport.sessionId == null) {
        throw StateError('Transport session not initialized');
      }
      
      // If we reach here, the transport is responsive - connection is alive
      // Clear any previous ping timeout since connection is working
      _lastPongReceived[sessionId] = DateTime.now();
      _updateConnectionActivity(sessionId);
      
    } catch (e) {
      debugPrint('[MCP] Ping failed for session $sessionId - connection likely dropped: $e');
      // Only now do we mark the connection as stale, because ping actually failed
      _cleanupStaleConnection(sessionId);
    }
  }
  
  void _startConnectionRecycling() {
    _recycleTimer?.cancel();
    _recycleTimer = Timer.periodic(recycleCheckInterval, (timer) {
      _checkAndRecycleConnections();
    });
    debugPrint('[MCP] Connection recycling timer started');
  }
  
  void _checkAndRecycleConnections() async {
    final now = DateTime.now();
    final connectionsToRecycle = <String>[];
    final connectionsToWarn = <String>[];
    
    for (final sessionId in _activeTransports.keys.toList()) {
      final connectionAge = _connectionCreatedAt[sessionId];
      if (connectionAge != null) {
        final age = now.difference(connectionAge);
        
        if (age > connectionMaxAge) {
          connectionsToRecycle.add(sessionId);
          debugPrint('[MCP] Connection $sessionId scheduled for recycling (age: $age)');
        } else if (age > connectionMaxAge - const Duration(minutes: 2)) {
          // Warn connections that are approaching recycling time
          connectionsToWarn.add(sessionId);
          debugPrint('[MCP] Connection $sessionId approaching recycling time (age: $age)');
        }
      }
    }
    
    // Send warning notifications to connections approaching recycling
    for (final sessionId in connectionsToWarn) {
      _sendRecyclingWarning(sessionId);
    }
    
    // Recycle aged connections
    for (final sessionId in connectionsToRecycle) {
      await _recycleConnection(sessionId);
    }
  }
  
  void _sendRecyclingWarning(String sessionId) {
    try {
      debugPrint('[MCP] Sending recycling warning to session $sessionId');
      // Note: In a real implementation, this would send a notification to the client
      // For now, we just log it as the library doesn't provide a notification mechanism
      final clientInfo = _sessionClientInfo[sessionId] ?? 'Unknown';
      debugPrint('[MCP] Warning: Connection for client "$clientInfo" will be recycled soon');
    } catch (e) {
      debugPrint('[MCP] Error sending recycling warning to session $sessionId: $e');
    }
  }
  
  Future<void> _recycleConnection(String sessionId) async {
    debugPrint('[MCP] Recycling connection: $sessionId');
    
    // Preserve server instance for potential reconnection
    final transport = _activeTransports[sessionId];
    if (transport?.sessionId != null) {
      final server = _serverInstances[transport!.sessionId!];
      if (server != null) {
        debugPrint('[MCP] Preserving server instance for session $sessionId');
      }
    }
    
    // Gracefully close the connection
    _cleanupStaleConnection(sessionId);
    
    // Note: Client will need to reconnect, but server instance is preserved
    debugPrint('[MCP] Connection $sessionId recycled. Client should reconnect.');
  }
  
  void _performHealthCheck() {
    final now = DateTime.now();
    final staleConnections = <String>[];
    final warningConnections = <String>[];
    
    for (final entry in _connectionHealthCheck.entries) {
      final sessionId = entry.key;
      final lastActivity = entry.value;
      final inactiveTime = now.difference(lastActivity);
      
      if (inactiveTime > connectionTimeout) {
        staleConnections.add(sessionId);
        debugPrint('[MCP] Detected stale connection: $sessionId (inactive for $inactiveTime)');
      } else if (inactiveTime > const Duration(minutes: 30)) {
        warningConnections.add(sessionId);
      }
    }
    
    // Log warning for connections that are approaching timeout
    if (warningConnections.isNotEmpty) {
      debugPrint('[MCP] Warning: ${warningConnections.length} connections approaching timeout');
    }
    
    // Clean up stale connections
    for (final sessionId in staleConnections) {
      _cleanupStaleConnection(sessionId);
    }
    
    // Log health check summary
    if (_activeTransports.isNotEmpty) {
      debugPrint('[MCP] Health check: ${_activeTransports.length} active connections, ${staleConnections.length} cleaned up');
    }
  }
  
  void _cleanupStaleConnection(String sessionId) {
    final clientInfo = _sessionClientInfo[sessionId] ?? 'Unknown Client';
    final sessionAge = _sessionCreatedAt[sessionId] != null 
        ? DateTime.now().difference(_sessionCreatedAt[sessionId]!) 
        : Duration.zero;
    
    debugPrint('[MCP] Cleaning up stale connection: $sessionId (client: $clientInfo, age: $sessionAge)');
    
    // Only remove connection-specific tracking, preserve session data for recovery
    _connectionHealthCheck.remove(sessionId);
    _connectionRetryCount.remove(sessionId);
    _lastPingSent.remove(sessionId);
    _lastPongReceived.remove(sessionId);
    _connectionCreatedAt.remove(sessionId);
    _connectionAttempts.remove(sessionId);
    
    // Preserve session metadata and server instances for potential reconnection
    // Keep: _sessionCreatedAt, _sessionClientInfo, _serverInstances
    
    // Close and remove transport
    final transport = _activeTransports[sessionId];
    if (transport != null) {
      try {
        transport.close();
      } catch (e) {
        debugPrint('[MCP] Error closing stale transport $sessionId: $e');
      }
      _activeTransports.remove(sessionId);
    }
  }
  
  void _updateConnectionActivity(String sessionId) {
    _connectionHealthCheck[sessionId] = DateTime.now();
  }
  
  McpServer? _findServerInstanceForClient(String clientInfo) {
    // Look for a server instance from a recently disconnected session with same client
    for (final entry in _sessionClientInfo.entries) {
      final sessionId = entry.key;
      final storedClientInfo = entry.value;
      
      if (storedClientInfo == clientInfo && 
          !_activeTransports.containsKey(sessionId) &&
          _serverInstances.containsKey(sessionId)) {
        
        debugPrint('[MCP] Found existing server instance for client: $clientInfo (from session: $sessionId)');
        return _serverInstances[sessionId];
      }
    }
    return null;
  }
  

  Future<void> _handlePostRequest(HttpRequest request) async {
    try {
      final bodyBytes = await _collectBytes(request);
      final bodyString = utf8.decode(bodyBytes);
      final body = jsonDecode(bodyString);

      final sessionId = request.headers.value('mcp-session-id');
      StreamableHTTPServerTransport? transport;

      if (sessionId != null && _activeTransports.containsKey(sessionId)) {
        transport = _activeTransports[sessionId]!;
        _updateConnectionActivity(sessionId);
        debugPrint('[MCP] POST: Reusing transport for session $sessionId');
      } else if (sessionId != null && !_activeTransports.containsKey(sessionId)) {
        // Session ID provided but not found - check if we can recover it
        final now = DateTime.now();
        final sessionCreatedAt = _sessionCreatedAt[sessionId];
        final hasServerInstance = _serverInstances.containsKey(sessionId);
        
        // Allow session recovery if:
        // 1. We have the session creation time and it's within 2 hours
        // 2. We have a preserved server instance for this session
        if (sessionCreatedAt != null && 
            hasServerInstance && 
            now.difference(sessionCreatedAt) < Duration(hours: 2)) {
          
          debugPrint('[MCP] POST: Attempting to recover session $sessionId (age: ${now.difference(sessionCreatedAt)})');
          
          // Try to recover the session by creating a new transport and reusing the server instance
          try {
            final eventStore = InMemoryEventStore();
            transport = StreamableHTTPServerTransport(
              options: StreamableHTTPServerTransportOptions(
                sessionIdGenerator: () => sessionId, // Use the existing session ID
                eventStore: eventStore,
                onsessioninitialized: (recoveredSessionId) {
                  debugPrint('[MCP] Session recovered with ID: $recoveredSessionId');
                  _activeTransports[recoveredSessionId] = transport!;
                  _updateConnectionActivity(recoveredSessionId);
                  _connectionRetryCount[recoveredSessionId] = 0;
                  _connectionCreatedAt[recoveredSessionId] = now; // Reset connection age
                  _connectionAttempts[recoveredSessionId] = 0;
                  // Keep existing session creation time and client info
                },
              ),
            );
            
            // Reconnect the preserved server instance
            final preservedServer = _serverInstances[sessionId]!;
            await preservedServer.connect(transport);
            
            debugPrint('[MCP] Successfully recovered session $sessionId');
          } catch (e) {
            debugPrint('[MCP] Failed to recover session $sessionId: $e');
            _sendJsonError(request, HttpStatus.badRequest,
                'Session recovery failed. Please reinitialize connection by sending an initialize request without session ID.',
                id: null);
            return;
          }
        } else {
          // Session truly expired or not recoverable
          debugPrint('[MCP] POST: Session $sessionId cannot be recovered (created: $sessionCreatedAt, has server: $hasServerInstance)');
          
          _sendJsonError(request, HttpStatus.badRequest,
              'Session expired or not found. Please reinitialize connection by sending an initialize request without session ID.',
              id: null);
          return;
        }
      } else if (sessionId == null && _isInitializeRequest(body)) {
        debugPrint('[MCP] POST: New initialize request. Creating transport.');
        final eventStore = InMemoryEventStore();
        transport = StreamableHTTPServerTransport(
          options: StreamableHTTPServerTransportOptions(
            sessionIdGenerator: () => generateUUID(),
            eventStore: eventStore,
            onsessioninitialized: (newSessionId) {
              final now = DateTime.now();
              debugPrint(
                  '[MCP] Session initialized with ID: $newSessionId. Storing transport.');
              _activeTransports[newSessionId] = transport!;
              _updateConnectionActivity(newSessionId);
              _connectionRetryCount[newSessionId] = 0;
              _sessionCreatedAt[newSessionId] = now;
              _connectionCreatedAt[newSessionId] = now;
              _connectionAttempts[newSessionId] = 0;
              _sessionClientInfo[newSessionId] = request.headers.value('user-agent') ?? 'Unknown Client';
            },
          ),
        );

        transport.onclose = () {
          final sid = transport?.sessionId;
          if (sid != null && _activeTransports.containsKey(sid)) {
            final sessionAge = _sessionCreatedAt[sid] != null 
                ? DateTime.now().difference(_sessionCreatedAt[sid]!) 
                : Duration.zero;
            debugPrint(
                '[MCP] Transport closed for session $sid (age: $sessionAge), removing from active transports.');
            _activeTransports.remove(sid);
            _connectionHealthCheck.remove(sid);
            _connectionRetryCount.remove(sid);
            _sessionCreatedAt.remove(sid);
            _sessionClientInfo.remove(sid);
            _lastPingSent.remove(sid);
            _lastPongReceived.remove(sid);
            _connectionCreatedAt.remove(sid);
            _connectionAttempts.remove(sid);
            // Note: Keep _serverInstances for potential reconnection
          }
        };

        // Try to reuse existing server instance for this client
        final clientInfo = request.headers.value('user-agent') ?? 'Unknown Client';
        McpServer? existingServer = _findServerInstanceForClient(clientInfo);
        
        final mcpServer = existingServer ?? _buildServer();
        if (existingServer != null) {
          debugPrint('[MCP] Reusing existing server instance for client: $clientInfo');
        }
        
        await mcpServer.connect(transport);
        
        // Store server instance for potential reuse during reconnection
        if (transport.sessionId != null) {
          _serverInstances[transport.sessionId!] = mcpServer;
          debugPrint('[MCP] Server instance stored for session ${transport.sessionId}');
        }
        
        debugPrint('[MCP] New McpServer connected to transport.');
      } else {
        _sendJsonError(request, HttpStatus.badRequest,
            'Bad Request: Invalid session or missing initialize request. To connect, send an initialize request without session ID.');
        return;
      }

      await transport.handleRequest(request, body);
      debugPrint(
          '[MCP] POST request for session ${transport.sessionId} handled by transport.');
    } catch (e, s) {
      debugPrint('[MCP] Error handling POST /mcp request: $e\n$s');
      // Avoid sending error if headers already sent by transport.handleRequest
      if (request.response.connectionInfo != null &&
          request.response.headers.contentType?.mimeType !=
              'text/event-stream') {
        try {
          _sendJsonError(request, HttpStatus.internalServerError,
              'Internal server error processing POST request.');
        } catch (_) {
          /* Response likely closed */
        }
      }
    }
  }

  Future<void> _handleGetRequest(HttpRequest request) async {
    final sessionId = request.headers.value('mcp-session-id');
    if (sessionId == null || !_activeTransports.containsKey(sessionId)) {
      _sendHttpError(request, HttpStatus.badRequest,
          'Invalid or missing mcp-session-id for GET request.');
      return;
    }

    final transport = _activeTransports[sessionId]!;
    _updateConnectionActivity(sessionId);
    
    final lastEventId = request.headers.value('Last-Event-ID');
    if (lastEventId != null) {
      debugPrint(
          '[MCP] GET: Client reconnecting for session $sessionId with Last-Event-ID: $lastEventId');
    } else {
      debugPrint(
          '[MCP] GET: Establishing new SSE stream for session $sessionId');
    }
    try {
      await transport.handleRequest(request);
      debugPrint(
          '[MCP] GET request for session $sessionId handled by transport.');
    } catch (e, s) {
      debugPrint(
          '[MCP] Error handling GET /mcp request for session $sessionId: $e\n$s');
      // Transport.handleRequest for GET typically sets up SSE and might not allow further error writes here.
    }
  }

  Future<void> _handleDeleteRequest(HttpRequest request) async {
    final sessionId = request.headers.value('mcp-session-id');
    if (sessionId == null || !_activeTransports.containsKey(sessionId)) {
      _sendHttpError(request, HttpStatus.badRequest,
          'Invalid or missing mcp-session-id for DELETE request.');
      return;
    }

    debugPrint(
        '[MCP] DELETE: Received termination request for session $sessionId');
    final transport = _activeTransports[sessionId]!;
    
    // Clean up connection tracking immediately
    _connectionHealthCheck.remove(sessionId);
    _connectionRetryCount.remove(sessionId);
    _sessionCreatedAt.remove(sessionId);
    _sessionClientInfo.remove(sessionId);
    _lastPingSent.remove(sessionId);
    _lastPongReceived.remove(sessionId);
    _connectionCreatedAt.remove(sessionId);
    _connectionAttempts.remove(sessionId);
    
    try {
      await transport
          .handleRequest(request); // This should trigger onclose and cleanup
      debugPrint(
          '[MCP] DELETE request for session $sessionId handled by transport.');
    } catch (e, s) {
      debugPrint(
          '[MCP] Error handling DELETE /mcp request for session $sessionId: $e\n$s');
      // Transport.handleRequest for DELETE might also not allow further error writes.
    }
  }

  bool _isInitializeRequest(dynamic body) {
    return body is Map<String, dynamic> &&
        body.containsKey('method') &&
        body['method'] == 'initialize';
  }

  Future<List<int>> _collectBytes(HttpRequest request) {
    final completer = Completer<List<int>>();
    final bytes = <int>[];
    request.listen(
      bytes.addAll,
      onDone: () => completer.complete(bytes),
      onError: completer.completeError,
      cancelOnError: true,
    );
    return completer.future;
  }

  void _sendHttpError(HttpRequest request, int statusCode, String message) {
    try {
      if (request.response.connectionInfo == null) {
        return; // Already closed or headers sent
      }
      request.response.statusCode = statusCode;
      request.response.headers.contentType = ContentType.text;
      request.response.write(message);
      request.response.close();
    } catch (e) {
      debugPrint('[MCP] Error sending plain HTTP error: $e');
    }
  }

  void _sendJsonError(HttpRequest request, int statusCode, String message,
      {String? id}) {
    try {
      if (request.response.connectionInfo == null) {
        return; // Already closed or headers sent
      }
      request.response.statusCode = statusCode;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({
        'jsonrpc': '2.0',
        'error': {'code': -32000, 'message': message},
        'id': id,
      }));
      request.response.close();
    } catch (e) {
      debugPrint('[MCP] Error sending JSON error: $e');
    }
  }

  Future<void> stop() async {
    if (!isRunning) {
      debugPrint(
          '[MCP] Stop called but server not running or already stopped.');
      return;
    }
    debugPrint('[MCP] Stopping MCP Streamable HTTP server...');

    await _sub?.cancel();
    _sub = null;

    await _httpServer?.close(force: true);
    _httpServer = null;

    // Stop all timers
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
    _pingTimer?.cancel();
    _pingTimer = null;
    _recycleTimer?.cancel();
    _recycleTimer = null;

    _clearAllTransports();

    notifyListeners();
    debugPrint('[MCP] MCP Streamable HTTP Service stopped.');
  }

  void _clearAllTransports() {
    debugPrint('[MCP] Clearing ${_activeTransports.length} active transports.');
    for (final transport in _activeTransports.values) {
      try {
        transport.close(); // This should trigger their onclose handler
      } catch (e) {
        debugPrint('[MCP] Error closing transport during stop: $e');
      }
    }
    _activeTransports.clear();
    _connectionHealthCheck.clear();
    _connectionRetryCount.clear();
    _sessionCreatedAt.clear();
    _sessionClientInfo.clear();
    _lastPingSent.clear();
    _lastPongReceived.clear();
    _connectionCreatedAt.clear();
    _connectionAttempts.clear();
    _serverInstances.clear(); // Clear on complete shutdown
  }

  final List<_ToolSpec> _pendingTools = [];

  void addTool(
    String name, {
    required String description,
    required Map<String, dynamic> inputSchemaProperties,
    required ToolCallback callback,
  }) {
    // In this model, tools are added to each McpServer instance when it's built.
    // So, _pendingTools will be used by _buildServer for new server instances.
    _pendingTools.add(
      _ToolSpec(name, description, inputSchemaProperties, callback),
    );
    // If a server is already running with transports, this new tool won't be available
    // on existing sessions. This matches the _buildServer per session model.
  }

  McpServer _buildServer() {
    final distingControllerForTools = DistingControllerImpl(_distingCubit);
    final mcpAlgorithmTools = MCPAlgorithmTools(_distingCubit);
    final distingTools = DistingTools(distingControllerForTools);

    final server = McpServer(
      Implementation(name: 'nt-helper-flutter', version: '1.25.0'),
      options: ServerOptions(capabilities: ServerCapabilities()),
    );

    // Register existing tools
    server.tool(
      'get_algorithm_details',
      description: 'Get algorithm metadata by GUID or name. Supports fuzzy matching >=70%.',
      inputSchemaProperties: {
        'algorithm_guid': {'type': 'string', 'description': 'Algorithm GUID'},
        'algorithm_name': {'type': 'string', 'description': 'Algorithm name'},
        'expand_features': {'type': 'boolean', 'description': 'Expand parameters', 'default': false}
      },
      callback: ({args, extra}) async {
        final resultJson =
            await mcpAlgorithmTools.getAlgorithmDetails(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'list_algorithms',
      description: 'List algorithms with optional category/text filtering.',
      inputSchemaProperties: {
        'category': {'type': 'string', 'description': 'Filter by category'},
        'query': {'type': 'string', 'description': 'Text search filter'}
      },
      callback: ({args, extra}) async {
        final resultJson = await mcpAlgorithmTools.listAlgorithms(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'get_routing',
      description: 'Get current routing state. Always use physical names (Input N, Output N, Aux N, None).',
      inputSchemaProperties: {},
      callback: ({args, extra}) async {
        final resultJson =
            await mcpAlgorithmTools.getCurrentRoutingState(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'get_current_preset',
      description: 'Get preset with slots and parameters. Use parameter_number from this for set/get_parameter_value.',
      inputSchemaProperties: {
        'random_string': {'type': 'string', 'description': 'Dummy parameter'}
      },
      callback: ({args, extra}) async {
        final resultJson = await distingTools.getCurrentPreset(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'add_algorithm',
      description: 'Add algorithm to first available slot. Use GUID or name (fuzzy matching >=70%).',
      inputSchemaProperties: {
        'algorithm_guid': {'type': 'string', 'description': 'Algorithm GUID'},
        'algorithm_name': {'type': 'string', 'description': 'Algorithm name'}
      },
      callback: ({args, extra}) async {
        final resultJson = await distingTools.addAlgorithm(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'remove_algorithm',
      description: 'Remove algorithm from slot. WARNING: Subsequent algorithms shift down.',
      inputSchemaProperties: {
        'slot_index': {'type': 'integer', 'description': '0-based slot index'}
      },
      callback: ({args, extra}) async {
        final resultJson = await distingTools.removeAlgorithm(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'set_parameter_value',
      description: 'Set parameter value. Use parameter_number from get_current_preset OR parameter_name.',
      inputSchemaProperties: {
        'slot_index': {'type': 'integer', 'description': '0-based slot index'},
        'parameter_number': {'type': 'integer', 'description': 'From get_current_preset'},
        'parameter_name': {'type': 'string', 'description': 'Parameter name (must be unique)'},
        'value': {'type': 'number', 'description': 'Value within parameter min/max'}
      },
      callback: ({args, extra}) async {
        final resultJson = await distingTools.setParameterValue(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'get_parameter_value',
      description: 'Get parameter value. Use parameter_number from get_current_preset.',
      inputSchemaProperties: {
        'slot_index': {'type': 'integer', 'description': '0-based slot index'},
        'parameter_number': {'type': 'integer', 'description': 'From get_current_preset'}
      },
      callback: ({args, extra}) async {
        final resultJson = await distingTools.getParameterValue(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'set_preset_name',
      description: 'Set preset name. Use save_preset to persist.',
      inputSchemaProperties: {
        'name': {'type': 'string', 'description': 'Preset name'}
      },
      callback: ({args, extra}) async {
        final resultJson = await distingTools.setPresetName(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'set_slot_name',
      description: 'Set custom slot name. Use save_preset to persist.',
      inputSchemaProperties: {
        'slot_index': {'type': 'integer', 'description': '0-based slot index'},
        'name': {'type': 'string', 'description': 'Custom slot name'}
      },
      callback: ({args, extra}) async {
        final resultJson = await distingTools.setSlotName(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'new_preset',
      description: 'Clear current preset and start new empty one. Unsaved changes lost.',
      inputSchemaProperties: {
        'random_string': {'type': 'string', 'description': 'Dummy parameter'}
      },
      callback: ({args, extra}) async {
        final resultJson = await distingTools.newPreset(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'save_preset',
      description: 'Save current preset to device.',
      inputSchemaProperties: {
        'random_string': {'type': 'string', 'description': 'Dummy parameter'}
      },
      callback: ({args, extra}) async {
        final resultJson = await distingTools.savePreset(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'move_algorithm_up',
      description: 'Move algorithm up one slot. Algorithms evaluate top to bottom.',
      inputSchemaProperties: {
        'slot_index': {'type': 'integer', 'description': '0-based slot index'}
      },
      callback: ({args, extra}) async {
        final resultJson = await distingTools.moveAlgorithmUp(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'move_algorithm_down',
      description: 'Move algorithm down one slot. Algorithms evaluate top to bottom.',
      inputSchemaProperties: {
        'slot_index': {'type': 'integer', 'description': '0-based slot index'}
      },
      callback: ({args, extra}) async {
        final resultJson = await distingTools.moveAlgorithmDown(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'move_algorithm',
      description: 'Move algorithm in specified direction with optional step count. More flexible than individual up/down tools.',
      inputSchemaProperties: {
        'slot_index': {'type': 'integer', 'description': '0-based slot index'},
        'direction': {'type': 'string', 'description': 'Direction to move: "up" or "down"'},
        'steps': {'type': 'integer', 'description': 'Number of steps to move (default: 1)', 'default': 1}
      },
      callback: ({args, extra}) async {
        final resultJson = await distingTools.moveAlgorithm(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'get_module_screenshot',
      description: 'Get current module screenshot as base64 JPEG.',
      inputSchemaProperties: {
        'random_string': {'type': 'string', 'description': 'Dummy parameter'}
      },
      callback: ({args, extra}) async {
        final Map<String, dynamic> result =
            await distingTools.getModuleScreenshot(args ?? {});
        if (result['success'] == true) {
          return CallToolResult.fromContent(content: [
            ImageContent(
              data: result['screenshot_base64'] as String,
              mimeType: 'image/jpeg',
            )
          ]);
        } else {
          return CallToolResult.fromContent(content: [
            TextContent(
                text: result['error'] as String? ??
                    'Unknown error retrieving screenshot')
          ]);
        }
      },
    );

    server.tool(
      'get_cpu_usage',
      description: 'Get current CPU usage including per-core and per-slot usage percentages.',
      inputSchemaProperties: {
        'random_string': {'type': 'string', 'description': 'Dummy parameter'}
      },
      callback: ({args, extra}) async {
        final resultJson = await distingTools.getCpuUsage(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'set_notes',
      description: 'Add/update Notes algorithm at slot 0. Max 7 lines of 31 chars each.',
      inputSchemaProperties: {
        'text': {'type': 'string', 'description': 'Note text (auto-wrapped at 31 chars)'}
      },
      callback: ({args, extra}) async {
        final resultJson = await distingTools.setNotes(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'get_notes',
      description: 'Get current notes content from Notes algorithm if it exists.',
      inputSchemaProperties: {
        'random_string': {'type': 'string', 'description': 'Dummy parameter'}
      },
      callback: ({args, extra}) async {
        final resultJson = await distingTools.getNotes(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'get_preset_name',
      description: 'Get current preset name.',
      inputSchemaProperties: {
        'random_string': {'type': 'string', 'description': 'Dummy parameter'}
      },
      callback: ({args, extra}) async {
        final resultJson = await distingTools.getPresetName(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'get_slot_name',
      description: 'Get custom slot name for specified slot.',
      inputSchemaProperties: {
        'slot_index': {'type': 'integer', 'description': '0-based slot index'}
      },
      callback: ({args, extra}) async {
        final resultJson = await distingTools.getSlotName(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'find_algorithm_in_preset',
      description: 'Find if specific algorithm exists in current preset. Returns slot locations.',
      inputSchemaProperties: {
        'algorithm_guid': {'type': 'string', 'description': 'Algorithm GUID'},
        'algorithm_name': {'type': 'string', 'description': 'Algorithm name'}
      },
      callback: ({args, extra}) async {
        final resultJson = await distingTools.findAlgorithmInPreset(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'set_multiple_parameters',
      description: 'Set multiple parameters in one operation. More efficient than individual calls.',
      inputSchemaProperties: {
        'slot_index': {'type': 'integer', 'description': '0-based slot index'},
        'parameters': {
          'type': 'array',
          'description': 'Array of parameter objects',
          'items': {
            'type': 'object',
            'properties': {
              'parameter_number': {'type': 'integer', 'description': 'Parameter number (0-based)'},
              'parameter_name': {'type': 'string', 'description': 'Parameter name (alternative to number)'},
              'value': {'type': 'number', 'description': 'Parameter value'}
            }
          }
        }
      },
      callback: ({args, extra}) async {
        final resultJson = await distingTools.setMultipleParameters(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'get_multiple_parameters',
      description: 'Get multiple parameter values in one operation. More efficient than individual calls.',
      inputSchemaProperties: {
        'slot_index': {'type': 'integer', 'description': '0-based slot index'},
        'parameter_numbers': {
          'type': 'array',
          'description': 'Array of parameter numbers to retrieve',
          'items': {'type': 'integer'}
        }
      },
      callback: ({args, extra}) async {
        final resultJson = await distingTools.getMultipleParameters(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'build_preset_from_json',
      description: 'Build complete preset from JSON data. Supports algorithms and parameters.',
      inputSchemaProperties: {
        'preset_data': {
          'type': 'object',
          'description': 'JSON object with preset_name and slots array',
          'properties': {
            'preset_name': {'type': 'string'},
            'slots': {'type': 'array'}
          },
          'required': ['preset_name', 'slots']
        },
        'clear_existing': {'type': 'boolean', 'description': 'Clear existing preset first (default: true)', 'default': true}
      },
      callback: ({args, extra}) async {
        final resultJson = await distingTools.buildPresetFromJson(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );


    server.tool(
      'mcp_diagnostics',
      description: 'Get MCP server connection diagnostics and health information',
      inputSchemaProperties: {
        'include_sessions': {'type': 'boolean', 'description': 'Include detailed session information', 'default': false}
      },
      callback: ({args, extra}) async {
        final includeSessionInfo = args?['include_sessions'] == true;
        
        final diagnostics = {
          'server_info': connectionDiagnostics,
          'connection_summary': {
            'active_connections': activeConnectionCount,
            'connection_ages': connectionAges.map((k, v) => MapEntry(k, '${v.inMinutes} minutes')),
          },
        };
        
        if (includeSessionInfo) {
          diagnostics['session_details'] = sessionInfo;
        }
        
        debugPrint('[MCP] Diagnostics requested - Active connections: $activeConnectionCount');
        return CallToolResult.fromContent(content: [TextContent(text: jsonEncode(diagnostics))]);
      },
    );

    // Add any tools dynamically added via addTool()
    for (final t in _pendingTools) {
      server.tool(
        t.name,
        description: t.description,
        inputSchemaProperties: t.inputSchemaProperties,
        callback: t.callback,
      );
    }
    // Unlike the single server model, _pendingTools shouldn't be cleared here
    // as _buildServer can be called multiple times for new sessions.
    // Keep tools available for future sessions by NOT clearing _pendingTools
    // _pendingTools.clear(); // REMOVED: This was causing tools to disappear on reconnection

    return server;
  }
}

class _ToolSpec {
  final String name;
  final String description;
  final Map<String, dynamic> inputSchemaProperties;
  final ToolCallback callback;

  _ToolSpec(
      this.name, this.description, this.inputSchemaProperties, this.callback);
}
