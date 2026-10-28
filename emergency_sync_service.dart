import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Enum de las 4 amenazas base normadas en la plataforma comunitaria "SS"
enum TipoEmergenciaSS {
  fuegoIncendio,
  postSismo,
  salud,
  robo,
}

extension TipoEmergenciaSSExt on TipoEmergenciaSS {
  String get codigo {
    switch (this) {
      case TipoEmergenciaSS.fuegoIncendio:
        return 'FUEGO_INCENDIO';
      case TipoEmergenciaSS.postSismo:
        return 'POST_SISMO';
      case TipoEmergenciaSS.salud:
        return 'SALUD';
      case TipoEmergenciaSS.robo:
        return 'ROBO';
    }
  }

  String get numeroDespacho {
    switch (this) {
      case TipoEmergenciaSS.fuegoIncendio:
        return '132'; // Bomberos de Chile
      case TipoEmergenciaSS.postSismo:
        return '+56227082983'; // Seguridad Municipal / Interna
      case TipoEmergenciaSS.salud:
        return '131'; // SAMU
      case TipoEmergenciaSS.robo:
        return '133'; // Carabineros de Chile
    }
  }
}

/// Modelo de Alerta Activa para sincronización reactiva
class AlertaComunitariaModel {
  final String idAlerta;
  final String houseId;
  final String houseNumber;
  final String primaryAccess;
  final TipoEmergenciaSS tipoEmergencia;
  final String estado; // 'ACTIVA', 'EN_APOYO', 'CONTROLADA', 'CERRADA'
  final DateTime fechaHora;
  final String representanteNombre;
  final String representanteFono;
  final bool tieneVulnerables;
  final int totalOcupantes;

  AlertaComunitariaModel({
    required this.idAlerta,
    required this.houseId,
    required this.houseNumber,
    required this.primaryAccess,
    required this.tipoEmergencia,
    required this.estado,
    required this.fechaHora,
    required this.representanteNombre,
    required this.representanteFono,
    required this.tieneVulnerables,
    required this.totalOcupantes,
  });

  factory AlertaComunitariaModel.fromMap(String docId, Map<String, dynamic> map) {
    TipoEmergenciaSS parseTipo(String? val) {
      switch (val) {
        case 'FUEGO_INCENDIO':
          return TipoEmergenciaSS.fuegoIncendio;
        case 'POST_SISMO':
          return TipoEmergenciaSS.postSismo;
        case 'SALUD':
          return TipoEmergenciaSS.salud;
        case 'ROBO':
          return TipoEmergenciaSS.robo;
        default:
          return TipoEmergenciaSS.fuegoIncendio;
      }
    }

    return AlertaComunitariaModel(
      idAlerta: docId,
      houseId: map['houseId'] ?? '',
      houseNumber: map['houseNumber'] ?? '',
      primaryAccess: map['primaryAccess'] ?? 'San Ignacio 1659',
      tipoEmergencia: parseTipo(map['tipoEmergencia']),
      estado: map['estado'] ?? 'ACTIVA',
      fechaHora: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      representanteNombre: map['contacto']?['nombre'] ?? '',
      representanteFono: map['contacto']?['telefono'] ?? '',
      tieneVulnerables: map['contacto']?['tieneVulnerables'] ?? false,
      totalOcupantes: map['contacto']?['totalOcupantes'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'houseId': houseId,
      'houseNumber': houseNumber,
      'primaryAccess': primaryAccess,
      'tipoEmergencia': tipoEmergencia.codigo,
      'estado': estado,
      'timestamp': FieldValue.serverTimestamp(),
      'contacto': {
        'nombre': representanteNombre,
        'telefono': representanteFono,
        'tieneVulnerables': tieneVulnerables,
        'totalOcupantes': totalOcupantes,
      },
      'sectorComunidad': 'Villa Elena Barros (San Ignacio 1659 / Av. Viel 1660)',
    };
  }
}

/// Servicio de Despacho y Sincronización en Tiempo Real
class EmergencySyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  EmergencySyncService() {
    // Configuración Local-First para alta disponibilidad en desastres
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  /// Stream reactivo para escuchar la emergencia activa que debe reflejarse en el plano
  Stream<AlertaComunitariaModel?> streamAlertaActiva() {
    return _firestore
        .collection('emergencias_comunitarias')
        .where('estado', whereIn: ['ACTIVA', 'EN_APOYO'])
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          final doc = snapshot.docs.first;
          return AlertaComunitariaModel.fromMap(doc.id, doc.data());
        });
  }

  /// Emite la señal hacia Firestore con fallback automático a SMS directo si no hay datos
  Future<void> emitirAlerta({
    required String houseId,
    required String houseNumber,
    required String primaryAccess,
    required TipoEmergenciaSS tipo,
    required String representanteNombre,
    required String representanteFono,
    required bool tieneVulnerables,
    required int totalOcupantes,
  }) async {
    final alertData = AlertaComunitariaModel(
      idAlerta: 'ALERT_${DateTime.now().millisecondsSinceEpoch}',
      houseId: houseId,
      houseNumber: houseNumber,
      primaryAccess: primaryAccess,
      tipoEmergencia: tipo,
      estado: 'ACTIVA',
      fechaHora: DateTime.now(),
      representanteNombre: representanteNombre,
      representanteFono: representanteFono,
      tieneVulnerables: tieneVulnerables,
      totalOcupantes: totalOcupantes,
    );

    try {
      // 1. Escritura local/remota en Firestore
      await _firestore
          .collection('emergencias_comunitarias')
          .doc(alertData.idAlerta)
          .set(alertData.toMap());

      // 2. Verificar conectividad para despachar fallback por SMS de ser requerido
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        await _despacharFallbackSMS(alertData);
      }
    } catch (e) {
      debugPrint('Error de red al emitir alarma en la nube: $e');
      await _despacharFallbackSMS(alertData);
    }
  }

  /// Cierre o resolución de la emergencia
  Future<void> resolverAlerta(String idAlerta) async {
    await _firestore
        .collection('emergencias_comunitarias')
        .doc(idAlerta)
        .update({
      'estado': 'CONTROLADA',
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Marcado directo 1-tap al organismo público oficial
  Future<void> llamarOrganismoEmergencia(String numero) async {
    final Uri uri = Uri(scheme: 'tel', path: numero);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  /// Fallback mediante SMS con coordenadas y datos clave hacia líder comunitario
  Future<void> _despacharFallbackSMS(AlertaComunitariaModel alerta) async {
    final String mensaje = Uri.encodeComponent(
      'EMERGENCIA ${alerta.tipoEmergencia.codigo} en ${alerta.houseNumber} '
      '(${alerta.primaryAccess}). Resp: ${alerta.representanteNombre} '
      '(${alerta.representanteFono}). Ocupantes: ${alerta.totalOcupantes}. '
      'Vulnerables: ${alerta.tieneVulnerables ? "SI" : "NO"}.'
    );
    // Número del Coordinador de Gestión de Riesgos o central de monitoreo
    const String fonoCoordinador = '+56227082983';
    final Uri smsUri = Uri.parse('sms:$fonoCoordinador?body=$mensaje');

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    }
  }
}
