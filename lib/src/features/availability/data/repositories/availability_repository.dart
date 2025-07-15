import '../models/availability.dart';

abstract class AvailabilityRepository {
  Future<List<Availability>> getAvailabilities(String goalkeeperId);
  Future<Availability> createAvailability(Availability availability);
  Future<void> deleteAvailability(String availabilityId);
  Future<Availability> updateAvailability(Availability availability);
}
