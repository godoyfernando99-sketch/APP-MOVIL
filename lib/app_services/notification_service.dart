import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:scanneranimal/app/history/scan_models.dart';
import 'package:vibration/vibration.dart';

class NotificationService {
  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null, 
      [
        NotificationChannel(
          channelKey: 'emergency_channel',
          channelName: 'Alertas de Emergencia',
          channelDescription: 'Notificaciones para casos urgentes',
          defaultColor: const Color(0xFF9D50BB),
          ledColor: Colors.red,
          importance: NotificationImportance.Max,
          channelShowBadge: true,
          criticalAlerts: true,
          playSound: true,
          enableVibration: true,
        ),
        NotificationChannel(
          channelKey: 'treatment_channel',
          channelName: 'Tratamientos y Dosis',
          channelDescription: 'Medicamentos y re-escaneos',
          defaultColor: const Color(0xFF2196F3),
          ledColor: Colors.blue,
          importance: NotificationImportance.High,
        ),
        NotificationChannel(
          channelKey: 'gestation_channel',
          channelName: 'Seguimiento de Gestación',
          channelDescription: 'Alertas de parto',
          defaultColor: const Color(0xFFE91E63),
          ledColor: Colors.pink,
          importance: NotificationImportance.High,
        ),
      ],
      debug: false,
    );
  }

  static Future<void> programarAlertasSegunResultado(ScanResult result) async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
      if (!(await AwesomeNotifications().isNotificationAllowed())) return;
    }

    final String animalName = result.animalType;
    final String localTimeZone = await AwesomeNotifications().getLocalTimeZoneIdentifier();

    // 1. VIBRACIÓN Y ALERTA URGENTE (SI ES ALTO RIESGO)
    if (result.isHighRisk) {
      bool? hasVib = await Vibration.hasVibrator();
      if (hasVib == true) {
        Vibration.vibrate(
          pattern: [500, 1000, 500, 1000],
          intensities: [128, 255, 128, 255],
        );
      }

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 911,
          channelKey: 'emergency_channel',
          title: '🚨 URGENCIA MÉDICA: $animalName',
          body: 'Se detectó una condición grave que requiere atención inmediata.',
          notificationLayout: NotificationLayout.BigText,
          backgroundColor: Colors.red,
          wakeUpScreen: true,
        ),
      );
    }

    // 2. RECORDATORIO DE RE-ESCANEO (CADA 3 DÍAS)
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 333,
        channelKey: 'treatment_channel',
        title: '📸 Control Evolutivo: $animalName',
        body: 'Han pasado 3 días. Realiza un nuevo escaneo para verificar si el tratamiento está funcionando.',
      ),
      schedule: NotificationInterval(
        interval: const Duration(hours: 72),
        repeats: true,
        timeZone: localTimeZone,
        preciseAlarm: true,
      ),
    );

    // 3. SEGUIMIENTO DE GESTACIÓN / PARTO
    // Se utiliza el campo daysUntilDelivery corregido para programar la alerta
    if (result.isPregnant && (result.daysUntilDelivery ?? 0) > 0) {
      // Notificación de advertencia 24 horas antes del parto estimado
      int diasParaNotificar = result.daysUntilDelivery! > 1 ? result.daysUntilDelivery! - 1 : 1;

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 777,
          channelKey: 'gestation_channel',
          title: '🐣 Parto Próximo: $animalName',
          // CORRECCIÓN: Ahora el mensaje es dinámico con el tiempo de gestación actual y crías
          body: 'Estado actual: ${result.gestationWeeks}. Quedan aprox. 24h para el parto. Prepárate para recibir a las crías (${result.offspringCount ?? 'varias'}).',
          notificationLayout: NotificationLayout.BigText,
        ),
        schedule: NotificationInterval(
          interval: Duration(days: diasParaNotificar),
          repeats: false,
          timeZone: localTimeZone,
          preciseAlarm: true,
        ),
      );
    }
  }
}