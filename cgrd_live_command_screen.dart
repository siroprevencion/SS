import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

/// Modelo de Alerta Activa para escucha reactiva en el Panel CGRD
class ActiveEmergencyEvent {
  final String id;
  final String houseId;
  final String houseNumber;
  final String primaryAccess;
  final String threatType;
  final String status;
  final DateTime timestamp;
  final String repName;
  final String repPhone;
  final bool hasVulnerabilities;
  final int totalOccupants;

  ActiveEmergencyEvent({
    required this.id,
    required this.houseId,
    required this.houseNumber,
    required this.primaryAccess,
    required this.threatType,
    required this.status,
    required this.timestamp,
    required this.repName,
    required this.repPhone,
    required this.hasVulnerabilities,
    required this.totalOccupants,
  });

  factory ActiveEmergencyEvent.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ActiveEmergencyEvent(
      id: doc.id,
      houseId: data['houseId'] ?? '',
      houseNumber: data['houseNumber'] ?? 'N/A',
      primaryAccess: data['primaryAccess'] ?? 'San Ignacio 1659',
      threatType: data['tipoEmergencia'] ?? 'DESCONOCIDA',
      status: data['estado'] ?? 'ACTIVA',
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      repName: data['contacto']?['nombre'] ?? 'Sin asignar',
      repPhone: data['contacto']?['telefono'] ?? '',
      hasVulnerabilities: data['contacto']?['tieneVulnerables'] ?? false,
      totalOccupants: data['contacto']?['totalOcupantes'] ?? 1,
    );
  }
}

/// Pantalla Integral de Mando CGRD y Bitácora de Cierre Post-Incidente (Ley N° 21.364)
class CGRDLiveCommandScreen extends StatefulWidget {
  const CGRDLiveCommandScreen({Key? key}) : super(key: key);

  @override
  State<CGRDLiveCommandScreen> createState() => _CGRDLiveCommandScreenState();
}

