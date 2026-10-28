import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Modelo de datos para el Catastro Comunitario y Censo Vecinal
/// Alineado con el registro preventivo GRD_XX_REG_10 y Ley N° 21.364.
class HouseCensusData {
  String houseNumber;
  String streetAccess;
  int totalOccupants;
  String repFullName;
  String repPhone;
  String? secFullName;
  String? secPhone;
  bool hasReducedMobility;
  bool isSeniorCitizen;
  bool isElectrodependent;
  String medicalNotes;
  bool isFormCompleted;

  HouseCensusData({
    this.houseNumber = '',
    this.streetAccess = 'San Ignacio 1659',
    this.totalOccupants = 1,
    this.repFullName = '',
    this.repPhone = '',
    this.secFullName,
    this.secPhone,
    this.hasReducedMobility = false,
    this.isSeniorCitizen = false,
    this.isElectrodependent = false,
    this.medicalNotes = '',
    this.isFormCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'houseNumber': houseNumber,
      'streetAccess': streetAccess,
      'totalOccupants': totalOccupants,
      'representative': {
        'fullName': repFullName,
        'phone': repPhone,
      },
      'secondaryContact': {
        'fullName': secFullName ?? '',
        'phone': secPhone ?? '',
      },
      'vulnerability': {
        'hasReducedMobility': hasReducedMobility,
        'isSeniorCitizen': isSeniorCitizen,
        'isElectrodependent': isElectrodependent,
        'medicalNotes': medicalNotes,
      },
      'isFormCompleted': isFormCompleted,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }
}

class HouseRegistrationScreen extends StatefulWidget {
  final HouseCensusData? initialData;
  final Function(HouseCensusData) onSave;

  const HouseRegistrationScreen({
    Key? key,
    this.initialData,
    required this.onSave,
  }) : super(key: key);

  @override
  State<HouseRegistrationScreen> createState() => _HouseRegistrationScreenState();
}

class _HouseRegistrationScreenState extends State<HouseRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto
  late TextEditingController _houseNumberCtrl;
  late TextEditingController _totalOccupantsCtrl;
  late TextEditingController _repNameCtrl;
  late TextEditingController _repPhoneCtrl;
  late TextEditingController _secNameCtrl;
  late TextEditingController _secPhoneCtrl;
  late TextEditingController _medicalNotesCtrl;

  // Variables de estado
  String _selectedAccess = 'San Ignacio 1659';
  bool _hasReducedMobility = false;
  bool _isSeniorCitizen = false;
  bool _isElectrodependent = false;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData ?? HouseCensusData();
    _houseNumberCtrl = TextEditingController(text: data.houseNumber);
    _totalOccupantsCtrl = TextEditingController(text: data.totalOccupants.toString());
    _repNameCtrl = TextEditingController(text: data.repFullName);
    _repPhoneCtrl = TextEditingController(text: data.repPhone);
    _secNameCtrl = TextEditingController(text: data.secFullName ?? '');
    _secPhoneCtrl = TextEditingController(text: data.secPhone ?? '');
    _medicalNotesCtrl = TextEditingController(text: data.medicalNotes);

