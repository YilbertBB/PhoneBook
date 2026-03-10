abstract class TokenManager {
  // Métodos existentes
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> deleteToken();
  Future<bool> hasToken();

  // 🔄 Añade estos métodos para refresh token
  Future<void> saveRefreshToken(String refreshToken);
  Future<String?> getRefreshToken();
  Future<bool> hasRefreshToken();
}
