import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

class SectionBuilder {
  final Slot slot;

  SectionBuilder({required this.slot});

  Future<Map<String, List<ParameterInfo>>?> buildSections() async {
    try {
      // Load the JSON file based on the GUID of the algorithm in the slot
      String jsonString = await rootBundle.loadString(
        'assets/sections/${slot.algorithm.guid.trim()}.json',
        cache: true,
      );

      // Decode the JSON into a map of sections
      Map<String, List<dynamic>> data =
          Map<String, List<dynamic>>.from(jsonDecode(jsonString));

// Initialize the resulting map
      Map<String, List<ParameterInfo>> sections = {};

      // Create a mutable copy of the parameters list
      List<ParameterInfo> remainingParameters = List.from(slot.parameters);

      // Iterate over each section in the JSON
      data.forEach((sectionName, patterns) {
        // Check if the section name contains a wildcard (*)
        if (sectionName.contains('*')) {
          // Handle dynamic key duplication
          remainingParameters.removeWhere((param) {
            final regex = RegExp(r'^(\d+):(.+)$'); // Matches "number:name"
            final match = regex.firstMatch(param.name);

            if (match != null) {
              String number = match.group(1)!; // Extract the number prefix
              String parameterName = match.group(2)!.trim().toLowerCase();

              // Check if the parameter name matches any pattern
              bool matches = patterns.any((pattern) {
                String lowerCasePattern = pattern.toLowerCase();
                if (lowerCasePattern.contains('*')) {
                  // Handle wildcard matching
                  String regexPattern = '^' +
                      RegExp.escape(lowerCasePattern).replaceAll(r'\*', '.*') +
                      r'$';
                  return RegExp(regexPattern).hasMatch(parameterName);
                } else {
                  // Exact match
                  return parameterName == lowerCasePattern;
                }
              });

              if (matches) {
                // Create a new key with the number inserted into the wildcard
                String dynamicKey = sectionName.replaceAll('*', number);

                // Add to the correct section
                sections.putIfAbsent(dynamicKey, () => []);
                sections[dynamicKey]!.add(param);

                return true; // Remove the parameter from remainingParameters
              }
            }

            return false; // Keep the parameter if no match is found
          });
        } else {
          // Standard matching without wildcard in the key
          List<ParameterInfo> matchingParameters = [];
          remainingParameters.removeWhere((param) {
            String lowerCaseName = param.name.toLowerCase();

            // Check if the parameter name matches any pattern
            bool matches = patterns.any((pattern) {
              String lowerCasePattern = pattern.toLowerCase();
              if (lowerCasePattern.contains('*')) {
                // Handle wildcard matching
                String regexPattern = '^' +
                    RegExp.escape(lowerCasePattern).replaceAll(r'\*', '.*') +
                    r'$';
                return RegExp(regexPattern).hasMatch(lowerCaseName);
              } else {
                // Exact match
                return lowerCaseName == lowerCasePattern;
              }
            });

            if (matches) {
              matchingParameters.add(param);
            }

            return matches; // Remove the parameter if it matches
          });

          // Add the matching parameters to the section map
          if (matchingParameters.isNotEmpty) {
            sections[sectionName] = matchingParameters;
          }
        }
      });

      return sections;
    } catch (e) {
      // Handle any errors and return an empty map
      print('Error while building sections: $e');
      return null;
    }
  }
}
