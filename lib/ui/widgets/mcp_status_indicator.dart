import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nt_helper/services/mcp_server_service.dart';
import 'package:nt_helper/services/settings_service.dart';

/// Small round LED indicator for MCP server status with tooltip
class McpStatusIndicator extends StatelessWidget {
  static const int mcpPort = 3000;

  const McpStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService(); // Get SettingsService instance
    final mcpInstance =
        McpServerService.instance; // Get McpServerService instance
    final isRunning = context.watch<McpServerService>().isRunning;
    final baseColor = isRunning ? Colors.green.shade600 : Colors.grey.shade600;
    final highlightColor = isRunning
        ? Colors.green.shade300
        : Colors.grey.shade400;
    final shadowColor = isRunning
        ? Colors.green.shade800
        : Colors.grey.shade800;

    final tooltip = isRunning
        ? 'MCP server running at http://localhost:$mcpPort (Tap to disable)'
        : 'MCP server is disabled (Tap to enable)';

    return GestureDetector(
      onTap: () async {
        // Check if on supported platform first
        if (!(Platform.isMacOS || Platform.isWindows)) {
          debugPrint("[McpIndicatorTap] Not on MacOS/Windows. Toggle ignored.");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "MCP Service can only be toggled on macOS or Windows.",
              ),
            ),
          );
          return;
        }

        final bool currentMcpSetting = settings.mcpEnabled;
        final newMcpSetting = !currentMcpSetting;
        await settings.setMcpEnabled(newMcpSetting);
        debugPrint(
          "[McpIndicatorTap] Toggled MCP setting. Old: $currentMcpSetting, New: $newMcpSetting",
        );

        // Now apply the logic to start/stop the server
        final bool isServerCurrentlyRunning = mcpInstance.isRunning;
        debugPrint(
          "[McpIndicatorTap] Server was running: $isServerCurrentlyRunning. New MCP setting: $newMcpSetting",
        );

        if (newMcpSetting) {
          // Try to turn ON
          if (!isServerCurrentlyRunning) {
            debugPrint(
              "[McpIndicatorTap] MCP Setting is ON, Server is OFF. Attempting to START server.",
            );
            await mcpInstance.start().catchError((e) {
              debugPrint('[McpIndicatorTap] Error starting MCP Server: $e');
            });
            debugPrint(
              "[McpIndicatorTap] MCP Server START attempt finished. Now Running: ${mcpInstance.isRunning}",
            );
          } else {
            debugPrint(
              "[McpIndicatorTap] MCP Setting is ON, Server is ALREADY ON. No action taken. Running: ${mcpInstance.isRunning}",
            );
          }
        } else {
          // Try to turn OFF
          if (isServerCurrentlyRunning) {
            debugPrint(
              "[McpIndicatorTap] MCP Setting is OFF, Server is ON. Attempting to STOP server.",
            );
            await mcpInstance.stop().catchError((e) {
              debugPrint('[McpIndicatorTap] Error stopping MCP Server: $e');
            });
            debugPrint(
              "[McpIndicatorTap] MCP Server STOP attempt finished. Now Running: ${mcpInstance.isRunning}",
            );
          } else {
            debugPrint(
              "[McpIndicatorTap] MCP Setting is OFF, Server is ALREADY OFF. No action taken. Running: ${mcpInstance.isRunning}",
            );
          }
        }
        // McpServerService.notifyListeners() is called by start()/stop(), which Consumer listens to.
      },
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 16, // Slightly larger for better effect
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(
                -0.3,
                -0.4,
              ), // Offset center for top-right light source
              radius: 0.9,
              colors: [highlightColor, baseColor, shadowColor],
              stops: const [0.0, 0.6, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(77),
                blurRadius: 2,
                offset: const Offset(1, 1),
              ),
            ],
          ),
          child: Center(
            // For specular highlight
            child: Container(
              width: 5, // Size of specular highlight
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(179),
              ),
              margin: const EdgeInsets.only(
                right: 3,
                bottom: 3,
              ), // Position highlight
            ),
          ),
        ),
      ),
    );
  }
}
