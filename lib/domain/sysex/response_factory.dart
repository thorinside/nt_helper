import 'package:flutter/foundation.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/sysex/responses/algorithm_info_response.dart';
import 'package:nt_helper/domain/sysex/responses/algorithm_response.dart';
import 'package:nt_helper/domain/sysex/responses/all_parameter_values_response.dart';
import 'package:nt_helper/domain/sysex/responses/mapping_response.dart';
import 'package:nt_helper/domain/sysex/responses/message_response.dart';
import 'package:nt_helper/domain/sysex/responses/num_parameters_response.dart';
import 'package:nt_helper/domain/sysex/responses/number_of_algorithms_in_preset_response.dart';
import 'package:nt_helper/domain/sysex/responses/number_of_algorithms_response.dart';
import 'package:nt_helper/domain/sysex/responses/parameter_enum_strings_response.dart';
import 'package:nt_helper/domain/sysex/responses/parameter_info_response.dart';
import 'package:nt_helper/domain/sysex/responses/parameter_pages_response.dart';
import 'package:nt_helper/domain/sysex/responses/parameter_value_response.dart';
import 'package:nt_helper/domain/sysex/responses/parameter_value_string_response.dart';
import 'package:nt_helper/domain/sysex/responses/routing_information_response.dart';
import 'package:nt_helper/domain/sysex/responses/screenshot_response.dart';
import 'package:nt_helper/domain/sysex/responses/strings_response.dart';
import 'package:nt_helper/domain/sysex/responses/sysex_response.dart';

class ResponseFactory {
  static SysexResponse? fromMessageType(
      DistingNTRespMessageType type, Uint8List payload) {
    switch (type) {
      case DistingNTRespMessageType.respNumAlgorithms:
        return NumberOfAlgorithmsResponse(payload);
      case DistingNTRespMessageType.respAlgorithmInfo:
        return AlgorithmInfoResponse(payload);
      case DistingNTRespMessageType.respMessage:
        return MessageResponse(payload);
      case DistingNTRespMessageType.respScreenshot:
        return ScreenshotResponse(payload);
      case DistingNTRespMessageType.respAlgorithm:
        return AlgorithmResponse(payload);
      case DistingNTRespMessageType.respPresetName:
        return MessageResponse(payload); // Also a simple string
      case DistingNTRespMessageType.respNumParameters:
        return NumParametersResponse(payload);
      case DistingNTRespMessageType.respParameterInfo:
        return ParameterInfoResponse(payload);
      case DistingNTRespMessageType.respAllParameterValues:
        return AllParameterValuesResponse(payload);
      case DistingNTRespMessageType.respParameterValue:
        return ParameterValueResponse(payload);
      case DistingNTRespMessageType.respUnitStrings:
        return StringsResponse(payload);
      case DistingNTRespMessageType.respEnumStrings:
        return ParameterEnumStringsResponse(payload);
      case DistingNTRespMessageType.respMapping:
        return MappingResponse(payload);
      case DistingNTRespMessageType.respParameterValueString:
        return ParameterValueStringResponse(payload);
      case DistingNTRespMessageType.respParameterPages:
        return ParameterPagesResponse(payload);
      case DistingNTRespMessageType.respNumAlgorithmsInPreset:
        return NumberOfAlgorithmsInPresetResponse(payload);
      case DistingNTRespMessageType.respRouting:
        return RoutingInformationResponse(payload);
      case DistingNTRespMessageType.unknown:
        return null;
    }
  }
} 