class _CGRDLiveCommandScreenState extends State<CGRDLiveCommandScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _callEmergency(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _openCloseIncidentModal(BuildContext context, ActiveEmergencyEvent event) {
    final summaryCtrl = TextEditingController();
    final damagesCtrl = TextEditingController();
    final actionsCtrl = TextEditingController();
    final lessonsCtrl = TextEditingController();
    bool isDrill = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1D27),
              title: Row(
                children: [
                  const Icon(Icons.fact_check_outlined, color: Color(0xFF00E676)),
                  const SizedBox(width: 10),
                  Text(
                    'Acta de Cierre / Bitácora: ${event.houseNumber}',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 500,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('¿Corresponde a un Simulacro programado?', style: TextStyle(color: Colors.white, fontSize: 13)),
                        subtitle: const Text('Registro conforme a GRD_XX_REG_13 / GRD_XX_REG_14', style: TextStyle(color: Colors.white54, fontSize: 11)),
                        value: isDrill,
                        activeColor: const Color(0xFF00E676),
                        onChanged: (val) => setModalState(() => isDrill = val),
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(summaryCtrl, 'Evaluación y Resumen de la Respuesta (ACCEDER)', 3),
                      const SizedBox(height: 12),
                      _buildTextField(damagesCtrl, 'Daños a personas o infraestructura (Evaluación secundaria)', 2),
                      const SizedBox(height: 12),
                      _buildTextField(actionsCtrl, 'Organismos externos que concurrieron (Bomberos, Carabineros, SAMU)', 2),
                      const SizedBox(height: 12),
                      _buildTextField(lessonsCtrl, 'Lecciones aprendidas y Readecuación del Plan (Fase R)', 2),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('CANCELAR', style: TextStyle(color: Colors.white60)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                  onPressed: () async {
                    // 1. Guardar en Bitácora histórica permanente
                    await _firestore.collection('bitacora_incidentes_cgrd').add({
                      'alertId': event.id,
                      'houseId': event.houseId,
                      'houseNumber': event.houseNumber,
                      'threatType': event.threatType,
                      'primaryAccess': event.primaryAccess,
                      'isDrill': isDrill,
                      'summary': summaryCtrl.text.trim(),
                      'damages': damagesCtrl.text.trim(),
                      'externalResponders': actionsCtrl.text.trim(),
                      'lessonsLearned': lessonsCtrl.text.trim(),
                      'closedAt': FieldValue.serverTimestamp(),
                      'closedBy': 'Líder de Respuesta CGRD',
                      'sector': 'Villa Elena Barros',
                    });

                    // 2. Actualizar estado de la alerta en vivo para despejar la señal del plano
                    await _firestore.collection('emergencias_comunitarias').doc(event.id).update({
                      'estado': 'CONTROLADA',
                      'resolvedAt': FieldValue.serverTimestamp(),
                    });

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Incidente cerrado y registrado formalmente en la Bitácora CGRD.'),
                        backgroundColor: Color(0xFF2E7D32),
                      ),
                    );
                  },
                  child: const Text('FINALIZAR Y REGISTRAR ACTA'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, int lines) {
    return TextField(
      controller: ctrl,
      maxLines: lines,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
        filled: true,
        fillColor: const Color(0xFF141720),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgDark = Color(0xFF0F1117);
    const cardDark = Color(0xFF1A1D27);
    const brandGreen = Color(0xFF00E676);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: const Text('Consola Reactiva CGRD - Villa Elena Barros (Ley N° 21.364)'),
        backgroundColor: const Color(0xFF141720),
        elevation: 1,
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            icon: const Icon(Icons.fire_truck),
            label: const Text('132 Bomberos'),
            onPressed: () => _callEmergency('132'),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.lightBlueAccent),
            icon: const Icon(Icons.medical_services),
            label: const Text('131 SAMU'),
            onPressed: () => _callEmergency('131'),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.purpleAccent),
            icon: const Icon(Icons.local_police),
            label: const Text('133 Carabineros'),
            onPressed: () => _callEmergency('133'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('emergencias_comunitarias')
            .where('estado', whereIn: ['ACTIVA', 'EN_APOYO'])
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          final alerts = snapshot.hasData
              ? snapshot.data!.docs.map((d) => ActiveEmergencyEvent.fromDoc(d)).toList()
              : <ActiveEmergencyEvent>[];

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PANEL IZQUIERDO: Alertas Activas en Tiempo Real disparadas desde el plano
              Expanded(
                flex: 5,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildHeader('ALERTAS EN TIEMPO REAL RECIBIDAS DE LA COMUNIDAD', Icons.radar, brandGreen),
                    if (alerts.isEmpty)
                      Card(
                        color: cardDark,
                        child: const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(Icons.check_circle_outline, color: brandGreen, size: 48),
                              SizedBox(height: 12),
                              Text('Comunidad sin emergencias activas', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                              Text('Monitoreo permanente en pasajes San Ignacio 1659 y Av. Viel 1660.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                        ),
                      )
                    else
                      ...alerts.map((alert) {
                        return Card(
                          color: const Color(0xFF24141A),
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(color: Color(0xFFFF5252), width: 1.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          margin: const EdgeInsets.only(bottom: 14),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5252)),
                                        const SizedBox(width: 8),
                                        Text('${alert.threatType} DECLARADO', style: const TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.bold, fontSize: 15)),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: const Color(0xFFFF5252).withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                                      child: Text(alert.status, style: const TextStyle(color: Color(0xFFFF5252), fontSize: 11, fontWeight: FontWeight.bold)),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text('Vivienda: ${alert.houseNumber} (${alert.primaryAccess})', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                Text('Representante: ${alert.repName} | Fono: ${alert.repPhone}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                Text('Carga Habitacional: ${alert.totalOccupants} residentes', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                                if (alert.hasVulnerabilities)
                                  Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.accessible, color: Colors.amber, size: 16),
                                        SizedBox(width: 6),
                                        Text('ALERTA GRD_XX_REG_10: Presencia de personas vulnerables en este domicilio', style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                const Divider(color: Colors.white12, height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(foregroundColor: brandGreen, side: const BorderSide(color: brandGreen)),
                                      icon: const Icon(Icons.phone),
                                      label: const Text('LLAMAR VECINO'),
                                      onPressed: () => _callEmergency(alert.repPhone),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                                      icon: const Icon(Icons.fact_check),
                                      label: const Text('GESTIONAR / CERRAR ACTA'),
                                      onPressed: () => _openCloseIncidentModal(context, alert),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),

              // PANEL DERECHO: Historial de la Bitácora y Actas CGRD
              Expanded(
                flex: 5,
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('bitacora_incidentes_cgrd').orderBy('closedAt', descending: true).limit(10).snapshots(),
                  builder: (context, bitacoraSnap) {
                    final registros = bitacoraSnap.hasData ? bitacoraSnap.data!.docs : [];

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildHeader('BITÁCORA HISTÓRICA Y ACTAS DE REUNIÓN CGRD (GRD_XX_REG_04)', Icons.history_edu, Colors.lightBlueAccent),
                        if (registros.isEmpty)
                          Card(
                            color: cardDark,
                            child: const Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Text('No hay cierres de incidentes archivados aún.', style: TextStyle(color: Colors.white54, fontSize: 13)),
                            ),
                          )
                        else
                          ...registros.map((doc) {
                            final bData = doc.data() as Map<String, dynamic>;
                            final bool esSimulacro = bData['isDrill'] ?? false;
                            return Card(
                              color: cardDark,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('${bData['threatType']} - ${bData['houseNumber']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: esSimulacro ? Colors.blue.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(esSimulacro ? 'SIMULACRO' : 'REAL', style: TextStyle(color: esSimulacro ? Colors.blueAccent : brandGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text('Evaluación: ${bData['summary'] ?? "Sin registro"}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                    Text('Organismos externos: ${bData['externalResponders'] ?? "N/A"}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                                    Text('Readecuación (Fase R): ${bData['lessonsLearned'] ?? "N/A"}', style: const TextStyle(color: Colors.amberAccent, fontSize: 11)),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
