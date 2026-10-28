# Sistema de Alerta Temprana Comunitaria "SS" - Villa Elena Barros
### Gestión del Riesgo de Desastres (GRD) | Ley N° 21.364 (SINAPRED - SENAPRED)

Plataforma móvil y web de alerta temprana y despacho vecinal ante emergencias críticas, diseñada bajo el marco regulatorio chileno de la **Ley N° 21.364**, la metodología de respuesta **ACCEDER** y el proceso de diagnóstico **AIDEP**.

---

## 📌 Características Principales

1. **Catastro Preventivo y Censo Comunitario (`GRD_XX_REG_10`):**
   - Registro de carga ocupacional por vivienda.
   - Identificación de grupos prioritarios: personas con movilidad reducida, adultos mayores y pacientes electrodependientes.
   - Datos de contacto y representante del hogar.

2. **Plano Vectorial Interactivo Canvas (Villa Elena Barros):**
   - Renderizado espacial de las viviendas y accesos viales (*San Ignacio 1659* y *Av. Viel 1660*).
   - Simbología oficial: Entrada/Salida de Red Seca, Gabinetes de Manguera, Extintores PQS, Punto de Reunión Interior (P.R.I.) y Punto de Encuentro Exterior (P.E.E.).
   - Animación de onda expansiva perimetral (*ripple effect*) en la vivienda siniestrada.

3. **Matriz de Activación (4 Amenazas Normadas):**
   - **1. Fuego / Incendio:** Enlace a Bomberos (132).
   - **2. Emergencia Post Sismo:** Enlace a Seguridad Comunal (+562 2708 2983).
   - **3. Emergencia Salud:** Enlace a SAMU (131).
   - **4. Emergencia Robo / Intrusión:** Enlace a Carabineros (133).

4. **Consola de Mando CGRD y Bitácora Digital (`GRD_XX_REG_04` / `REG_14`):**
   - Recepción reactiva de emergencias comunitarias.
   - Monitoreo de evacuación y asistencia a hogares vulnerables.
   - Levantamiento de actas post-incidente y registro formal de simulacros anuales.

5. **Alta Resiliencia y Operación Offline-First:**
   - Base de datos local persistente ante cortes de conectividad celular 4G/5G.
   - Notificaciones críticas de alta prioridad con anulación de modo silencio (Android Foreground & Apple Critical Alerts).
   - Fallback automático por SMS estructurado hacia el Líder CGRD.

---

## 🚀 Estructura del Repositorio

```text
├── lib/
│   ├── main.dart                      # Aplicación ejecutable integrada (Plano, Catastro y Mando CGRD)
│   ├── house_registration_screen.dart # Formulario de censo y validación de datos
│   ├── villa_vector_map_screen.dart   # Vista del plano interactivo y animación de amenazas
│   ├── cgrd_live_command_screen.dart  # Consola reactiva para el Coordinador CGRD y bitácora
│   └── emergency_sync_service.dart    # Capa de sincronización y fallback SMS
├── android/
│   └── app/src/main/AndroidManifest.xml # Permisos de llamadas, display wake lock y sirena
├── ios/
│   └── Runner/Info.plist              # Declaración de Critical Alerts y ubicación continua
├── functions/
│   └── index_cloud_function.ts        # Cloud Function para despacho FCM prioritario
├── docs/
│   └── especificacion_tecnica_sistema_ss.pdf # Memoria técnica formal y marco legal
└── README.md
```

---

## 🛠️ Requisitos e Instalación

1. Clonar el repositorio:
   ```bash
   git clone https://github.com/<tu-usuario>/ss-alerta-comunitaria.git
   cd ss-alerta-comunitaria
   ```
2. Instalar dependencias:
   ```bash
   flutter pub get
   flutter pub add url_launcher
   ```
3. Ejecutar en el navegador para visualización inmediata:
   ```bash
   flutter run -d chrome
   ```
