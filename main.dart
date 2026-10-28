import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const SSAlertaComunitariaApp());
}

class SSAlertaComunitariaApp extends StatelessWidget {
  const SSAlertaComunitariaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SS Alerta Vecinal - Villa Elena Barros',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF10131A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E676),
          secondary: Color(0xFF2979FF),
          surface: Color(0xFF191D28),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

/// Estado global en memoria para probar la aplicación de inmediato (Mock / Demo Reactivo)
class AppState {
  static final AppState instance = AppState._();
  AppState._();

  final ValueNotifier<List<HouseNode>> housesNotifier = ValueNotifier<List<HouseNode>>([
    HouseNode(
      id: 'H1',
      number: 'Casa 01',
      boundary: const Rect.fromLTWH(70, 150, 75, 95),
      primaryAccess: 'San Ignacio 1659',
      representativeName: 'Elena Soto',
      contactPhone: '+56 9 8811 2233',
      totalOccupants: 2,
    ),
    HouseNode(
      id: 'H2',
      number: 'Casa 02',
      boundary: const Rect.fromLTWH(170, 150, 75, 95),
      primaryAccess: 'San Ignacio 1659',
      representativeName: 'Carlos Fuentes',
      contactPhone: '+56 9 7722 3344',
      totalOccupants: 3,
    ),
    HouseNode(
      id: 'H3',
      number: 'Casa 03',
      boundary: const Rect.fromLTWH(270, 150, 75, 95),
      primaryAccess: 'San Ignacio 1659',
      hasVulnerablePersons: true,
      representativeName: 'Matías Martínez',
      contactPhone: '+56 9 1234 5678',
      totalOccupants: 3,
      medicalNotes: 'Adulto mayor con movilidad reducida',
    ),
    HouseNode(
      id: 'H4',
      number: 'Casa 04',
      boundary: const Rect.fromLTWH(370, 150, 75, 95),
      primaryAccess: 'Av. Viel 1660',
      representativeName: 'Ana Morales',
      contactPhone: '+56 9 6655 4433',
      totalOccupants: 4,
    ),
    HouseNode(
      id: 'H5',
      number: 'Casa 05',
      boundary: const Rect.fromLTWH(70, 370, 75, 95),
      primaryAccess: 'San Ignacio 1659',
      representativeName: 'Pedro Valdivia',
      contactPhone: '+56 9 5544 3322',
      totalOccupants: 2,
    ),
    HouseNode(
      id: 'H6',
      number: 'Casa 06',
      boundary: const Rect.fromLTWH(170, 370, 75, 95),
      primaryAccess: 'San Ignacio 1659',
      representativeName: 'Rosa Araya',
      contactPhone: '+56 9 4433 2211',
      totalOccupants: 1,
    ),
    HouseNode(
      id: 'H7',
      number: 'Casa 07',
      boundary: const Rect.fromLTWH(270, 370, 75, 95),
      primaryAccess: 'Av. Viel 1660',
      hasVulnerablePersons: true,
      representativeName: 'Jorge Farías',
      contactPhone: '+56 9 3322 1100',
      totalOccupants: 2,
      medicalNotes: 'Paciente electrodependiente',
    ),
    HouseNode(
      id: 'H8',
      number: 'Casa 08',
      boundary: const Rect.fromLTWH(370, 370, 75, 95),
      primaryAccess: 'Av. Viel 1660',
      representativeName: 'Lucía Núñez',
      contactPhone: '+56 9 2211 0099',
      totalOccupants: 1,
    ),
  ]);

  final ValueNotifier<ActiveEmergencyEvent?> activeAlertNotifier = ValueNotifier<ActiveEmergencyEvent?>(null);
  final ValueNotifier<List<BitacoraRecord>> bitacoraNotifier = ValueNotifier<List<BitacoraRecord>>([]);
}

/// Navegación Principal con barra inferior (Tabs)
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _views = const [
    VillaVectorMapScreen(),
    HouseListAndRegistrationScreen(),
    CGRDLiveCommandScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _views[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: const Color(0xFF141720),
        selectedItemColor: const Color(0xFF00E676),
        unselectedItemColor: Colors.white54,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Plano Villa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Catastro Casas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shield_outlined),
            activeIcon: Icon(Icons.shield),
            label: 'Mando CGRD',
          ),
        ],
      ),
    );
  }
}

// ==========================================
// MÓDULO 1: TIPOS Y MODELOS DE DATOS
// ==========================================

