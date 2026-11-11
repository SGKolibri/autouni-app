package com.example.autouni_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity

// FragmentActivity é exigência do local_auth (BiometricPrompt).
class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createAlertsChannel()
    }

    /**
     * Canal dos alertas do campus. O backend envia o push com
     * `channelId = "autouni_alerts"` (S5-T6); sem o canal criado, o Android
     * cai no canal genérico, com prioridade baixa. Criar de novo é inofensivo.
     */
    private fun createAlertsChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            ALERTS_CHANNEL_ID,
            "Alertas do campus",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Falhas de dispositivos, consumo e automações"
        }
        getSystemService(NotificationManager::class.java)
            .createNotificationChannel(channel)
    }

    private companion object {
        const val ALERTS_CHANNEL_ID = "autouni_alerts"
    }
}
