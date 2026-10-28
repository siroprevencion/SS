import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Tipos de amenazas según metodología ACCEDER y Marco SENAPRED
enum ThreatType {
  fuegoIncendio,
  postSismo,
  salud,
  robo,
}

/// Extensión para obtener colores, etiquetas y números de auxilio oficiales
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
        return '4. Emerg. Robo / Seguridad';
    }
  }

  Color get color {
    switch (this) {
      case ThreatType.fuegoIncendio:
        return const Color(0xFFD32F2F); // Rojo fuego
      case ThreatType.postSismo:
        return const Color(0xFFF57C00); // Naranja sismo
      case ThreatType.salud:
        return const Color(0xFF1976D2); // Azul médico SAMU
      case ThreatType.robo:
        return const Color(0xFF7B1FA2); // Morado seguridad
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
        return '132'; // Bomberos
      case ThreatType.postSismo:
        return '+56227082983'; // Seguridad Interna / Comunal
      case ThreatType.salud:
        return '131'; // SAMU
      case ThreatType.robo:
        return '133'; // Carabineros
    }
  }
}

/// Modelo de vivienda dentro del plano vectorial de la Villa Elena Barros
class HouseNode {
  final String id;
  final String number;
  final Rect boundary;
  final String primaryAccess;
  final bool hasVulnerablePersons;
  final String representativeName;
  final String contactPhone;

  HouseNode({
    required this.id,
    required this.number,
    required this.boundary,
    required this.primaryAccess,
    this.hasVulnerablePersons = false,
    this.representativeName = '',
    this.contactPhone = '',
  });
}

class VillaVectorMapScreen extends StatefulWidget {
  const VillaVectorMapScreen({Key? key}) : super(key: key);

  @override
  State<VillaVectorMapScreen> createState() => _VillaVectorMapScreenState();
}