enum ThreatType { fuegoIncendio, postSismo, salud, robo }

extension ThreatDetails on ThreatType {
  String get label {
    switch (this) {
      case ThreatType.fuegoIncendio:
        return '1. Fuego / Incendio';
      case ThreatType.postSismo:
        return '2. Emerg. Post Sismo';
      case ThreatType.salud:
        return '3. Emerg. Salud';
      case ThreatType.robo:
        return '4. Emerg. Robo / Intrusión';
    }
  }

  Color get color {
    switch (this) {
      case ThreatType.fuegoIncendio:
        return const Color(0xFFD32F2F);
      case ThreatType.postSismo:
        return const Color(0xFFF57C00);
      case ThreatType.salud:
        return const Color(0xFF1976D2);
      case ThreatType.robo:
        return const Color(0xFF7B1FA2);
    }
  }

  IconData get icon {
    switch (this) {
      case ThreatType.fuegoIncendio:
        return Icons.local_fire_department;
      case ThreatType.postSismo:
        return Icons.broken_image;
      case ThreatType.salud:
        return Icons.medical_services;
      case ThreatType.robo:
        return Icons.shield;
    }
  }

  String get defaultEmergencyNumber {
    switch (this) {
      case ThreatType.fuegoIncendio:
        return '132';
      case ThreatType.postSismo:
        return '+56227082983';
      case ThreatType.salud:
        return '131';
      case ThreatType.robo:
        return '133';
    }
  }
}

class HouseNode {
  final String id;
  String number;
  final Rect boundary;
  String primaryAccess;
  bool hasVulnerablePersons;
  String representativeName;
  String contactPhone;
  int totalOccupants;
  String medicalNotes;

  HouseNode({
    required this.id,
    required this.number,
    required this.boundary,
    required this.primaryAccess,
    this.hasVulnerablePersons = false,
    this.representativeName = '',
    this.contactPhone = '',
    this.totalOccupants = 1,
    this.medicalNotes = '',
  });
}

class ActiveEmergencyEvent {
  final String id;
  final String houseId;
  final String houseNumber;
  final String primaryAccess;
  final ThreatType threatType;
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
    required this.timestamp,
    required this.repName,
    required this.repPhone,
    required this.hasVulnerabilities,
    required this.totalOccupants,
  });
}

class BitacoraRecord {
  final String id;
  final String houseNumber;
  final String threatName;
  final bool isDrill;
  final String summary;
  final String damages;
  final String responders;
  final String lessons;
  final DateTime date;

  BitacoraRecord({
    required this.id,
    required this.houseNumber,
    required this.threatName,
    required this.isDrill,
    required this.summary,
    required this.damages,
    required this.responders,
    required this.lessons,
    required this.date,
  });
}

// ==========================================
// MÓDULO 2: PLANO VECTORIAL INTERACTIVO
// ==========================================

class VillaVectorMapScreen extends StatefulWidget {
  const VillaVectorMapScreen({Key? key}) : super(key: key);

  @override
  State<VillaVectorMapScreen> createState() => _VillaVectorMapScreenState();
}

class _VillaVectorMapScreenState extends State<VillaVectorMapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _triggerEmergency(ThreatType threat, HouseNode house) {
    final alert = ActiveEmergencyEvent(
      id: 'ALERTA_${DateTime.now().millisecondsSinceEpoch}',
      houseId: house.id,
      houseNumber: house.number,
      primaryAccess: house.primaryAccess,
      threatType: threat,
      timestamp: DateTime.now(),
      repName: house.representativeName,
      repPhone: house.contactPhone,
      hasVulnerabilities: house.hasVulnerablePersons,
      totalOccupants: house.totalOccupants,
    );

