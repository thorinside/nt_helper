import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/disting_app.dart';

void main() {
  test('DistingApp exposes the Template Manager route', () {
    expect(DistingApp.templateManagerRoute, '/template-manager');
    expect(DistingApp.buildRoutes(), contains(DistingApp.templateManagerRoute));
  });
}
