/// Desfecho de um pedido de biometria ao usuário.
enum BiometricAuthResult {
  /// Biometria confirmada.
  success,

  /// Não confirmou: biometria não reconhecida, cancelada ou interrompida.
  /// Dá para tentar de novo.
  failed,

  /// Tentativas demais: o sistema bloqueou a biometria por um tempo (ou até
  /// o usuário desbloquear o aparelho com a senha/PIN).
  lockedOut,

  /// Não há como pedir biometria agora (sem hardware, nada cadastrado, erro
  /// do aparelho). O caminho é o login por senha.
  unavailable,
}

/// Biometria do aparelho, abstraída para as features não dependerem do
/// plugin (e poderem mocká-la nos testes). Nenhum método lança.
abstract interface class BiometricAuthenticator {
  /// O aparelho tem hardware e alguma biometria cadastrada?
  Future<bool> isAvailable();

  /// Abre o prompt do sistema. [reason] é o texto exibido ao usuário.
  Future<BiometricAuthResult> authenticate({required String reason});
}
