import 'package:get_it/get_it.dart';
import 'package:flutter/foundation.dart';
import 'package:nt_helper/core/routing/routing_factory.dart';
import 'package:nt_helper/core/routing/port_compatibility_validator.dart';
import 'package:nt_helper/core/routing/algorithm_routing.dart';
import 'package:nt_helper/core/routing/models/algorithm_routing_metadata.dart';
import 'package:nt_helper/services/haptic_feedback_service.dart';

/// Service locator configuration for routing-related dependencies.
///
/// This class provides a centralized way to register and configure routing
/// dependencies with the get_it service locator. It follows best practices
/// for dependency injection and provides a clean API for setting up routing
/// services.
///
/// Example usage:
/// ```dart
/// // Setup during app initialization
/// await RoutingServiceLocator.setup();
///
/// // Use in your code
/// final factory = RoutingServiceLocator.routingFactory;
/// final routing = factory.createRouting(metadata);
///
/// // Or get a routing instance directly
/// final routing = RoutingServiceLocator.getRouting(metadata);
///
/// // Clean up when shutting down
/// await RoutingServiceLocator.reset();
/// ```
class RoutingServiceLocator {
  static final GetIt _getIt = GetIt.instance;

  /// Whether the service locator has been set up
  static bool get isSetup => _getIt.isRegistered<RoutingFactory>();

  /// Gets the RoutingFactory instance from the service locator
  static RoutingFactory get routingFactory => _getIt<RoutingFactory>();

  /// Gets the PortCompatibilityValidator instance from the service locator
  static PortCompatibilityValidator get portValidator =>
      _getIt<PortCompatibilityValidator>();

  /// Gets the HapticFeedbackService instance from the service locator
  static IHapticFeedbackService get hapticFeedbackService =>
      _getIt<IHapticFeedbackService>();

  /// Sets up all routing-related dependencies in the service locator.
  ///
  /// This method should be called during app initialization, before any
  /// routing functionality is used. It registers:
  /// - PortCompatibilityValidator as a singleton
  /// - RoutingFactory as a singleton (using the validator)
  /// - HapticFeedbackService as a singleton
  ///
  /// Parameters:
  /// - [customValidator]: Optional custom port compatibility validator.
  ///   If not provided, a default validator will be used.
  /// - [customFactory]: Optional custom routing factory. If not provided,
  ///   a default factory will be created using the validator.
  ///
  /// Throws: [StateError] if setup is called when already initialized
  static Future<void> setup({
    PortCompatibilityValidator? customValidator,
    RoutingFactory? customFactory,
  }) async {
    if (isSetup) {
      throw StateError(
        'RoutingServiceLocator is already set up. Call reset() first if you need to reconfigure.',
      );
    }

    debugPrint('RoutingServiceLocator: Setting up routing dependencies');

    // Register port compatibility validator as singleton
    final validator = customValidator ?? PortCompatibilityValidator();
    _getIt.registerSingleton<PortCompatibilityValidator>(validator);
    debugPrint('RoutingServiceLocator: Registered PortCompatibilityValidator');

    // Register routing factory as singleton
    final factory = customFactory ?? RoutingFactory(validator: validator);
    _getIt.registerSingleton<RoutingFactory>(factory);
    debugPrint('RoutingServiceLocator: Registered RoutingFactory');

    // Register haptic feedback service as singleton
    final hapticService = HapticFeedbackService();
    _getIt.registerSingleton<IHapticFeedbackService>(hapticService);
    debugPrint('RoutingServiceLocator: Registered HapticFeedbackService');

    debugPrint('RoutingServiceLocator: Setup complete');
  }

  /// Convenience method to get a routing instance directly.
  ///
  /// This method combines getting the factory and creating a routing instance
  /// in one call, providing a simpler API for consumers who just need a
  /// routing instance.
  ///
  /// Parameters:
  /// - [metadata]: The algorithm routing metadata
  /// - [validator]: Optional validator to override the factory's default
  ///
  /// Returns: An [AlgorithmRouting] instance configured according to the metadata
  ///
  /// Throws: [StateError] if the service locator hasn't been set up
  static AlgorithmRouting getRouting(
    AlgorithmRoutingMetadata metadata, {
    PortCompatibilityValidator? validator,
  }) {
    _ensureSetup();
    return routingFactory.createRouting(metadata, validator: validator);
  }

  /// Convenience method to get a validated routing instance directly.
  ///
  /// This method performs metadata validation before creating the routing
  /// instance, providing additional safety.
  ///
  /// Parameters:
  /// - [metadata]: The algorithm routing metadata
  /// - [validator]: Optional validator to override the factory's default
  ///
  /// Returns: An [AlgorithmRouting] instance configured according to the metadata
  ///
  /// Throws:
  /// - [StateError] if the service locator hasn't been set up
  /// - [RoutingFactoryException] if the metadata is invalid
  static AlgorithmRouting getValidatedRouting(
    AlgorithmRoutingMetadata metadata, {
    PortCompatibilityValidator? validator,
  }) {
    _ensureSetup();
    return routingFactory.createValidatedRouting(
      metadata,
      validator: validator,
    );
  }

  /// Analyzes metadata using the registered factory.
  ///
  /// This provides access to the factory's metadata analysis capabilities
  /// through the service locator.
  ///
  /// Parameters:
  /// - [metadata]: The algorithm routing metadata to analyze
  ///
  /// Returns: A list of suggestions and potential issues
  ///
  /// Throws: [StateError] if the service locator hasn't been set up
  static List<String> analyzeMetadata(AlgorithmRoutingMetadata metadata) {
    _ensureSetup();
    return routingFactory.analyzeMetadata(metadata);
  }