class _VillaVectorMapScreenState extends State<VillaVectorMapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  // Estado reactivo de alerta
  String? _activeHouseId;
  ThreatType? _activeThreat;
  HouseNode? _selectedHouseDetails;

  // Catálogo de casas mapeadas según plano: San Ignacio 1659 (izq) y Av. Viel 1660 (der)
  final List<HouseNode> _houses = [
    // Manzana Norte (Casas 01 a 04)
    HouseNode(
      id: 'H1',
      number: 'Casa 01',
      boundary: const Rect.fromLTWH(70, 150, 75, 95),
      primaryAccess: 'San Ignacio 1659',
      representativeName: 'Elena Soto',
      contactPhone: '+56 9 8811 2233',
    ),
    HouseNode(
      id: 'H2',
      number: 'Casa 02',
      boundary: const Rect.fromLTWH(170, 150, 75, 95),
      primaryAccess: 'San Ignacio 1659',
      representativeName: 'Carlos Fuentes',
      contactPhone: '+56 9 7722 3344',
    ),
    HouseNode(
      id: 'H3',
      number: 'Casa 03',
      boundary: const Rect.fromLTWH(270, 150, 75, 95),
      primaryAccess: 'San Ignacio 1659',
      hasVulnerablePersons: true,
      representativeName: 'Matías Martínez',
      contactPhone: '+56 9 1234 5678',
    ),
    HouseNode(
      id: 'H4',
      number: 'Casa 04',
      boundary: const Rect.fromLTWH(370, 150, 75, 95),
      primaryAccess: 'Av. Viel 1660',
      representativeName: 'Ana Morales',
      contactPhone: '+56 9 6655 4433',
    ),

    // Manzana Sur (Casas 05 a 08)
    HouseNode(
      id: 'H5',
      number: 'Casa 05',
      boundary: const Rect.fromLTWH(70, 370, 75, 95),
      primaryAccess: 'San Ignacio 1659',
      representativeName: 'Pedro Valdivia',
      contactPhone: '+56 9 5544 3322',
    ),
    HouseNode(
      id: 'H6',
      number: 'Casa 06',
      boundary: const Rect.fromLTWH(170, 370, 75, 95),
      primaryAccess: 'San Ignacio 1659',
      representativeName: 'Rosa Araya',
      contactPhone: '+56 9 4433 2211',
    ),
    HouseNode(
      id: 'H7',
      number: 'Casa 07',
      boundary: const Rect.fromLTWH(270, 370, 75, 95),
      primaryAccess: 'Av. Viel 1660',
      hasVulnerablePersons: true,
      representativeName: 'Jorge Farías',
      contactPhone: '+56 9 3322 1100',
    ),
    HouseNode(
      id: 'H8',
      number: 'Casa 08',
      boundary: const Rect.fromLTWH(370, 370, 75, 95),
      primaryAccess: 'Av. Viel 1660',
      representativeName: 'Lucía Núñez',
      contactPhone: '+56 9 2211 0099',
    ),
  ];

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

  void _triggerEmergency(ThreatType threat, HouseNode house) {
    setState(() {
      _activeThreat = threat;
      _activeHouseId = house.id;
      _selectedHouseDetails = house;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: threat.color,
        duration: const Duration(seconds: 4),
        content: Text(
          'ALERTA EMITIDA: ${threat.label} en ${house.number} (${house.primaryAccess})',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _clearEmergency() {
    setState(() {
      _activeHouseId = null;
      _activeThreat = null;
      _selectedHouseDetails = null;
    });
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _onCanvasTap(Offset localPosition) {
    for (final house in _houses) {
      if (house.boundary.contains(localPosition)) {
        setState(() {
          _selectedHouseDetails = house;
        });
        _showHouseModal(house);
        return;
      }
    }
  }

  void _showHouseModal(HouseNode house) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E212D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                  Text(
                    house.number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (house.hasVulnerablePersons)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        border: Border.all(color: Colors.amber),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.accessible, color: Colors.amber, size: 16),
                          SizedBox(width: 4),
                          Text('Vulnerable', style: TextStyle(color: Colors.amber, fontSize: 12)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Acceso de Evacuación: ${house.primaryAccess}', style: const TextStyle(color: Colors.white70)),
              Text('Representante: ${house.representativeName}', style: const TextStyle(color: Colors.white70)),
              Text('Contacto: ${house.contactPhone}', style: const TextStyle(color: Colors.white70)),
              const Divider(color: Colors.white24, height: 24),
              const Text('DISPARAR ALERTA EN ESTE DOMICILIO:', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ThreatType.values.map((threat) {
                  return ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: threat.color,
                      foregroundColor: Colors.white,
                    ),
                    icon: Icon(threat.icon, size: 18),
                    label: Text(threat.label),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _triggerEmergency(threat, house);
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
    return Scaffold(
      backgroundColor: const Color(0xFF111319),
      appBar: AppBar(
        title: const Text('Plano Interactivo Villa Elena Barros', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF191D28),
        actions: [
          IconButton(
            tooltip: 'Llamada rápida Bomberos (132)',
            icon: const Icon(Icons.fire_truck, color: Colors.redAccent),
            onPressed: () => _makeCall('132'),
          ),
          IconButton(
            tooltip: 'Llamada rápida Carabineros (133)',
            icon: const Icon(Icons.local_police, color: Colors.purpleAccent),
            onPressed: () => _makeCall('133'),
          ),
          IconButton(
            tooltip: 'Llamada rápida SAMU (131)',
            icon: const Icon(Icons.medical_services, color: Colors.blueAccent),
            onPressed: () => _makeCall('131'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner de alerta comunitaria activa
          if (_activeHouseId != null && _activeThreat != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: _activeThreat!.color,
              child: Row(
                children: [
                  Icon(_activeThreat!.icon, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EMERGENCIA ACTIVA: ${_activeThreat!.label.toUpperCase()}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          'Ubicación: ${_selectedHouseDetails?.number} | ${_selectedHouseDetails?.primaryAccess}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onPressed: () => _makeCall(_activeThreat!.defaultEmergencyNumber),
                    child: Text('LLAMAR ${_activeThreat!.defaultEmergencyNumber}'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _clearEmergency,
                  ),
                ],
              ),
            ),

          // Canvas Vectorial Interactivo
          Expanded(
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.6,
              maxScale: 3.0,
              child: Center(
                child: GestureDetector(
                  onTapUp: (details) => _onCanvasTap(details.localPosition),
                  child: SizedBox(
                    width: 520,
                    height: 580,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: VillaEvacuationPainter(
                            houses: _houses,
                            activeHouseId: _activeHouseId,
                            pulseValue: _pulseController.value,
                            threatColor: _activeThreat?.color ?? Colors.red,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Barra informativa inferior
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF191D28),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.touch_app_outlined, color: Color(0xFF00E676), size: 18),
                    SizedBox(width: 8),
                    Text('Toca cualquier casa para ver ficha o disparar alerta', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                Text('Ley N° 21.364 / SENAPRED', style: TextStyle(color: Colors.white30, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pintor vectorial en Canvas que reproduce el plano de la Villa Elena Barros
class VillaEvacuationPainter extends CustomPainter {
  final List<HouseNode> houses;
  final String? activeHouseId;
  final double pulseValue;
  final Color threatColor;

  VillaEvacuationPainter({
    required this.houses,
    required this.activeHouseId,
    required this.pulseValue,
    required this.threatColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Fondo perimetral del loteo
    final bgPaint = Paint()..color = const Color(0xFF222634);
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)), bgPaint);

    // 2. Límites de accesos viales (San Ignacio 1659 / Av. Viel 1660)
    final streetPaint = Paint()..color = const Color(0xFF161924);
    // San Ignacio (Oeste / Izquierda)
    canvas.drawRect(Rect.fromLTWH(0, 0, 45, size.height), streetPaint);
    // Av. Viel (Este / Derecha)
    canvas.drawRect(Rect.fromLTWH(size.width - 45, 0, 45, size.height), streetPaint);

    // Texto de Calles
    _drawVerticalText(canvas, 'SAN IGNACIO 1659', const Offset(15, 200), const Color(0xFF00E676));
    _drawVerticalText(canvas, 'AV. VIEL 1660', Offset(size.width - 28, 220), const Color(0xFF00E676));

    // 3. Pasaje central / Vía de Evacuación
    final roadPaint = Paint()..color = const Color(0xFF2D3244);
    canvas.drawRect(Rect.fromLTWH(45, 270, size.width - 90, 70), roadPaint);

    // Línea discontinua central de evacuación
    final dashPaint = Paint()
      ..color = const Color(0xFF00E676).withOpacity(0.5)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(55, 305), Offset(size.width - 55, 305), dashPaint);

    // 4. Recursos Críticos (Red Seca, Extintores PQS, P.R.I. y P.E.E.)
    _drawSafetyResources(canvas, size);

    // 5. Renderizado interactivo de cada vivienda
    for (final house in houses) {
      final isEmergency = house.id == activeHouseId;

      final housePaint = Paint()
        ..color = isEmergency ? threatColor : const Color(0xFF383E54)
        ..style = PaintingStyle.fill;

      // Dibujar vivienda
      canvas.drawRRect(RRect.fromRectAndRadius(house.boundary, const Radius.circular(8)), housePaint);

      final borderPaint = Paint()
        ..color = isEmergency ? Colors.white : const Color(0xFF535C7A)
        ..strokeWidth = isEmergency ? 2.5 : 1.2
        ..style = PaintingStyle.stroke;
      canvas.drawRRect(RRect.fromRectAndRadius(house.boundary, const Radius.circular(8)), borderPaint);

      // Efecto Onda / Ripple en la casa siniestrada
      if (isEmergency) {
        final ripplePaint = Paint()
          ..color = threatColor.withOpacity(1.0 - pulseValue)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 + (pulseValue * 10);
        canvas.drawRRect(
          RRect.fromRectAndRadius(house.boundary.inflate(pulseValue * 10), const Radius.circular(12)),
          ripplePaint,
        );
      }

      // Etiqueta del número de casa
      _drawText(
        canvas,
        house.number,
        Offset(house.boundary.center.dx, house.boundary.center.dy - 6),
        isEmergency ? Colors.white : Colors.white70,
        12,
        FontWeight.bold,
      );

      // Indicador de vulnerabilidad
      if (house.hasVulnerablePersons && !isEmergency) {
        final badgePaint = Paint()..color = Colors.amber;
        canvas.drawCircle(Offset(house.boundary.right - 12, house.boundary.top + 12), 4, badgePaint);
      }
    }
  }

  void _drawSafetyResources(Canvas canvas, Size size) {
    // Punto de Reunión Interior (P.R.I.) en el centro del pasaje
    final priPaint = Paint()..color = const Color(0xFF2E7D32);
    canvas.drawCircle(const Offset(260, 305), 18, priPaint);
    _drawText(canvas, 'P.R.I.', const Offset(260, 305), Colors.white, 9, FontWeight.bold);

    // Punto de Encuentro Exterior (P.E.E. - Av. Viel)
    final peePaint = Paint()..color = const Color(0xFF1B5E20);
    canvas.drawCircle(Offset(size.width - 25, 120), 16, peePaint);
    _drawText(canvas, 'P.E.E.', Offset(size.width - 25, 120), Colors.white, 8, FontWeight.bold);

    // Entrada Red Seca (San Ignacio)
    final redSecaPaint = Paint()..color = const Color(0xFFD32F2F);
    canvas.drawRect(const Rect.fromLTWH(50, 90, 16, 16), redSecaPaint);
    _drawText(canvas, 'R.S.', const Offset(58, 98), Colors.white, 7, FontWeight.bold);

    // Salida Red Seca (Av. Viel)
    canvas.drawRect(Rect.fromLTWH(size.width - 66, 90, 16, 16), redSecaPaint);
    _drawText(canvas, 'R.S.', Offset(size.width - 58, 98), Colors.white, 7, FontWeight.bold);

    // Extintores PQS
    final pqsPaint = Paint()..color = const Color(0xFFFF5252);
    canvas.drawCircle(const Offset(150, 260), 6, pqsPaint);
    _drawText(canvas, 'PQS', const Offset(150, 250), Colors.white, 7, FontWeight.w600);

    canvas.drawCircle(const Offset(350, 260), 6, pqsPaint);
    _drawText(canvas, 'PQS', const Offset(350, 250), Colors.white, 7, FontWeight.w600);
  }

  void _drawText(Canvas canvas, String text, Offset center, Color color, double fontSize, FontWeight weight) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: weight),
      ),
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
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant VillaEvacuationPainter oldDelegate) => true;
}