    _selectedAccess = data.streetAccess.isNotEmpty ? data.streetAccess : 'San Ignacio 1659';
    _hasReducedMobility = data.hasReducedMobility;
    _isSeniorCitizen = data.isSeniorCitizen;
    _isElectrodependent = data.isElectrodependent;
  }

  @override
  void dispose() {
    _houseNumberCtrl.dispose();
    _totalOccupantsCtrl.dispose();
    _repNameCtrl.dispose();
    _repPhoneCtrl.dispose();
    _secNameCtrl.dispose();
    _secPhoneCtrl.dispose();
    _medicalNotesCtrl.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final savedData = HouseCensusData(
        houseNumber: _houseNumberCtrl.text.trim(),
        streetAccess: _selectedAccess,
        totalOccupants: int.tryParse(_totalOccupantsCtrl.text.trim()) ?? 1,
        repFullName: _repNameCtrl.text.trim(),
        repPhone: _repPhoneCtrl.text.trim(),
        secFullName: _secNameCtrl.text.trim().isNotEmpty ? _secNameCtrl.text.trim() : null,
        secPhone: _secPhoneCtrl.text.trim().isNotEmpty ? _secPhoneCtrl.text.trim() : null,
        hasReducedMobility: _hasReducedMobility,
        isSeniorCitizen: _isSeniorCitizen,
        isElectrodependent: _isElectrodependent,
        medicalNotes: _medicalNotesCtrl.text.trim(),
        isFormCompleted: true,
      );

      widget.onSave(savedData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ficha de Domicilio guardada correctamente en el Catastro Comunitario'),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF12141A);
    const cardColor = Color(0xFF1D212C);
    const accentColor = Color(0xFF00E676);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'Catastro Comunitario SS',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF161922),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          children: [
            // Banner explicativo GRD
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF263238),
                borderRadius: BorderRadius.circular(10),
                border: Border.left(borderSide: const BorderSide(color: accentColor, width: 4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: accentColor, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Registro preventivo de carga ocupacional y vulnerabilidad para el despacho oportuno de emergencias.',
                      style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // SECCIÓN 1: Identificación del Domicilio
            _buildSectionHeader('1. Individualización del Domicilio', Icons.home_work_outlined),
            Card(
              color: cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _houseNumberCtrl,
                      keyboardType: TextInputType.text,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        label: 'Número de Casa / Dpto *',
                        hint: 'Ej: Casa 03',
                        icon: Icons.tag,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingrese el número o identificador de la casa';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedAccess,
                      dropdownColor: const Color(0xFF222634),
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        label: 'Vía de Salida y Acceso Primario',
                        icon: Icons.alt_route,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'San Ignacio 1659',
                          child: Text('San Ignacio de Loyola 1659'),
                        ),
                        DropdownMenuItem(
                          value: 'Av. Viel 1660',
                          child: Text('Av. Viel 1660'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedAccess = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _totalOccupantsCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        label: 'Cantidad Total de Residentes Habituales *',
                        hint: 'Ej: 3',
                        icon: Icons.groups_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Indique el número de personas';
                        }
                        final num = int.tryParse(value);
                        if (num == null || num < 1) {
                          return 'Debe registrar al menos 1 residente';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // SECCIÓN 2: Contactos de Emergencia
            _buildSectionHeader('2. Representante y Contactos', Icons.person_pin_outlined),
            Card(
              color: cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _repNameCtrl,
                      keyboardType: TextInputType.name,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        label: 'Nombre Completo del Representante *',
                        hint: 'Ej: Matías Martínez',
                        icon: Icons.person_outline,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El representante del hogar es obligatorio';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _repPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        label: 'Teléfono Principal de Contacto *',
                        hint: 'Ej: +56 9 1234 5678',
                        icon: Icons.phone_android,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingrese un número telefónico';
                        }
                        if (value.trim().length < 8) {
                          return 'Ingrese un teléfono de contacto válido';
                        }
                        return null;
                      },
                    ),
                    const Divider(color: Colors.white24, height: 32),
                    TextFormField(
                      controller: _secNameCtrl,
                      keyboardType: TextInputType.name,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        label: 'Contacto Secundario (Opcional)',
                        hint: 'Nombre de familiar o vecino',
                        icon: Icons.contact_phone_outlined,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _secPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        label: 'Teléfono de Contacto Secundario',
                        hint: 'Ej: +56 9 8765 4321',
                        icon: Icons.phone_outlined,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // SECCIÓN 3: Catastro de Personas Vulnerables (GRD)
            _buildSectionHeader('3. Censo de Grupos de Atención Prioritaria', Icons.accessible_forward_outlined),
            Card(
              color: cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    SwitchListTile(
                      activeColor: accentColor,
                      title: const Text('Movilidad Reducida o Discapacidad Física',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Uso de bastón, silla de ruedas o prótesis para evacuación',
                          style: TextStyle(color: Colors.white60, fontSize: 12)),
                      value: _hasReducedMobility,
                      onChanged: (val) => setState(() => _hasReducedMobility = val),
                    ),
                    const Divider(color: Colors.white12),
                    SwitchListTile(
                      activeColor: accentColor,
                      title: const Text('Adulto Mayor en el Hogar',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Personas de 65 años o más que requieran asistencia de salida',
                          style: TextStyle(color: Colors.white60, fontSize: 12)),
                      value: _isSeniorCitizen,
                      onChanged: (val) => setState(() => _isSeniorCitizen = val),
                    ),
                    const Divider(color: Colors.white12),
                    SwitchListTile(
                      activeColor: const Color(0xFFFF5252),
                      title: const Text('Paciente Electrodependiente',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Dependencia crítica de energía para equipos médicos vitales',
                          style: TextStyle(color: Colors.white60, fontSize: 12)),
                      value: _isElectrodependent,
                      onChanged: (val) => setState(() => _isElectrodependent = val),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _medicalNotesCtrl,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        label: 'Observaciones Médicas / Rescate de Emergencia',
                        hint: 'Ej: Oxígeno domiciliario, habitación segundo piso',
                        icon: Icons.medical_information_outlined,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Botón de Confirmación y Guardado
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: const Color(0xFF0C1B10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: _submitForm,
                icon: const Icon(Icons.check_circle_outline, size: 22),
                label: const Text(
                  'GUARDAR REGISTRO DE VIVIENDA',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00E676), size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({required String label, String? hint, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.white60, size: 20),
      filled: true,
      fillColor: const Color(0xFF141720),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF2C3142), width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF00E676), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFFF5252), width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFFF5252), width: 1.5),
      ),
    );
  }
}
