abstract interface class GoogleAccounts {
  Future<String?> idToken();

  Future<void> signOut();
}
