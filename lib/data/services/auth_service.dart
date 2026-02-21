import '../models/models.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _apiService;
  final StorageService _storageService;

  AuthService({
    required ApiService apiService,
    required StorageService storageService,
  }) : _apiService = apiService,
       _storageService = storageService;

  Future<bool> isLoggedIn() async {
    final activeAccount = await _storageService.getActiveAccount();
    return activeAccount != null;
  }

  Future<Account?> getActiveAccount() async {
    return await _storageService.getActiveAccount();
  }

  Future<List<Account>> getAccounts() async {
    return await _storageService.getAccounts();
  }

  Future<ApiResult<Account>> login({
    required String username,
    required String apiKey,
    String? host,
  }) async {
    final targetHost = host ?? 'https://e926.net';
    _apiService.setBaseUrl(targetHost);
    final result = await _apiService.verifyCredentials(username, apiKey);

    return result.when(
      success: (_) async {
        try {
          final account = await _storageService.addAccount(
            username: username,
            apiKey: apiKey,
            host: targetHost,
          );
          _apiService.setAuth(username, apiKey);
          return ApiResult.success(account);
        } catch (e, _) {
          return ApiResult.failure(ApiException.unknown(e));
        }
      },
      failure: (error) => ApiResult.failure(error),
    );
  }

  Future<ApiResult<Account>> switchAccount(String accountId) async {
    final accounts = await _storageService.getAccounts();
    final account = accounts.where((a) => a.id == accountId).firstOrNull;

    if (account == null) {
      return ApiResult.failure(ApiException.notFound('Account'));
    }

    await _storageService.setActiveAccountId(accountId);
    _apiService.setBaseUrl(account.host);
    _apiService.setAuth(account.username, account.apiKey);

    return ApiResult.success(account);
  }

  Future<void> removeAccount(String accountId) async {
    await _storageService.removeAccount(accountId);
    final activeAccount = await _storageService.getActiveAccount();
    if (activeAccount != null) {
      _apiService.setBaseUrl(activeAccount.host);
      _apiService.setAuth(activeAccount.username, activeAccount.apiKey);
    } else {
      _apiService.clearAuth();
    }
  }

  Future<void> logout() async {
    final activeAccount = await _storageService.getActiveAccount();
    if (activeAccount != null) {
      await removeAccount(activeAccount.id);
    }
  }

  Future<Account?> initializeAuth() async {
    final activeAccount = await _storageService.getActiveAccount();
    if (activeAccount != null) {
      _apiService.setBaseUrl(activeAccount.host);
      _apiService.setAuth(activeAccount.username, activeAccount.apiKey);
      return activeAccount;
    }
    return null;
  }
}
