import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_practice/homepage.dart';
import 'package:flutter_application_practice/pages/beautician_home.dart';
import 'package:flutter_application_practice/pages/feed.dart';

void main() {
  test('returns beautician homepage for beautician role', () {
    final widget = createHomePageForRole('beautician');

    expect(widget, isA<BeauticianHomePage>());
  });

  test('returns client homepage for client role', () {
    final widget = createHomePageForRole('client');

    expect(widget, isA<UserHomePage>());
  });
}

createHomePageForRole(String s) {}
