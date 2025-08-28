import 'package:flutter/foundation.dart';
import 'models/port.dart';
import 'models/connection.dart';

/// Enum representing different types of validation errors
enum ValidationErrorType {
  /// Ports have incompatible directions
  incompatibleDirection,
  
  /// Ports have incompatible types
  incompatibleType,
  
  /// Source port is not active
  inactiveSourcePort,
  
  /// Destination port is not active
  inactiveDestinationPort,
  
  /// Port constraint violation
  constraintViolation,
  
  /// Connection would create a loop
  circularDependency,
  
  /// Port is already connected (for single-connection ports)
  portAlreadyConnected,
  
  /// Custom validation rule failed
  customRuleFailed,
}

/// Data class representing a validation result
@immutable
class ValidationResult {
  const ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });
  
  /// Whether the validation passed
  final bool isValid;
  
  /// List of validation errors
  final List<ValidationError> errors;
  
  /// List of validation warnings (non-blocking)
  final List<ValidationWarning> warnings;
  
  /// Creates a successful validation result
  const ValidationResult.success({List<ValidationWarning> warnings = const []})
      : isValid = true,
        errors = const [],
        warnings = warnings;
  
  /// Creates a failed validation result
  const ValidationResult.failure(List<ValidationError> errors)
      : isValid = false,
        errors = errors,
        warnings = const [];
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ValidationResult &&
        other.isValid == isValid &&
        listEquals(other.errors, errors) &&
        listEquals(other.warnings, warnings);
  }
  
  @override
  int get hashCode => Object.hash(isValid, errors, warnings);
}

/// Data class representing a validation error
@immutable
class ValidationError {
  const ValidationError({
    required this.type,
    required this.message,
    this.sourcePortId,
    this.destinationPortId,
    this.details,
  });
  
  /// The type of validation error
  final ValidationErrorType type;
  
  /// Human-readable error message
  final String message;
  
  /// ID of the source port (if applicable)
  final String? sourcePortId;
  
  /// ID of the destination port (if applicable)
  final String? destinationPortId;
  
  /// Additional error details
  final Map<String, dynamic>? details;
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ValidationError &&
        other.type == type &&
        other.message == message &&
        other.sourcePortId == sourcePortId &&
        other.destinationPortId == destinationPortId &&
        mapEquals(other.details, details);
  }
  
  @override
  int get hashCode => Object.hash(type, message, sourcePortId, destinationPortId, details);
}

/// Data class representing a validation warning
@immutable
class ValidationWarning {
  const ValidationWarning({
    required this.message,
    this.sourcePortId,
    this.destinationPortId,
    this.details,
  });
  
  /// Human-readable warning message
  final String message;
  
  /// ID of the source port (if applicable)
  final String? sourcePortId;
  
  /// ID of the destination port (if applicable)
  final String? destinationPortId;
  
  /// Additional warning details
  final Map<String, dynamic>? details;
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ValidationWarning &&
        other.message == message &&
        other.sourcePortId == sourcePortId &&
        other.destinationPortId == destinationPortId &&
        mapEquals(other.details, details);
  }
  
  @override
  int get hashCode => Object.hash(message, sourcePortId, destinationPortId, details);
}

/// Custom validation rule function type
typedef ValidationRule = ValidationResult Function(Port source, Port destination);

/// Service for validating port compatibility and connections.
/// 
/// This service provides comprehensive validation for port connections,
/// including type compatibility, direction validation, constraint checking,
/// and custom validation rules.
/// 
/// Example usage:
/// ```dart
/// final validator = PortCompatibilityValidator();
/// 
/// final result = validator.validateConnection(sourcePort, destinationPort);
/// if (result.isValid) {
///   // Connection is valid
/// } else {
///   // Handle errors
///   for (final error in result.errors) {
///     debugPrint('Validation error: ${error.message}');
///   }
/// }
/// ```
class PortCompatibilityValidator {
  /// Creates a new port compatibility validator
  PortCompatibilityValidator({
    List<ValidationRule> customRules = const [],
  }) : _customRules = List.from(customRules);
  
