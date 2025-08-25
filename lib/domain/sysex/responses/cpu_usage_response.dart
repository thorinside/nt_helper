import 'package:nt_helper/models/cpu_usage.dart';
import 'package:nt_helper/domain/sysex/responses/sysex_response.dart';

class CpuUsageResponse extends SysexResponse {
  CpuUsageResponse(super.data);

  @override
  CpuUsage parse() {
    final cpu1 = data[0];
    final cpu2 = data[1];
    final slotUsages = data.sublist(2).toList();

    return CpuUsage(cpu1: cpu1, cpu2: cpu2, slotUsages: slotUsages);
  }
}
