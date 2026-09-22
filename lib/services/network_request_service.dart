class NetworkDroppedException implements Exception {
  final String message;
  const NetworkDroppedException(this.message);

  @override
  String toString() => message;
}

class NetworkRequestService {
  static const int totalSteps = 5;
  static const Duration stepDuration = Duration(milliseconds: 700);

  Future<void> simulateFetch({
    required bool Function() isOnline,
    void Function(int step, int totalSteps)? onProgress,
  }) async {
    if (!isOnline()) {
      throw const NetworkDroppedException('No connection available to start the request');
    }

    for (var step = 1; step <= totalSteps; step++) {
      await Future.delayed(stepDuration);
      if (!isOnline()) {
        throw NetworkDroppedException(
          'Connection dropped mid-transfer (chunk $step of $totalSteps)',
        );
      }
      onProgress?.call(step, totalSteps);
    }
  }
}