  final List<ValidationRule> _customRules;
  
  /// Adds a custom validation rule
  void addCustomRule(ValidationRule rule) {
    _customRules.add(rule);
    debugPrint('PortCompatibilityValidator: Added custom validation rule');
  }
  
  /// Removes all custom validation rules
  void clearCustomRules() {
    _customRules.clear();
    debugPrint('PortCompatibilityValidator: Cleared custom validation rules');
  }
  
  /// Validates whether a connection between two ports is valid.
  /// 
  /// Performs comprehensive validation including:
  /// - Direction compatibility
  /// - Type compatibility
  /// - Port activity status
  /// - Constraint validation
  /// - Custom rule validation
  /// 
  /// Parameters:
  /// - [source]: The source port for the connection
  /// - [destination]: The destination port for the connection
  /// - [existingConnections]: List of existing connections to check for conflicts
  /// 
  /// Returns a [ValidationResult] containing the validation outcome
  ValidationResult validateConnection(
    Port source,
    Port destination, {
    List<Connection> existingConnections = const [],
  }) {
    final errors = <ValidationError>[];
    final warnings = <ValidationWarning>[];
    
    // Validate direction compatibility
    final directionResult = _validateDirection(source, destination);
    if (!directionResult.isValid) {
      errors.addAll(directionResult.errors);
    }
    warnings.addAll(directionResult.warnings);
    
    // Validate type compatibility
    final typeResult = _validateType(source, destination);
    if (!typeResult.isValid) {
      errors.addAll(typeResult.errors);
    }
    warnings.addAll(typeResult.warnings);
    
    // Validate port activity
    final activityResult = _validateActivity(source, destination);
    if (!activityResult.isValid) {
      errors.addAll(activityResult.errors);
    }
    
    // Validate constraints
    final constraintResult = _validateConstraints(source, destination);
    if (!constraintResult.isValid) {
      errors.addAll(constraintResult.errors);
    }
    warnings.addAll(constraintResult.warnings);
    
    // Check for existing connections if applicable
    final connectionResult = _validateExistingConnections(
      source, 
      destination, 
      existingConnections,
    );
    if (!connectionResult.isValid) {
      errors.addAll(connectionResult.errors);
    }
    warnings.addAll(connectionResult.warnings);
    
    // Apply custom validation rules
    for (final rule in _customRules) {
      try {
        final customResult = rule(source, destination);
        if (!customResult.isValid) {
          errors.addAll(customResult.errors);
        }
        warnings.addAll(customResult.warnings);
      } catch (e) {
        errors.add(ValidationError(
          type: ValidationErrorType.customRuleFailed,
          message: 'Custom validation rule failed: $e',
          sourcePortId: source.id,
          destinationPortId: destination.id,
        ));
        debugPrint('PortCompatibilityValidator: Custom rule failed - $e');
      }
    }
    
    final isValid = errors.isEmpty;
    debugPrint(
      'PortCompatibilityValidator: Validation ${isValid ? "passed" : "failed"} for '
      '${source.id} -> ${destination.id}',
    );
    
    return ValidationResult(
      isValid: isValid,
      errors: errors,
      warnings: warnings,
    );
  }
  
  /// Validates direction compatibility between ports
  ValidationResult _validateDirection(Port source, Port destination) {
    if (!source.canConnectTo(destination)) {
      return ValidationResult.failure([
        ValidationError(
          type: ValidationErrorType.incompatibleDirection,
          message: 'Cannot connect ${source.direction.name} port to ${destination.direction.name} port',
          sourcePortId: source.id,
          destinationPortId: destination.id,
        ),
      ]);
    }
    
    return const ValidationResult.success();
  }
  
