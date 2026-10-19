import 'package:flutter_test/flutter_test.dart';
import 'package:safetour/data/local/initial_safety_data.dart';

void main() {
  test('Initial safety data sanity test', () {
    expect(InitialSafetyData.defaultZones.length, 100);
    expect(InitialSafetyData.defaultZones.first.areaName.isNotEmpty, true);
  });
}
