

class TestAccount {
  final String username;
  final String password;
  final String role; // artist, listener, premium

  TestAccount({required this.username, required this.password, required this.role});
}

class TestAccounts {
  static final artist = TestAccount(
    username: 'artist_user',
    password: 'artist123',
    role: 'artist',
  );

  static final listener = TestAccount(
    username: 'listener_user',
    password: 'listener123',
    role: 'listener',
  );

  static final premium = TestAccount(
    username: 'premium_user',
    password: 'premium123',
    role: 'premium',
  );

  static List<TestAccount> get all => [artist, listener, premium];
}