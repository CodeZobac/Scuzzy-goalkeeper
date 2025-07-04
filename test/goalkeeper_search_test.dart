import 'package:flutter_test/flutter_test.dart';
import 'package:goalkeeper/src/features/goalkeeper_search/data/models/goalkeeper.dart';

void main() {
  group('Goalkeeper Search Tests', () {
    test('Goalkeeper model creates correctly from map', () {
      final testData = {
        'id': '1',
        'name': 'João Silva',
        'city': 'Lisboa',
        'price_per_game': 50.0,
        'gender': 'M',
        'club': 'SL Benfica',
        'nationality': 'Portuguese',
        'country': 'Portugal',
        'birth_date': '1995-06-15T00:00:00.000Z',
      };

      final goalkeeper = Goalkeeper.fromMap(testData);

      expect(goalkeeper.id, '1');
      expect(goalkeeper.name, 'João Silva');
      expect(goalkeeper.city, 'Lisboa');
      expect(goalkeeper.pricePerGame, 50.0);
      expect(goalkeeper.gender, 'M');
      expect(goalkeeper.club, 'SL Benfica');
      expect(goalkeeper.nationality, 'Portuguese');
      expect(goalkeeper.country, 'Portugal');
      expect(goalkeeper.birthDate, isNotNull);
    });

    test('Goalkeeper model helper methods work correctly', () {
      final goalkeeper = Goalkeeper(
        id: '1',
        name: 'João Silva',
        city: 'Lisboa',
        pricePerGame: 50.0,
        club: 'SL Benfica',
        birthDate: DateTime(1995, 6, 15),
      );

      expect(goalkeeper.displayPrice, '€50.00/jogo');
      expect(goalkeeper.displayLocation, 'Lisboa');
      expect(goalkeeper.displayClub, 'SL Benfica');
      expect(goalkeeper.age, isNotNull);
      expect(goalkeeper.displayAge, contains('anos'));
    });

    test('Goalkeeper model handles null values correctly', () {
      final goalkeeper = Goalkeeper(
        id: '1',
        name: 'João Silva',
      );

      expect(goalkeeper.displayPrice, 'Preço não definido');
      expect(goalkeeper.displayLocation, 'Localização não definida');
      expect(goalkeeper.displayClub, 'Clube não definido');
      expect(goalkeeper.displayAge, 'Idade não definida');
    });

    test('Goalkeeper model converts to and from JSON correctly', () {
      final goalkeeper = Goalkeeper(
        id: '1',
        name: 'João Silva',
        city: 'Lisboa',
        pricePerGame: 50.0,
      );

      final json = goalkeeper.toJson();
      final fromJson = Goalkeeper.fromJson(json);

      expect(fromJson.id, goalkeeper.id);
      expect(fromJson.name, goalkeeper.name);
      expect(fromJson.city, goalkeeper.city);
      expect(fromJson.pricePerGame, goalkeeper.pricePerGame);
    });
  });
}
