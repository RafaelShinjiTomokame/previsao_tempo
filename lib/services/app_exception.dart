enum AppErrorType { network, serviceUnavailable, invalidResponse }

/// Erro de domínio, com mensagem pronta para ser exibida ao usuário.
class AppException implements Exception {
  final AppErrorType type;
  final String message;

  const AppException(this.type, this.message);

  const AppException.network()
      : this(AppErrorType.network,
            'Falha de conexão. Verifique sua internet e tente novamente.');

  const AppException.unavailable([int? status])
      : this(AppErrorType.serviceUnavailable,
            'O serviço do CPTEC/INPE está indisponível no momento. Tente novamente mais tarde.');

  const AppException.invalid()
      : this(AppErrorType.invalidResponse,
            'O serviço retornou uma resposta inválida. Tente novamente mais tarde.');

  @override
  String toString() => message;
}
