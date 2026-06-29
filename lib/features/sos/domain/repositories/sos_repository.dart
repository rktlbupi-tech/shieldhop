import '../../../../core/errors/failures.dart';

abstract class SosRepository {
  Future<(bool, Failure?)> startSos({required double lat, required double lng});
  Future<(bool, Failure?)> stopSos();
}
