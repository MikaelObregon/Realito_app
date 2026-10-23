# 01. Estructura Completa del Proyecto (`Realito_app`)

Este documento detalla la organización de carpetas y el propósito de cada archivo dentro del repositorio de **Realito**, actualizado con la arquitectura de **Modelo B ("Presupuesto Mensual Ágil y Disponible Libre")**.

---

## 1. Mapa General del Repositorio

```text
Realito_app/
├── README.md                                  # Documentación principal del repositorio para Git / GitHub
├── pubspec.yaml                               # Configuración de paquetes y dependencias Flutter/Dart
├── analysis_options.yaml                      # Reglas de linting y calidad de código Dart
├── .gitignore                                 # Archivos ignorados en control de versiones Git
│
├── web/                                       # Aplicación Web / PWA instalable en el teléfono y navegador
│   ├── index.html                             # App interactiva completa conectada en vivo a Supabase (Modelo B)
│   └── manifest.json                          # Manifiesto PWA para instalar en pantalla de inicio (Android/iOS)
│
├── supabase/                                  # Esquema y migraciones de Base de Datos en la nube
│   └── migrations/
│       └── 0001_initial_schema.sql            # Script SQL con las 7 tablas 100% en español + políticas RLS
│
├── lib/                                       # Código fuente modular en Flutter / Dart (Clean Architecture)
│   ├── main.dart                              # Punto de entrada de la aplicación Flutter
│   ├── app.dart                               # Configuración global de temas (Obsidiana/Marfil) y rutas
│   ├── core/                                  # Núcleo transversal de la aplicación
│   │   ├── database/
│   │   │   └── app_database.dart              # Definición de persistencia local SQLite (Drift)
│   │   ├── network/
│   │   │   └── exchange_rate_service.dart     # Servicio de consulta de Dólar Oficial (Venta — Banco Nación)
│   │   ├── router/
│   │   │   └── app_router.dart                # Enrutador declarativo de pantallas
│   │   ├── sync/
│   │   │   └── sync_engine.dart               # Motor de sincronización automática con cola Outbox
│   │   ├── theme/
│   │   │   ├── app_colors.dart                # Paleta cromática (Obsidiana Oscuro y Salvia/Marfil Claro)
│   │   │   └── app_theme.dart                 # Definición tipográfica y componentes Material 3
│   │   └── utils/
│   │       └── money_formatter.dart           # Formateador es-AR ($ 1.250.000), conversión USD y suma rápida (+)
│   └── features/                              # Módulos funcionales de negocio
│       ├── dashboard/                         # Pestaña 1: Inicio (Disponible Puro, Margen Diario, Buscador)
│       │   └── presentation/
│       │       ├── screens/
│       │       │   └── dashboard_screen.dart
│       │       └── widgets/
│       │           └── category_donut_chart.dart
│       ├── planning/                          # Pestaña 2: Checklist de Gastos Fijos Mensuales y Vencimientos
│       │   └── presentation/
│       │       └── screens/
│       │           └── planning_screen.dart
│       ├── reports/                           # Pestaña 3: 📊 Reportes & Estadísticas (Balance mensual y PDF)
│       │   └── presentation/
│       │       └── screens/
│       │           └── reports_screen.dart
│       ├── settings/                          # Pestaña 4: ⚙️ Ajustes (Temas, Categorías, Dólar, Backup)
│       │   └── presentation/
│       │       └── screens/
│       │           └── settings_screen.dart
│       └── transactions/                      # Carga rápida en 2 segundos (+), edición y filtros
│           ├── domain/
│           │   └── entities/
│           │       └── transaction_models.dart
│           └── presentation/
│               ├── controllers/
│               │   └── quick_transaction_controller.dart
│               └── screens/
│                   ├── quick_transaction_screen.dart
│                   └── transactions_history_screen.dart
│
├── test/                                      # Suite de Pruebas Unitarias, E2E y Regresión
│   ├── run_all_tests.js                       # Ejecutor automatizado de las 8 suites (42 casos de prueba)
│   ├── verify_supabase_live.js                # Script de verificación y sincronización en vivo con Supabase
│   ├── reporte_pruebas_e2e.html               # Reporte visual interactivo con el resultado de las 42 pruebas
│   ├── resultados_regresion.json              # Bitácora JSON de la última corrida de regresión
│   ├── unit/                                  # Tests unitarios en Dart
│   │   ├── money_formatter_test.dart          # Pruebas de formato ARS/USD y calculadora con '+'
│   │   ├── domain_calculators_test.dart       # Pruebas de Disponible Real, Margen Diario y Cierre de Mes
│   │   └── accounts_and_categories_test.dart  # Pruebas de cuentas y categorías
│   └── e2e/                                   # Tests punta a punta (End-to-End)
│       └── realito_full_flows_e2e_test.dart   # Simulación integral de todos los flujos de usuario
│
└── docs/                                      # Documentación Técnica y Funcional actualizada
    ├── 01_estructura_del_proyecto.md          # Este documento: detalle carpeta por carpeta
    ├── 02_base_de_datos_supabase_espanol.md   # Esquema de 7 tablas en español y sincronización automática
    ├── 03_flujos_funcionales_y_ux.md          # Pantallas, fórmulas financieras, modales y reporte PDF
    └── 04_pruebas_unitarias_y_regresion_e2e.md# Guía de ejecución de tests y regresión (42 casos)
```

---

## 2. Detalle de Cada Carpeta

### 📁 `web/`
Contiene la versión web interactiva y progresiva (**PWA**) lista para abrir o instalar directamente en el teléfono o en la computadora:
- **`web/index.html`**: Implementa la interfaz ágil de 4 accesos (`Inicio`, `Gastos Fijos`, `Reportes 📊`, `Ajustes ⚙️`), el botón central `＋ Cargar` de 2 segundos, el motor de persistencia local (`localStorage`), la conexión silenciosa con **Supabase**, sanitización anti-XSS (`escapeHtml`) y el exportador de **Reportes PDF**.
- **`web/manifest.json`**: Permite agregar la app a la pantalla de inicio del celular con ícono propio y pantalla completa (`standalone`) sin barras del navegador.

### 📁 `supabase/`
Contiene la infraestructura de base de datos relacional en PostgreSQL:
- **`supabase/migrations/0001_initial_schema.sql`**: Define las **7 tablas con nombres y columnas 100% en español**, sus claves primarias, restricciones (`CHECK`), triggers de fecha (`actualizado_en`) y políticas de acceso (`Row Level Security`).

### 📁 `lib/`
Contiene la arquitectura modular en **Flutter / Dart** dividida en dos grandes bloques:
- **`lib/core/`**: Servicios compartidos por toda la app (formateo de moneda argentina, cotización oficial Banco Nación, persistencia local y motor de sincronización).
- **`lib/features/`**: Pantallas organizadas por dominio funcional (`dashboard`, `planning`, `reports`, `settings`, `transactions`).

### 📁 `test/`
Aloja toda la infraestructura de calidad y regresión del proyecto:
- Permite validar en menos de 1 segundo los **42 casos de prueba** (unitarios y punta a punta con 100% de éxito), incluyendo consistencia matemática 1:1 y sanitización XSS.

### 📁 `docs/`
Reúne la documentación técnica viva del proyecto, alineada con las decisiones de diseño y las últimas mejoras de UX.
