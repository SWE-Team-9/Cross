import 'package:flutter_test/flutter_test.dart';
import 'core/mocks/testing/test_accounts.dart';
void main() {
  test('TestAccounts should contain 3 accounts', () {
    expect(TestAccounts.all.length, 3);
  });

  test('Premium account username should be correct', () {
    expect(TestAccounts.premium.username, 'premium_user');
  });
}