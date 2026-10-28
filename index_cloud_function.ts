import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

/**
 * Cloud Function que escucha la creación de una nueva alerta en Firestore
 * y despacha notificaciones push críticas a todos los dispositivos vecinales.
 */
export const onCommunityEmergencyCreated = functions.firestore
  .document("emergencias_comunitarias/{alertId}")
  .onCreate(async (snapshot, context) => {
    const alertData = snapshot.data();
    if (!alertData) return;

    const tipo = alertData.tipoEmergencia || "EMERGENCIA";
    const casa = alertData.houseNumber || "Domicilio no especificado";
    const acceso = alertData.primaryAccess || "San Ignacio 1659";
    const tieneVulnerables = alertData.contacto?.tieneVulnerables ? " (Atención prioritaria: persona vulnerable en el hogar)" : "";

    // Payload unificado cumpliendo estándares de alertas críticas (APNs y Android)
    const payload: admin.messaging.Message = {
      topic: "villa_elena_barros_alerts",
      notification: {
        title: `🚨 ALERTA COMUNITARIA: ${tipo}`,
        body: `Ubicación: ${casa} - Acceso: ${acceso}${tieneVulnerables}. Ingrese a la app para coordinar ayuda o evacuar.`,
      },
      data: {
        alertId: context.params.alertId,
        houseId: alertData.houseId || "",
        houseNumber: casa,
        tipoEmergencia: tipo,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "emergency_channel_high_priority",
          sound: "emergency_siren",
          priority: "max",
          visibility: "public",
          defaultVibrateTimings: true,
        },
      },
      apns: {
        headers: {
          "apns-priority": "10", // Prioridad inmediata
          "apns-push-type": "alert",
        },
        payload: {
          aps: {
            alert: {
              title: `🚨 ALERTA CRÍTICA: ${tipo}`,
              body: `Emergencia activa en ${casa} (${acceso}).`,
            },
            // Requiere aprobación del entitlement "com.apple.developer.usernotifications.critical-alerts" de Apple
            sound: {
              critical: true,
              name: "emergency_siren.aiff",
              volume: 1.0, // Omite el switch de silencio
            },
            badge: 1,
          },
        },
      },
    };

    try {
      const response = await admin.messaging().send(payload);
      console.log(`Notificación crítica despachada con éxito: ${response}`);
    } catch (error) {
      console.error("Error al despachar notificación crítica:", error);
    }
  });