  /// Validates metadata using the registered factory.
  ///
  /// Parameters:
  /// - [metadata]: The algorithm routing metadata to validate
  ///
  /// Returns: true if the metadata is valid, false otherwise
  ///
  /// Throws: [StateError] if the service locator hasn't been set up
  static bool validateMetadata(AlgorithmRoutingMetadata metadata) {
    _ensureSetup();
    return routingFactory.validateMetadata(metadata);
  }

  /// Resets the service locator, removing all routing-related registrations.
  ///
  /// This method should be called during app shutdown or when you need to
  /// reconfigure the routing dependencies. After calling this method,
  /// [setup] must be called again before using any routing functionality.
  ///
  /// This method is safe to call even if the service locator hasn't been
  /// set up or has already been reset.
  static Future<void> reset() async {
    debugPrint('RoutingServiceLocator: Resetting routing dependencies');

    // Unregister in reverse order of registration to handle dependencies properly
    if (_getIt.isRegistered<IHapticFeedbackService>()) {
      await _getIt.unregister<IHapticFeedbackService>();
      debugPrint('RoutingServiceLocator: Unregistered HapticFeedbackService');
    }

    if (_getIt.isRegistered<RoutingFactory>()) {
      await _getIt.unregister<RoutingFactory>();
      debugPrint('RoutingServiceLocator: Unregistered RoutingFactory');
    }

    if (_getIt.isRegistered<PortCompatibilityValidator>()) {
      await _getIt.unregister<PortCompatibilityValidator>();
      debugPrint(
        'RoutingServiceLocator: Unregistered PortCompatibilityValidator',
      );
    }

    debugPrint('RoutingServiceLocator: Reset complete');
  }

  /// Ensures the service locator has been set up, throwing an error if not.
  static void _ensureSetup() {
    if (!isSetup) {
      throw StateError(
        'RoutingServiceLocator has not been set up. Call RoutingServiceLocator.setup() first.',
      );
    }
  }

  /// Advanced registration method for custom scenarios.
  ///
  /// This method provides more control over the registration process and
  /// allows for custom registration patterns. Use this if you need to
  /// register dependencies with custom lifecycle management or if you
  /// need to integrate with existing DI setup.
  ///
  /// Parameters:
  /// - [registerValidator]: Function to register the validator
  /// - [registerFactory]: Function to register the factory
  ///
  /// Example:
  /// ```dart
  /// await RoutingServiceLocator.setupAdvanced(
  ///   registerValidator: (getIt) {
  ///     // Custom validator registration
  ///     getIt.registerLazySingleton<PortCompatibilityValidator>(
  ///       () => MyCustomValidator(),
  ///     );
  ///   },
  ///   registerFactory: (getIt) {
  ///     // Custom factory registration
  ///     getIt.registerFactory<RoutingFactory>(
  ///       () => RoutingFactory(validator: getIt<PortCompatibilityValidator>()),
  ///     );
  ///   },
  /// );
  /// ```
  static Future<void> setupAdvanced({
    required void Function(GetIt getIt) registerValidator,
    required void Function(GetIt getIt) registerFactory,
  }) async {
    if (isSetup) {
      throw StateError(
        'RoutingServiceLocator is already set up. Call reset() first if you need to reconfigure.',
      );
    }

    debugPrint(
      'RoutingServiceLocator: Setting up routing dependencies (advanced)',
    );

    registerValidator(_getIt);
    debugPrint(
      'RoutingServiceLocator: Custom PortCompatibilityValidator registered',
    );

    registerFactory(_getIt);
    debugPrint('RoutingServiceLocator: Custom RoutingFactory registered');

    debugPrint('RoutingServiceLocator: Advanced setup complete');
  }

  /// Gets diagnostic information about the current registration state.
  ///
  /// This method is useful for debugging and monitoring the service locator
  /// state during development.
  ///
  /// Returns: A map containing registration status and dependency information
  static Map<String, dynamic> getDiagnostics() {
    return {
      'isSetup': isSetup,
      'validatorRegistered': _getIt.isRegistered<PortCompatibilityValidator>(),
      'factoryRegistered': _getIt.isRegistered<RoutingFactory>(),
      'totalRegistrations':
          'N/A', // GetIt doesn't provide a direct count method
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

/// Extension methods for easier integration with existing get_it setups
extension GetItRoutingExtensions on GetIt {
  /// Registers routing dependencies using the standard pattern.
  ///
  /// This extension method allows you to register routing dependencies
  /// directly on your existing GetIt instance if you prefer not to use
  /// the RoutingServiceLocator wrapper.
  ///
  /// Example:
  /// ```dart
  /// final getIt = GetIt.instance;
  /// getIt.registerRoutingDependencies();
  ///
  /// // Later, use the dependencies
  /// final factory = getIt<RoutingFactory>();
  /// final routing = factory.createRouting(metadata);
  /// ```
  void registerRoutingDependencies({
    PortCompatibilityValidator? customValidator,
    RoutingFactory? customFactory,
  }) {
    // Register validator
    final validator = customValidator ?? PortCompatibilityValidator();
    registerSingleton<PortCompatibilityValidator>(validator);

    // Register factory
    final factory = customFactory ?? RoutingFactory(validator: validator);
    registerSingleton<RoutingFactory>(factory);
  }

  /// Unregisters routing dependencies.
  ///
  /// This extension method provides a convenient way to clean up routing
  /// dependencies from your GetIt instance.
  Future<void> unregisterRoutingDependencies() async {
    if (isRegistered<RoutingFactory>()) {
      await unregister<RoutingFactory>();
    }

    if (isRegistered<PortCompatibilityValidator>()) {
      await unregister<PortCompatibilityValidator>();
    }
  }
}