    AppState.instance.activeAlertNotifier.value = alert;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: threat.color,
        content: Text('ALERTA TRANSMITIDA: ${threat.label} en ${house.number}'),
      ),
    );
  }

  void _onTapCanvas(Offset position, List<HouseNode> houses) {
    for (final h in houses) {
      if (h.boundary.contains(position)) {
        _showHouseEmergencyModal(h);
        return;
      }
    }
  }

  void _showHouseEmergencyModal(HouseNode house) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E212D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(house.number, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  if (house.hasVulnerablePersons)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.amber)),
                      child: const Text('GRUPO PRIORITARIO GRD', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Representante: ${house.representativeName.isEmpty ? "Sin registrar" : house.representativeName} | ${house.contactPhone}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              Text('Acceso y Evacuación: ${house.primaryAccess} (${house.totalOccupants} residentes)', style: const TextStyle(color: Colors.white60, fontSize: 12)),
              if (house.medicalNotes.isNotEmpty)
                Text('Observaciones: ${house.medicalNotes}', style: const TextStyle(color: Colors.amberAccent, fontSize: 12)),
              const Divider(color: Colors.white24, height: 24),
              const Text('DISPARAR SEÑAL DE EMERGENCIA EN ESTE DOMICILIO:', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ThreatType.values.map((t) {
                  return ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: t.color, foregroundColor: Colors.white),
                    icon: Icon(t.icon, size: 16),
                    label: Text(t.label, style: const TextStyle(fontSize: 12)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _triggerEmergency(t, house);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ActiveEmergencyEvent?>(
      valueListenable: AppState.instance.activeAlertNotifier,
      builder: (context, activeAlert, _) {
        return ValueListenableBuilder<List<HouseNode>>(
          valueListenable: AppState.instance.housesNotifier,
          builder: (context, houses, _) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Villa Elena Barros - Plano de Alerta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                backgroundColor: const Color(0xFF141720),
                actions: [
                  IconButton(tooltip: 'Bomberos 132', icon: const Icon(Icons.fire_truck, color: Colors.redAccent), onPressed: () => _call('132')),
                  IconButton(tooltip: 'SAMU 131', icon: const Icon(Icons.medical_services, color: Colors.blueAccent), onPressed: () => _call('131')),
                  IconButton(tooltip: 'Carabineros 133', icon: const Icon(Icons.local_police, color: Colors.purpleAccent), onPressed: () => _call('133')),
                ],
              ),
              body: Column(
                children: [
                  if (activeAlert != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: activeAlert.threatType.color,
                      child: Row(
                        children: [
                          Icon(activeAlert.threatType.icon, color: Colors.white, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'EMERGENCIA ACTIVA: ${activeAlert.threatType.label.toUpperCase()} en ${activeAlert.houseNumber} (${activeAlert.primaryAccess})',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black87),
                            onPressed: () => _call(activeAlert.threatType.defaultEmergencyNumber),
                            child: Text('LLAMAR ${activeAlert.threatType.defaultEmergencyNumber}'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => AppState.instance.activeAlertNotifier.value = null,
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: InteractiveViewer(
                      boundaryMargin: const EdgeInsets.all(20),
                      minScale: 0.6,
                      maxScale: 3.0,
                      child: Center(
                        child: GestureDetector(
                          onTapUp: (details) => _onTapCanvas(details.localPosition, houses),
                          child: SizedBox(
                            width: 520,
                            height: 580,
                            child: AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, _) {
                                return CustomPaint(
                                  painter: VillaMapPainter(
                                    houses: houses,
                                    activeAlert: activeAlert,
                                    pulseValue: _pulseController.value,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: const Color(0xFF141720),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Toca cualquier casa en el plano para reportar emergencia', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text('Ley N° 21.364 / SENAPRED', style: TextStyle(color: Colors.white30, fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class VillaMapPainter extends CustomPainter {
  final List<HouseNode> houses;
  final ActiveEmergencyEvent? activeAlert;
  final double pulseValue;

  VillaMapPainter({
    required this.houses,
    required this.activeAlert,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF222634);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(16)), bgPaint);

    // Calles perimetrales
    final streetPaint = Paint()..color = const Color(0xFF161924);
    canvas.drawRect(Rect.fromLTWH(0, 0, 45, size.height), streetPaint);
    canvas.drawRect(Rect.fromLTWH(size.width - 45, 0, 45, size.height), streetPaint);

    _drawVerticalText(canvas, 'SAN IGNACIO 1659', const Offset(15, 200), const Color(0xFF00E676));
    _drawVerticalText(canvas, 'AV. VIEL 1660', Offset(size.width - 28, 220), const Color(0xFF00E676));

    // Pasaje Central
    final roadPaint = Paint()..color = const Color(0xFF2D3244);
    canvas.drawRect(Rect.fromLTWH(45, 270, size.width - 90, 70), roadPaint);

    // Línea de evacuación
    final dashPaint = Paint()
      ..color = const Color(0xFF00E676).withOpacity(0.5)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(55, 305), Offset(size.width - 55, 305), dashPaint);

    // Recursos de Seguridad
    // PRI
    canvas.drawCircle(const Offset(260, 305), 18, Paint()..color = const Color(0xFF2E7D32));
    _drawText(canvas, 'P.R.I.', const Offset(260, 305), Colors.white, 9, FontWeight.bold);

    // PEE
    canvas.drawCircle(Offset(size.width - 25, 120), 16, Paint()..color = const Color(0xFF1B5E20));
    _drawText(canvas, 'P.E.E.', Offset(size.width - 25, 120), Colors.white, 8, FontWeight.bold);

    // Red Seca
    final rsPaint = Paint()..color = const Color(0xFFD32F2F);
    canvas.drawRect(const Rect.fromLTWH(50, 90, 16, 16), rsPaint);
    _drawText(canvas, 'R.S.', const Offset(58, 98), Colors.white, 7, FontWeight.bold);
    canvas.drawRect(Rect.fromLTWH(size.width - 66, 90, 16, 16), rsPaint);
    _drawText(canvas, 'R.S.', Offset(size.width - 58, 98), Colors.white, 7, FontWeight.bold);

    // Extintores PQS
    final pqsPaint = Paint()..color = const Color(0xFFFF5252);
    canvas.drawCircle(const Offset(150, 260), 6, pqsPaint);
    _drawText(canvas, 'PQS', const Offset(150, 250), Colors.white, 7, FontWeight.w600);
    canvas.drawCircle(const Offset(350, 260), 6, pqsPaint);
    _drawText(canvas, 'PQS', const Offset(350, 250), Colors.white, 7, FontWeight.w600);

    // Render Casas
    for (final house in houses) {
      final isEmergency = activeAlert != null && activeAlert!.houseId == house.id;
      final color = isEmergency ? activeAlert!.threatType.color : const Color(0xFF383E54);

      canvas.drawRRect(RRect.fromRectAndRadius(house.boundary, const Radius.circular(8)), Paint()..color = color);

      final borderPaint = Paint()
        ..color = isEmergency ? Colors.white : const Color(0xFF535C7A)
        ..strokeWidth = isEmergency ? 2.5 : 1.2
        ..style = PaintingStyle.stroke;
      canvas.drawRRect(RRect.fromRectAndRadius(house.boundary, const Radius.circular(8)), borderPaint);

      if (isEmergency) {
        final ripplePaint = Paint()
          ..color = activeAlert!.threatType.color.withOpacity(1.0 - pulseValue)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 + (pulseValue * 10);
        canvas.drawRRect(
          RRect.fromRectAndRadius(house.boundary.inflate(pulseValue * 10), const Radius.circular(12)),
          ripplePaint,
        );
      }

      _drawText(
        canvas,
        house.number,
        Offset(house.boundary.center.dx, house.boundary.center.dy - 6),
        isEmergency ? Colors.white : Colors.white70,
        12,
        FontWeight.bold,
      );

      if (house.hasVulnerablePersons && !isEmergency) {
        canvas.drawCircle(Offset(house.boundary.right - 12, house.boundary.top + 12), 4, Paint()..color = Colors.amber);
      }
    }
  }

  void _drawText(Canvas canvas, String text, Offset center, Color color, double fontSize, FontWeight weight) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: weight)),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - (tp.width / 2), center.dy - (tp.height / 2)));
  }

  void _drawVerticalText(Canvas canvas, String text, Offset pos, Color color) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(-math.pi / 2);
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant VillaMapPainter oldDelegate) => true;
}

// ==========================================
// MÓDULO 3: CATASTRO Y FORMULARIO DE CASAS
// ==========================================

class HouseListAndRegistrationScreen extends StatelessWidget {
  const HouseListAndRegistrationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catastro Vecinal (Ley N° 21.364)'),
        backgroundColor: const Color(0xFF141720),
      ),
      body: ValueListenableBuilder<List<HouseNode>>(
        valueListenable: AppState.instance.housesNotifier,
        builder: (context, houses, _) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: houses.length,
            itemBuilder: (ctx, i) {
              final h = houses[i];
              return Card(
                color: const Color(0xFF1A1D27),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF00E676).withOpacity(0.2),
                    child: Text(h.number.replaceAll('Casa ', ''), style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
                  ),
                  title: Text('${h.number} - ${h.representativeName.isEmpty ? "Sin Registrar" : h.representativeName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Fono: ${h.contactPhone.isEmpty ? "Pendiente" : h.contactPhone} | Ocupantes: ${h.totalOccupants} | Acceso: ${h.primaryAccess}', style: const TextStyle(fontSize: 12, color: Colors.white60)),
                  trailing: const Icon(Icons.edit_note, color: Color(0xFF00E676)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => EditHouseScreen(house: h)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class EditHouseScreen extends StatefulWidget {
  final HouseNode house;
  const EditHouseScreen({Key? key, required this.house}) : super(key: key);

  @override
  State<EditHouseScreen> createState() => _EditHouseScreenState();
}

class _EditHouseScreenState extends State<EditHouseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _repNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _occupantsCtrl;
  late TextEditingController _notesCtrl;
  late String _access;
  late bool _hasVulnerable;

  @override
  void initState() {
    super.initState();
    _repNameCtrl = TextEditingController(text: widget.house.representativeName);
    _phoneCtrl = TextEditingController(text: widget.house.contactPhone);
    _occupantsCtrl = TextEditingController(text: widget.house.totalOccupants.toString());
    _notesCtrl = TextEditingController(text: widget.house.medicalNotes);
    _access = widget.house.primaryAccess;
    _hasVulnerable = widget.house.hasVulnerablePersons;
  }

  @override
  void dispose() {
    _repNameCtrl.dispose();
    _phoneCtrl.dispose();
    _occupantsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        widget.house.representativeName = _repNameCtrl.text.trim();
        widget.house.contactPhone = _phoneCtrl.text.trim();
        widget.house.totalOccupants = int.tryParse(_occupantsCtrl.text.trim()) ?? 1;
        widget.house.medicalNotes = _notesCtrl.text.trim();
        widget.house.primaryAccess = _access;
        widget.house.hasVulnerablePersons = _hasVulnerable;
      });

      // Notificar cambios al plano y consola
      AppState.instance.housesNotifier.value = List.from(AppState.instance.housesNotifier.value);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catastro de vivienda actualizado con éxito.'), backgroundColor: Color(0xFF2E7D32)),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Editar ${widget.house.number}'), backgroundColor: const Color(0xFF141720)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _repNameCtrl,
              decoration: const InputDecoration(labelText: 'Nombre Representante del Hogar *', filled: true, fillColor: Color(0xFF141720)),
              validator: (v) => v == null || v.trim().isEmpty ? 'Ingrese nombre' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Teléfono de Contacto Principal *', filled: true, fillColor: Color(0xFF141720)),
              validator: (v) => v == null || v.trim().length < 8 ? 'Ingrese teléfono válido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _occupantsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Total Ocupantes Habituales *', filled: true, fillColor: Color(0xFF141720)),
              validator: (v) => v == null || v.trim().isEmpty ? 'Indique residentes' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _access,
              dropdownColor: const Color(0xFF1E212D),
              decoration: const InputDecoration(labelText: 'Acceso y Vía de Evacuación Principal', filled: true, fillColor: Color(0xFF141720)),
              items: const [
                DropdownMenuItem(value: 'San Ignacio 1659', child: Text('San Ignacio 1659')),
                DropdownMenuItem(value: 'Av. Viel 1660', child: Text('Av. Viel 1660')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _access = val);
              },
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('¿Habita persona en situación de vulnerabilidad?'),
              subtitle: const Text('Movilidad reducida, adulto mayor o electrodependiente (GRD_XX_REG_10)', style: TextStyle(fontSize: 12, color: Colors.white54)),
              value: _hasVulnerable,
              activeColor: const Color(0xFF00E676),
              onChanged: (val) => setState(() => _hasVulnerable = val),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Observaciones Médicas / Rescate Prioritario', filled: true, fillColor: Color(0xFF141720)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black87, padding: const EdgeInsets.symmetric(vertical: 14)),
              icon: const Icon(Icons.save),
              label: const Text('GUARDAR FICHA DE CATASTRO', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// MÓDULO 4: CONSOLA CGRD Y ACTAS DE CIERRE
// ==========================================

class CGRDLiveCommandScreen extends StatelessWidget {
  const CGRDLiveCommandScreen({Key? key}) : super(key: key);

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _showCloseIncidentModal(BuildContext context, ActiveEmergencyEvent alert) {
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
                  const SizedBox(width: 8),
                  Text('Acta de Cierre: ${alert.houseNumber}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 480,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('¿Es Simulacro Programado? (GRD_XX_REG_13/14)', style: TextStyle(fontSize: 13)),
                        value: isDrill,
                        activeColor: const Color(0xFF00E676),
                        onChanged: (v) => setModalState(() => isDrill = v),
                      ),
                      const SizedBox(height: 8),
                      TextField(controller: summaryCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Evaluación y Resumen de la Respuesta (ACCEDER)', filled: true, fillColor: Color(0xFF141720))),
                      const SizedBox(height: 8),
                      TextField(controller: damagesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Daños a personas o infraestructura', filled: true, fillColor: Color(0xFF141720))),
                      const SizedBox(height: 8),
                      TextField(controller: actionsCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Organismos que concurrieron (132, 131, 133)', filled: true, fillColor: Color(0xFF141720))),
                      const SizedBox(height: 8),
                      TextField(controller: lessonsCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Lecciones aprendidas y Readecuación (Fase R)', filled: true, fillColor: Color(0xFF141720))),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR', style: TextStyle(color: Colors.white54))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                  child: const Text('ARCHIVAR ACTA Y DESPEJAR ALERTA'),
                  onPressed: () {
                    final rec = BitacoraRecord(
                      id: 'BIT_${DateTime.now().millisecondsSinceEpoch}',
                      houseNumber: alert.houseNumber,
                      threatName: alert.threatType.label,
                      isDrill: isDrill,
                      summary: summaryCtrl.text.trim(),
                      damages: damagesCtrl.text.trim(),
                      responders: actionsCtrl.text.trim(),
                      lessons: lessonsCtrl.text.trim(),
                      date: DateTime.now(),
                    );

                    AppState.instance.bitacoraNotifier.value = [rec, ...AppState.instance.bitacoraNotifier.value];
                    AppState.instance.activeAlertNotifier.value = null;

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Acta formal de cierre guardada en Bitácora CGRD.'), backgroundColor: Color(0xFF2E7D32)),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comité CGRD - Mando y Bitácora (Ley N° 21.364)'),
        backgroundColor: const Color(0xFF141720),
      ),
      body: ValueListenableBuilder<ActiveEmergencyEvent?>(
        valueListenable: AppState.instance.activeAlertNotifier,
        builder: (context, activeAlert, _) {
          return ValueListenableBuilder<List<BitacoraRecord>>(
            valueListenable: AppState.instance.bitacoraNotifier,
            builder: (context, bitacora, _) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('1. ESTADO DE EMERGENCIA ACTIVA EN LA VILLA', style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  if (activeAlert == null)
                    Card(
                      color: const Color(0xFF1A1D27),
                      child: const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline, color: Color(0xFF00E676), size: 36),
                            SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Comunidad en Normalidad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text('No se registran llamadas ni alertas activas.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Card(
                      color: const Color(0xFF26151B),
                      shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.redAccent, width: 1.5), borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('ALERTA EN CURSO: ${activeAlert.threatType.label.toUpperCase()}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                                  child: const Text('EN VIVO', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Ubicación: ${activeAlert.houseNumber} (${activeAlert.primaryAccess})', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Representante: ${activeAlert.repName} | Fono: ${activeAlert.repPhone}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            Text('Carga Ocupacional: ${activeAlert.totalOccupants} residentes', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                            if (activeAlert.hasVulnerabilities)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                                child: const Text('PRIORIDAD GRD_XX_REG_10: Ocupantes con necesidades especiales en la vivienda', style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            const Divider(color: Colors.white12, height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF00E676), side: const BorderSide(color: Color(0xFF00E676))),
                                  icon: const Icon(Icons.phone),
                                  label: const Text('LLAMAR CONTACTO'),
                                  onPressed: () => _call(activeAlert.repPhone),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                                  icon: const Icon(Icons.fact_check),
                                  label: const Text('CERRAR ACTA / BITÁCORA'),
                                  onPressed: () => _showCloseIncidentModal(context, activeAlert),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  const Text('2. HISTORIAL DE BITÁCORAS Y ACTAS ARCHIVADAS (GRD_XX_REG_04)', style: TextStyle(color: Colors.lightBlueAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  if (bitacora.isEmpty)
                    Card(
                      color: const Color(0xFF1A1D27),
                      child: const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text('Aún no se registran cierres de incidentes o simulacros en la bitácora.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ),
                    )
                  else
                    ...bitacora.map((b) {
                      return Card(
                        color: const Color(0xFF1A1D27),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${b.threatName} - ${b.houseNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: b.isDrill ? Colors.blue.withOpacity(0.2) : Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                                    child: Text(b.isDrill ? 'SIMULACRO' : 'REAL', style: TextStyle(color: b.isDrill ? Colors.blueAccent : const Color(0xFF00E676), fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('Evaluación: ${b.summary}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              Text('Lecciones aprendidas (Fase R): ${b.lessons}', style: const TextStyle(color: Colors.amberAccent, fontSize: 11)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