  /// Validates type compatibility between ports
  ValidationResult _validateType(Port source, Port destination) {
    final warnings = <ValidationWarning>[];
    
    if (!source.isCompatibleWith(destination)) {
      return ValidationResult.failure([
        ValidationError(
          type: ValidationErrorType.incompatibleType,
          message: 'Port types ${source.type.name} and ${destination.type.name} are not compatible',
          sourcePortId: source.id,
          destinationPortId: destination.id,
        ),
      ]);
    }
    
    // Add warning for cross-type connections that are allowed but may need attention
    if (source.type != destination.type) {
      warnings.add(ValidationWarning(
        message: 'Cross-type connection: ${source.type.name} to ${destination.type.name}',
        sourcePortId: source.id,
        destinationPortId: destination.id,
      ));
    }
    
    return ValidationResult.success(warnings: warnings);
  }
  
  /// Validates that both ports are active
  ValidationResult _validateActivity(Port source, Port destination) {
    final errors = <ValidationError>[];
    
    if (!source.isActive) {
      errors.add(ValidationError(
        type: ValidationErrorType.inactiveSourcePort,
        message: 'Source port ${source.id} is not active',
        sourcePortId: source.id,
        destinationPortId: destination.id,
      ));
    }
    
    if (!destination.isActive) {
      errors.add(ValidationError(
        type: ValidationErrorType.inactiveDestinationPort,
        message: 'Destination port ${destination.id} is not active',
        sourcePortId: source.id,
        destinationPortId: destination.id,
      ));
    }
    
    return errors.isEmpty ? const ValidationResult.success() : ValidationResult.failure(errors);
  }
  
  /// Validates port constraints
  ValidationResult _validateConstraints(Port source, Port destination) {
    final errors = <ValidationError>[];
    final warnings = <ValidationWarning>[];
    
    // Check source constraints
    if (source.constraints != null) {
      final sourceConstraints = source.constraints!;
      
      // Example: Check voltage range compatibility
      if (sourceConstraints.containsKey('voltageRange') && 
          destination.constraints?.containsKey('voltageRange') == true) {
        final sourceRange = sourceConstraints['voltageRange'] as Map<String, dynamic>?;
        final destRange = destination.constraints!['voltageRange'] as Map<String, dynamic>?;
        
        if (sourceRange != null && destRange != null) {
          final sourceMin = sourceRange['min'] as num?;
          final sourceMax = sourceRange['max'] as num?;
          final destMin = destRange['min'] as num?;
          final destMax = destRange['max'] as num?;
          
          if (sourceMin != null && destMax != null && sourceMin > destMax ||
              sourceMax != null && destMin != null && sourceMax < destMin) {
            errors.add(ValidationError(
              type: ValidationErrorType.constraintViolation,
              message: 'Voltage range incompatibility between ports',
              sourcePortId: source.id,
              destinationPortId: destination.id,
              details: {
                'sourceRange': sourceRange,
                'destinationRange': destRange,
              },
            ));
          }
        }
      }
    }
    
    return errors.isEmpty 
        ? ValidationResult.success(warnings: warnings) 
        : ValidationResult.failure(errors);
  }
  
  /// Validates against existing connections
  ValidationResult _validateExistingConnections(
    Port source,
    Port destination,
    List<Connection> existingConnections,
  ) {
    final warnings = <ValidationWarning>[];
    
    // Check if either port already has connections (informational)
    final sourceConnections = existingConnections.where(
      (conn) => conn.sourcePortId == source.id || conn.destinationPortId == source.id,
    ).length;
    
    final destConnections = existingConnections.where(
      (conn) => conn.sourcePortId == destination.id || conn.destinationPortId == destination.id,
    ).length;
    
    if (sourceConnections > 0) {
      warnings.add(ValidationWarning(
        message: 'Source port ${source.id} already has $sourceConnections connection(s)',
        sourcePortId: source.id,
        destinationPortId: destination.id,
      ));
    }
    
    if (destConnections > 0) {
      warnings.add(ValidationWarning(
        message: 'Destination port ${destination.id} already has $destConnections connection(s)',
        sourcePortId: source.id,
        destinationPortId: destination.id,
      ));
    }
    
    return ValidationResult.success(warnings: warnings);
  }
}