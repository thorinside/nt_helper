part of 'disting_cubit.dart';

class _StateHelpersDelegate {
  _StateHelpersDelegate(this._cubit);

  final DistingCubit _cubit;

  // Helper to fetch algorithm metadata for offline mode
  Future<List<AlgorithmInfo>> fetchOfflineAlgorithms() async {
    try {
      final allBasicAlgoEntries = await _cubit._metadataDao.getAllAlgorithms();
      final List<AlgorithmInfo> availableAlgorithmsInfo = [];

      final detailedFutures = allBasicAlgoEntries.map((basicEntry) async {
        return await _cubit._metadataDao.getFullAlgorithmDetails(basicEntry.guid);
      }).toList();

      final detailedResults = await Future.wait(detailedFutures);

      for (final details in detailedResults.whereType<FullAlgorithmDetails>()) {
        availableAlgorithmsInfo.add(
          AlgorithmInfo(
            guid: details.algorithm.guid,
            name: details.algorithm.name,
            algorithmIndex: -1,
            specifications: details.specifications
                .map(
                  (specEntry) => Specification(
                    name: specEntry.name,
                    min: specEntry.minValue,
                    max: specEntry.maxValue,
                    defaultValue: specEntry.defaultValue,
                    type: specEntry.type,
                  ),
                )
                .toList(),
          ),
        );
      }
      availableAlgorithmsInfo.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return availableAlgorithmsInfo;
    } catch (e, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
      return []; // Return empty on error
    }
  }

  List<RoutingInformation> buildRoutingInformation() {
    switch (_cubit.state) {
      case DistingStateSynchronized syncstate:
        return syncstate.slots
            .where((slot) => slot.routing.algorithmIndex != -1)
            .map(
              (slot) => RoutingInformation(
                algorithmIndex: slot.routing.algorithmIndex,
                routingInfo: slot.routing.routingInfo,
                algorithmName: (slot.algorithm.name.isNotEmpty)
                    ? slot.algorithm.name
                    : syncstate.algorithms
                          .firstWhere(
                            (element) => element.guid == slot.algorithm.guid,
                          )
                          .name,
              ),
            )
            .toList();
      default:
        return [];
    }
  }

  bool isProgramParameter(
    DistingStateSynchronized state,
    int algorithmIndex,
    int parameterNumber,
  ) =>
      (state.slots[algorithmIndex].parameters[parameterNumber].name ==
          "Program") &&
      (("spin" == state.slots[algorithmIndex].algorithm.guid) ||
          ("lua " == state.slots[algorithmIndex].algorithm.guid));
}

