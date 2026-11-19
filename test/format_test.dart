import 'package:flutter_test/flutter_test.dart';
import 'package:rumbo/utils/format.dart';

void main() {
  test('formatea metros y kilómetros', () {
    expect(formatDistance(850), '850 m');
    expect(formatDistance(1240), '1.24 km');
    expect(formatDistance(12400), '12.4 km');
  });

  test('punto cardinal en español', () {
    expect(compassPoint(0), 'N');
    expect(compassPoint(90), 'E');
    expect(compassPoint(-90), 'O');
    expect(compassPoint(225), 'SO');
  });

  test('coordenadas con hemisferio', () {
    expect(formatCoordinate(20.2756, isLatitude: true), '20.27560° N');
    expect(formatCoordinate(-97.9611, isLatitude: false), '97.96110° O');
  });
}
