/// Limites dos controles contextuais (S4-T4). O backend aceita faixas mais
/// largas (temperatura de -50 a 150), então o app aplica as do produto.
abstract final class DeviceLimits {
  /// Dimmer de iluminação, em %.
  static const int minIntensity = 0;
  static const int maxIntensity = 100;

  /// Termostato de ar-condicionado, em °C.
  static const double minTemperature = 16;
  static const double maxTemperature = 30;

  /// Passo do termostato.
  static const double temperatureStep = 1;

  /// Mensagem de erro para [value], ou `null` se estiver na faixa.
  static String? validateIntensity(num value) =>
      value < minIntensity || value > maxIntensity || value != value.round()
      ? 'O brilho vai de $minIntensity% a $maxIntensity%.'
      : null;

  static String? validateTemperature(num value) =>
      value.isNaN || value < minTemperature || value > maxTemperature
      ? 'A temperatura vai de ${minTemperature.round()} °C a '
            '${maxTemperature.round()} °C.'
      : null;

  /// Traz [value] para a faixa do dimmer (inteiro).
  static int clampIntensity(num value) =>
      value.round().clamp(minIntensity, maxIntensity);

  /// Traz [value] para a faixa do termostato, no passo de 1 °C.
  static double clampTemperature(num value) {
    final stepped = (value / temperatureStep).round() * temperatureStep;
    return stepped.clamp(minTemperature, maxTemperature).toDouble();
  }
}
