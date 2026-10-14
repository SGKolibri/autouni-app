/// Política de retry dos providers do app: nenhuma automática.
///
/// O Riverpod 3 refaz por padrão providers que falham (até 10 vezes, com
/// backoff). Aqui as telas já mostram o cache quando a rede cai e oferecem
/// "Tentar de novo" — um retry silencioso só faria o estado de erro piscar e
/// repetir requests contra um backend com problema.
Duration? noAutomaticRetry(int retryCount, Object error) => null;
