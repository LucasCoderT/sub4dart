import 'package:sub4dart/sub4dart.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    SubSonic subSonic;

    setUp(() {
      subSonic = new SubSonic("music.example.com", "John", "Doe");
    });

    test('First Test', () {
      expect(subSonic.isValid(), isTrue);
    });
  });
}
