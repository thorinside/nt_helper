#!/usr/bin/env python3
"""
Add ES-5 Expander and ES-5 Output parameters to Clock and Euclidean algorithms.

This script modifies assets/metadata/full_metadata.json to add:
- ES-5 Expander parameter (enum: Off, 1-6)
- ES-5 Output parameter (numeric: 1-8)

For both Clock (clck) and Euclidean (eucp) algorithms.
"""

import json
import sys
from pathlib import Path


def find_insert_position(parameters, algorithm_guid, last_param_num):
    """Find the position to insert new parameters after the last parameter of an algorithm."""
    for i, param in enumerate(parameters):
        if (param.get('algorithmGuid') == algorithm_guid and
            param.get('parameterNumber') == last_param_num):
            return i + 1
    return None


def create_es5_expander_param(algorithm_guid, param_number):
    """Create ES-5 Expander parameter definition."""
    return {
        "algorithmGuid": algorithm_guid,
        "parameterNumber": param_number,
        "name": "ES-5 Expander",
        "minValue": 0,
        "maxValue": 6,
        "defaultValue": 0,
        "unitId": None,
        "powerOfTen": 0,
        "rawUnitIndex": 1  # Enum type
    }


def create_es5_output_param(algorithm_guid, param_number):
    """Create ES-5 Output parameter definition."""
    return {
        "algorithmGuid": algorithm_guid,
        "parameterNumber": param_number,
        "name": "ES-5 Output",
        "minValue": 1,
        "maxValue": 8,
        "defaultValue": 1,
        "unitId": None,
        "powerOfTen": 0,
        "rawUnitIndex": 0  # Numeric type
    }


def create_es5_expander_enums(algorithm_guid, param_number):
    """Create enum values for ES-5 Expander parameter."""
    enum_strings = ["Off", "1", "2", "3", "4", "5", "6"]
    return [
        {
            "algorithmGuid": algorithm_guid,
            "parameterNumber": param_number,
            "enumIndex": i,
            "enumString": value
        }
        for i, value in enumerate(enum_strings)
    ]


def main():
    # Load the metadata file
    metadata_path = Path(__file__).parent.parent / "assets" / "metadata" / "full_metadata.json"

    print(f"Loading {metadata_path}...")
    with open(metadata_path, 'r') as f:
        metadata = json.load(f)

    parameters = metadata['tables']['parameters']
    parameter_enums = metadata['tables']['parameterEnums']

    # Add parameters for Clock algorithm (clck)
    # Last parameter is 21, so add 22 and 23
    print("Adding parameters for Clock algorithm...")
    clock_insert_pos = find_insert_position(parameters, 'clck', 21)
    if clock_insert_pos is None:
        print("ERROR: Could not find Clock parameter 21")
        sys.exit(1)

    clock_es5_expander = create_es5_expander_param('clck', 22)
    clock_es5_output = create_es5_output_param('clck', 23)

    parameters.insert(clock_insert_pos, clock_es5_expander)
    parameters.insert(clock_insert_pos + 1, clock_es5_output)

    # Add enum values for Clock ES-5 Expander
    clock_enums = create_es5_expander_enums('clck', 22)
    parameter_enums.extend(clock_enums)

    print(f"  Added Clock parameters 22 (ES-5 Expander) and 23 (ES-5 Output)")
    print(f"  Added {len(clock_enums)} enum values for Clock ES-5 Expander")

    # Add parameters for Euclidean algorithm (eucp)
    # Last parameter is 12, so add 13 and 14
    print("Adding parameters for Euclidean algorithm...")
    eucp_insert_pos = find_insert_position(parameters, 'eucp', 12)
    if eucp_insert_pos is None:
        print("ERROR: Could not find Euclidean parameter 12")
        sys.exit(1)

    eucp_es5_expander = create_es5_expander_param('eucp', 13)
    eucp_es5_output = create_es5_output_param('eucp', 14)

    # Account for the 2 Clock parameters we just inserted
    if eucp_insert_pos > clock_insert_pos:
        eucp_insert_pos += 2

    parameters.insert(eucp_insert_pos, eucp_es5_expander)
    parameters.insert(eucp_insert_pos + 1, eucp_es5_output)

    # Add enum values for Euclidean ES-5 Expander
    eucp_enums = create_es5_expander_enums('eucp', 13)
    parameter_enums.extend(eucp_enums)

    print(f"  Added Euclidean parameters 13 (ES-5 Expander) and 14 (ES-5 Output)")
    print(f"  Added {len(eucp_enums)} enum values for Euclidean ES-5 Expander")

    # Write back the modified metadata
    backup_path = metadata_path.with_suffix('.json.backup')
    print(f"\nCreating backup at {backup_path}...")
    with open(backup_path, 'w') as f:
        json.dump(metadata, f, indent=2)

    print(f"Writing updated metadata to {metadata_path}...")
    with open(metadata_path, 'w') as f:
        json.dump(metadata, f, indent=2)

    print("\nDone! Parameters added successfully.")
    print("\nSummary:")
    print("  Clock (clck): Added parameters 22 (ES-5 Expander) and 23 (ES-5 Output)")
    print("  Euclidean (eucp): Added parameters 13 (ES-5 Expander) and 14 (ES-5 Output)")
    print("  Added enum values: Off, 1, 2, 3, 4, 5, 6 for both algorithms")


if __name__ == '__main__':
    main()
