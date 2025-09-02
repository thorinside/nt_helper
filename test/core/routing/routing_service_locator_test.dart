import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_it/get_it.dart';
import 'package:nt_helper/core/routing/routing_service_locator.dart';
import 'package:nt_helper/core/routing/routing_factory.dart';
import 'package:nt_helper/core/routing/port_compatibility_validator.dart';
import 'package:nt_helper/core/routing/models/algorithm_routing_metadata.dart';
import 'package:nt_helper/core/routing/algorithm_routing.dart';
import 'package:nt_helper/core/routing/poly_algorithm_routing.dart';
import 'package:nt_helper/core/routing/multi_channel_algorithm_routing.dart';

@GenerateMocks([RoutingFactory, PortCompatibilityValidator])
import 'routing_service_locator_test.mocks.dart';

void main() {
  group('RoutingServiceLocator', () {
    late MockRoutingFactory mockFactory;
    late MockPortCompatibilityValidator mockValidator;

    setUp(() {
      mockFactory = MockRoutingFactory();
      mockValidator = MockPortCompatibilityValidator();
    });

    tearDown(() async {
      // Always reset the service locator after each test to ensure clean state
      await RoutingServiceLocator.reset();
    });

    group('Setup and Initialization', () {
      test('should not be setup initially', () {
        expect(RoutingServiceLocator.isSetup, isFalse);
      });

      test('should setup with default dependencies', () async {
        await RoutingServiceLocator.setup();

        expect(RoutingServiceLocator.isSetup, isTrue);
        expect(RoutingServiceLocator.routingFactory, isA<RoutingFactory>());
        expect(RoutingServiceLocator.portValidator, isA<PortCompatibilityValidator>());
      });

      test('should setup with custom validator', () async {
        await RoutingServiceLocator.setup(customValidator: mockValidator);

        expect(RoutingServiceLocator.isSetup, isTrue);
        expect(RoutingServiceLocator.portValidator, equals(mockValidator));
        expect(RoutingServiceLocator.routingFactory, isA<RoutingFactory>());
      });

      test('should setup with custom factory', () async {
        await RoutingServiceLocator.setup(customFactory: mockFactory);

        expect(RoutingServiceLocator.isSetup, isTrue);
        expect(RoutingServiceLocator.routingFactory, equals(mockFactory));
        expect(RoutingServiceLocator.portValidator, isA<PortCompatibilityValidator>());
      });

      test('should setup with both custom validator and factory', () async {
        await RoutingServiceLocator.setup(
          customValidator: mockValidator,
          customFactory: mockFactory,
        );

        expect(RoutingServiceLocator.isSetup, isTrue);
        expect(RoutingServiceLocator.portValidator, equals(mockValidator));
        expect(RoutingServiceLocator.routingFactory, equals(mockFactory));
      });

      test('should throw StateError when setup is called twice', () async {
        await RoutingServiceLocator.setup();

        expect(
          () async => await RoutingServiceLocator.setup(),
          throwsA(isA<StateError>()),
        );
      });

      test('should allow setup after reset', () async {
        await RoutingServiceLocator.setup();
        await RoutingServiceLocator.reset();
        
        expect(RoutingServiceLocator.isSetup, isFalse);
        
        await RoutingServiceLocator.setup();
        expect(RoutingServiceLocator.isSetup, isTrue);
      });
    });

    group('Reset Functionality', () {
      test('should reset successfully when setup', () async {
        await RoutingServiceLocator.setup();
        expect(RoutingServiceLocator.isSetup, isTrue);

        await RoutingServiceLocator.reset();
        expect(RoutingServiceLocator.isSetup, isFalse);
      });

      test('should be safe to call reset when not setup', () async {
        expect(RoutingServiceLocator.isSetup, isFalse);
        await RoutingServiceLocator.reset(); // Should not throw
        expect(RoutingServiceLocator.isSetup, isFalse);
      });

      test('should be safe to call reset multiple times', () async {
        await RoutingServiceLocator.setup();
        await RoutingServiceLocator.reset();
        await RoutingServiceLocator.reset(); // Should not throw
        expect(RoutingServiceLocator.isSetup, isFalse);
      });

      test('should throw when accessing services after reset', () async {
        await RoutingServiceLocator.setup();
        await RoutingServiceLocator.reset();

        expect(
          () => RoutingServiceLocator.routingFactory,
          throwsA(isA<StateError>()),
        );
        
        expect(
          () => RoutingServiceLocator.portValidator,
          throwsA(isA<StateError>()),
        );
      });
    });

    group('Convenience Methods', () {
      late AlgorithmRoutingMetadata polyMetadata;
      late AlgorithmRoutingMetadata multiMetadata;
      late AlgorithmRouting mockRouting;

      setUp(() async {
        polyMetadata = AlgorithmRoutingMetadataFactory.polyphonic(
          algorithmGuid: 'test-poly',
          voiceCount: 4,
        );
        
        multiMetadata = AlgorithmRoutingMetadataFactory.normal(
          algorithmGuid: 'test-normal',
        );

        mockRouting = MockAlgorithmRouting();

        // Setup mock factory behavior
        when(mockFactory.createRouting(any, validator: anyNamed('validator')))
            .thenReturn(mockRouting);
        when(mockFactory.createValidatedRouting(any, validator: anyNamed('validator')))
            .thenReturn(mockRouting);
        when(mockFactory.validateMetadata(any)).thenReturn(true);
        when(mockFactory.analyzeMetadata(any)).thenReturn(['test suggestion']);
      });

      test('getRouting should throw StateError when not setup', () {
        expect(
          () => RoutingServiceLocator.getRouting(polyMetadata),
          throwsA(isA<StateError>()),
        );
      });

      test('getRouting should work with real factory', () async {
        await RoutingServiceLocator.setup();

        final routing = RoutingServiceLocator.getRouting(polyMetadata);

        expect(routing, isA<PolyAlgorithmRouting>());
      });

      test('getRouting should work with mock factory', () async {
        await RoutingServiceLocator.setup(customFactory: mockFactory);

        final routing = RoutingServiceLocator.getRouting(polyMetadata);

        expect(routing, equals(mockRouting));
        verify(mockFactory.createRouting(polyMetadata, validator: null)).called(1);
      });

      test('getRouting should pass validator parameter', () async {
        await RoutingServiceLocator.setup(customFactory: mockFactory);

        final customValidator = MockPortCompatibilityValidator();
        RoutingServiceLocator.getRouting(polyMetadata, validator: customValidator);

        verify(mockFactory.createRouting(polyMetadata, validator: customValidator)).called(1);
      });

      test('getValidatedRouting should work with mock factory', () async {
        await RoutingServiceLocator.setup(customFactory: mockFactory);

        final routing = RoutingServiceLocator.getValidatedRouting(multiMetadata);

        expect(routing, equals(mockRouting));
        verify(mockFactory.createValidatedRouting(multiMetadata, validator: null)).called(1);
      });

      test('getValidatedRouting should pass validator parameter', () async {
        await RoutingServiceLocator.setup(customFactory: mockFactory);

        final customValidator = MockPortCompatibilityValidator();
        RoutingServiceLocator.getValidatedRouting(multiMetadata, validator: customValidator);

        verify(mockFactory.createValidatedRouting(multiMetadata, validator: customValidator)).called(1);
      });

      test('validateMetadata should work with mock factory', () async {
        await RoutingServiceLocator.setup(customFactory: mockFactory);

        final isValid = RoutingServiceLocator.validateMetadata(polyMetadata);

        expect(isValid, isTrue);
        verify(mockFactory.validateMetadata(polyMetadata)).called(1);
      });

      test('analyzeMetadata should work with mock factory', () async {
        await RoutingServiceLocator.setup(customFactory: mockFactory);

        final suggestions = RoutingServiceLocator.analyzeMetadata(polyMetadata);

        expect(suggestions, equals(['test suggestion']));
        verify(mockFactory.analyzeMetadata(polyMetadata)).called(1);
      });

      test('convenience methods should throw StateError when not setup', () {
        expect(
          () => RoutingServiceLocator.getValidatedRouting(polyMetadata),
          throwsA(isA<StateError>()),
        );
        
        expect(
          () => RoutingServiceLocator.validateMetadata(polyMetadata),
          throwsA(isA<StateError>()),
        );
        
        expect(
          () => RoutingServiceLocator.analyzeMetadata(polyMetadata),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('Advanced Setup', () {
      test('should setup with custom registration functions', () async {
        var validatorRegistered = false;
        var factoryRegistered = false;

        await RoutingServiceLocator.setupAdvanced(
          registerValidator: (getIt) {
            getIt.registerSingleton<PortCompatibilityValidator>(mockValidator);
            validatorRegistered = true;
          },
          registerFactory: (getIt) {
            getIt.registerSingleton<RoutingFactory>(mockFactory);
            factoryRegistered = true;
          },
        );

        expect(validatorRegistered, isTrue);
        expect(factoryRegistered, isTrue);
        expect(RoutingServiceLocator.isSetup, isTrue);
        expect(RoutingServiceLocator.portValidator, equals(mockValidator));
        expect(RoutingServiceLocator.routingFactory, equals(mockFactory));
      });

      test('should throw StateError when advanced setup is called twice', () async {
        await RoutingServiceLocator.setupAdvanced(
          registerValidator: (getIt) => getIt.registerSingleton<PortCompatibilityValidator>(mockValidator),
          registerFactory: (getIt) => getIt.registerSingleton<RoutingFactory>(mockFactory),
        );

        expect(
          () async => await RoutingServiceLocator.setupAdvanced(
            registerValidator: (getIt) => getIt.registerSingleton<PortCompatibilityValidator>(mockValidator),
            registerFactory: (getIt) => getIt.registerSingleton<RoutingFactory>(mockFactory),
          ),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('Diagnostics', () {
      test('should return correct diagnostics when not setup', () {
        final diagnostics = RoutingServiceLocator.getDiagnostics();

        expect(diagnostics['isSetup'], isFalse);
        expect(diagnostics['validatorRegistered'], isFalse);
        expect(diagnostics['factoryRegistered'], isFalse);
        expect(diagnostics['timestamp'], isA<String>());
      });

      test('should return correct diagnostics when setup', () async {
        await RoutingServiceLocator.setup();

        final diagnostics = RoutingServiceLocator.getDiagnostics();

        expect(diagnostics['isSetup'], isTrue);
        expect(diagnostics['validatorRegistered'], isTrue);
        expect(diagnostics['factoryRegistered'], isTrue);
        expect(diagnostics['totalRegistrations'], equals('N/A'));
        expect(diagnostics['timestamp'], isA<String>());
      });

      test('should return correct diagnostics after reset', () async {
        await RoutingServiceLocator.setup();
        await RoutingServiceLocator.reset();

        final diagnostics = RoutingServiceLocator.getDiagnostics();

        expect(diagnostics['isSetup'], isFalse);
        expect(diagnostics['validatorRegistered'], isFalse);
        expect(diagnostics['factoryRegistered'], isFalse);
      });
    });

    group('Integration with Real Services', () {
      test('should create real routing instances through service locator', () async {
        await RoutingServiceLocator.setup();

        final polyMetadata = AlgorithmRoutingMetadataFactory.polyphonic(
          algorithmGuid: 'integration-poly',
          voiceCount: 2,
        );

        final multiMetadata = AlgorithmRoutingMetadataFactory.widthBased(
          algorithmGuid: 'integration-width',
          channelCount: 4,
        );

        final polyRouting = RoutingServiceLocator.getRouting(polyMetadata);
        final multiRouting = RoutingServiceLocator.getRouting(multiMetadata);

        expect(polyRouting, isA<PolyAlgorithmRouting>());
        expect(multiRouting, isA<MultiChannelAlgorithmRouting>());

        // Test that the routing instances work correctly
        expect(polyRouting.inputPorts, isNotEmpty);
        expect(polyRouting.outputPorts, isNotEmpty);
        expect(multiRouting.inputPorts, isNotEmpty);
        expect(multiRouting.outputPorts, isNotEmpty);
      });

      test('should validate metadata through service locator', () async {
        await RoutingServiceLocator.setup();

        final validMetadata = AlgorithmRoutingMetadataFactory.polyphonic(
          algorithmGuid: 'valid-test',
          voiceCount: 4,
        );

        const invalidMetadata = AlgorithmRoutingMetadata(
          algorithmGuid: '',
          routingType: RoutingType.polyphonic,
        );

        expect(RoutingServiceLocator.validateMetadata(validMetadata), isTrue);
        expect(RoutingServiceLocator.validateMetadata(invalidMetadata), isFalse);
      });

      test('should analyze metadata through service locator', () async {
        await RoutingServiceLocator.setup();

        final highVoiceMetadata = AlgorithmRoutingMetadataFactory.polyphonic(
          algorithmGuid: 'high-voices',
          voiceCount: 20,
        );

        final suggestions = RoutingServiceLocator.analyzeMetadata(highVoiceMetadata);

        expect(suggestions, isNotEmpty);
        expect(suggestions.first, contains('High voice count'));
      });
    });
  });

  group('GetItRoutingExtensions', () {
    late GetIt testGetIt;

    setUp(() {
      testGetIt = GetIt.asNewInstance();
    });

    tearDown(() async {
      await testGetIt.reset();
    });

    group('registerRoutingDependencies', () {
      test('should register default dependencies', () {
        testGetIt.registerRoutingDependencies();

        expect(testGetIt.isRegistered<PortCompatibilityValidator>(), isTrue);
        expect(testGetIt.isRegistered<RoutingFactory>(), isTrue);
        expect(testGetIt<PortCompatibilityValidator>(), isA<PortCompatibilityValidator>());
        expect(testGetIt<RoutingFactory>(), isA<RoutingFactory>());
      });

      test('should register custom validator', () {
        final mockValidator = MockPortCompatibilityValidator();
        
        testGetIt.registerRoutingDependencies(customValidator: mockValidator);

        expect(testGetIt<PortCompatibilityValidator>(), equals(mockValidator));
      });

      test('should register custom factory', () {
        final mockFactory = MockRoutingFactory();
        
        testGetIt.registerRoutingDependencies(customFactory: mockFactory);

        expect(testGetIt<RoutingFactory>(), equals(mockFactory));
      });

      test('should register both custom dependencies', () {
        final mockValidator = MockPortCompatibilityValidator();
        final mockFactory = MockRoutingFactory();
        
        testGetIt.registerRoutingDependencies(
          customValidator: mockValidator,
          customFactory: mockFactory,
        );

        expect(testGetIt<PortCompatibilityValidator>(), equals(mockValidator));
        expect(testGetIt<RoutingFactory>(), equals(mockFactory));
      });
    });

    group('unregisterRoutingDependencies', () {
      test('should unregister dependencies when registered', () async {
        testGetIt.registerRoutingDependencies();
        
        expect(testGetIt.isRegistered<PortCompatibilityValidator>(), isTrue);
        expect(testGetIt.isRegistered<RoutingFactory>(), isTrue);

        await testGetIt.unregisterRoutingDependencies();

        expect(testGetIt.isRegistered<PortCompatibilityValidator>(), isFalse);
        expect(testGetIt.isRegistered<RoutingFactory>(), isFalse);
      });

      test('should be safe to call when not registered', () async {
        expect(testGetIt.isRegistered<PortCompatibilityValidator>(), isFalse);
        expect(testGetIt.isRegistered<RoutingFactory>(), isFalse);

        await testGetIt.unregisterRoutingDependencies(); // Should not throw

        expect(testGetIt.isRegistered<PortCompatibilityValidator>(), isFalse);
        expect(testGetIt.isRegistered<RoutingFactory>(), isFalse);
      });
    });

    group('Integration with Extensions', () {
      test('should work with routing functionality after registration', () async {
        testGetIt.registerRoutingDependencies();

        final factory = testGetIt<RoutingFactory>();
        final validator = testGetIt<PortCompatibilityValidator>();

        expect(factory, isA<RoutingFactory>());
        expect(validator, isA<PortCompatibilityValidator>());

        // Test that we can create routing instances
        final metadata = AlgorithmRoutingMetadataFactory.polyphonic(
          algorithmGuid: 'extension-test',
          voiceCount: 2,
        );

        final routing = factory.createRouting(metadata);
        expect(routing, isA<PolyAlgorithmRouting>());
      });
    });
  });
}

// Mock AlgorithmRouting for testing
class MockAlgorithmRouting extends Mock implements AlgorithmRouting {}