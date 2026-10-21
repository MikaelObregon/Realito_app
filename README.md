# 💸 Realito — Control de Finanzas Personales (Argentina)

**Realito** es una aplicación de finanzas personales diseñada específicamente para el uso diario en Argentina. Permite controlar en segundos tu **Saldo Disponible Real en Pesos (`ARS`) y Dólares (`USD`)**, cuánto podés gastar por día hasta tu próximo cobro, tus **Gastos Fijos mensuales**, tus **Billeteras (`Personal Pay`, `Banco`, `Efectivo`)** y tus **Movimientos Diarios**, con sincronización automática en tiempo real en **Supabase** (con tablas 100% en español).

---

## ✨ Características Principales

- **📊 Disponible Real y Margen Diario Automático:**
  - Calcula al instante `Ingresos - Gastos Fijos - Gastos Diarios` y lo divide por los días que faltan hasta tu próximo cobro (`💡 Podés gastar $ X / día`).
- **💵 Dólar Oficial (Precio de Venta — Banco Nación):**
  - Referencia integrada con la cotización de venta del **Banco de la Nación Argentina** y botón para alternar toda la app entre `Pesos (ARS)` y `Dólares (USD)`.
- **🧮 Carga Rápida con Calculadora (`+`) y Selector de Día Compacto:**
  - Teclado numérico propio con tecla `+` para sumar varios ítems en un mismo gasto (ej. `12000+4500`) y selector rápido de fecha (`Hoy`, `Ayer` o grilla táctil de los días `1` al `31` del mes).
- **☑️ Checklist de Gastos Fijos y Mes Adelantado:**
  - Seguimiento de vencimientos, pagos parciales o totales en 1 toque y botón para clonar gastos fijos al mes siguiente (`Noviembre ⏭️`).
- **🏦 Mis Cuentas y Transferencias Propias:**
  - Saldos en vivo por billetera, ajuste rápido de saldo real y transferencias entre cuentas propias sin alterar los gastos ni ingresos del mes.
- **📑 Reporte Mensual Ejecutivo y Descarga / Compartido PDF:**
  - Resumen con gráficos de distribución de ingresos y gastos por rubro. Genera una **Hoja A4 en PDF** que en el celular abre automáticamente la bandeja nativa para compartir por WhatsApp o guardar en el dispositivo.
- **☁️ Sincronización Automática en Supabase (100% en Español):**
  - Sincroniza silenciosamente en segundo plano contra 7 tablas PostgreSQL en español (`cuentas`, `categorias`, `gastos_fijos`, `movimientos`, `transferencias_cuentas`, `configuracion_usuario`, `estado_sincronizado`).
- **🎨 Dos Temas Visuales:**
  - Modo oscuro **Obsidiana** (`#0F172A`) y modo claro cálido **Salvia & Marfil** (`#F5F2EB`).

---

## 📂 Estructura del Proyecto

```text
Realito_app/
├── web/                                       # App Web / PWA lista para usar e instalar en el celular
│   ├── index.html                             # Aplicación completa conectada a Supabase
│   └── manifest.json                          # Manifiesto de instalación móvil (PWA)
├── supabase/
│   └── migrations/
│       └── 0001_initial_schema.sql            # Esquema SQL con las 7 tablas en español
├── lib/                                       # Arquitectura modular en Flutter / Dart
│   ├── core/                                  # Base de datos local, formateadores, red, sync y temas
│   └── features/                              # Módulos: dashboard, planning, accounts, transactions
├── test/                                      # Suite de 39 pruebas (Unitarias + E2E + Supabase en vivo)
│   ├── run_all_tests.js                       # Runner automatizado de regresión (39/39 tests)
│   ├── verify_supabase_live.js                # Verificador de conexión y tablas en Supabase
│   ├── reporte_pruebas_e2e.html               # Reporte visual HTML de la suite de pruebas
│   ├── resultados_regresion.json              # Resultados en formato JSON
│   ├── unit/                                  # Pruebas unitarias en Dart
│   └── e2e/                                   # Pruebas punta a punta en Dart
└── docs/                                      # Documentación completa del proyecto
    ├── 01_estructura_del_proyecto.md          # Detalle carpeta por carpeta y archivo por archivo
    ├── 02_base_de_datos_supabase_espanol.md   # Documentación de las 7 tablas en español en Supabase
    ├── 03_flujos_funcionales_y_ux.md          # Fórmulas financieras, pantallas, modales y PDF
    └── 04_pruebas_unitarias_y_regresion_e2e.md# Guía de pruebas unitarias, E2E y regresión
```

---

## 🗄️ Tablas en Base de Datos (Supabase — Español)

El esquema SQL ([`supabase/migrations/0001_initial_schema.sql`](supabase/migrations/0001_initial_schema.sql)) crea y mantiene sincronizadas las siguientes **7 tablas**:

1. **`cuentas`** (`id`, `nombre`, `icono`, `saldo`, `actualizado_en`)
2. **`categorias`** (`id`, `tipo`, `nombre`, `icono`, `color`, `actualizado_en`)
3. **`gastos_fijos`** (`id`, `mes_anio`, `titulo`, `categoria_id`, `monto_total`, `monto_pagado`, `dia_vencimiento`, `esta_pagado`, `nota`, `actualizado_en`)
4. **`movimientos`** (`id`, `mes_anio`, `etiqueta_dia`, `tipo`, `categoria_id`, `cuenta_id`, `monto`, `nota`, `actualizado_en`)
5. **`transferencias_cuentas`** (`id`, `cuenta_origen_id`, `cuenta_destino_id`, `monto`, `nota`, `etiqueta_fecha`, `actualizado_en`)
6. **`configuracion_usuario`** (`id`, `cotizacion_dolar_oficial`, `fuente_dolar`, `fecha_proximo_cobro`, `moneda_visualizacion`, `tema_visual`, `meses_sobrante_transferido`, `actualizado_en`)
7. **`estado_sincronizado`** (`clave_espacio`, `datos_json`, `actualizado_en`)

---

## 🧪 Ejecución de Pruebas (Unitarias + E2E)

Para ejecutar las **39 pruebas automatizadas** (8 suites) y actualizar el reporte HTML en [`test/reporte_pruebas_e2e.html`](test/reporte_pruebas_e2e.html):

```powershell
node test/run_all_tests.js
```

Para validar la conexión y sincronización en vivo con **Supabase**:

```powershell
node test/verify_supabase_live.js
```

---

## 📖 Documentación Detallada

- 📘 [**01. Estructura del Proyecto**](docs/01_estructura_del_proyecto.md)
- 🗄️ [**02. Base de Datos en Supabase (Español)**](docs/02_base_de_datos_supabase_espanol.md)
- 📱 [**03. Flujos Funcionales y Diseño UX**](docs/03_flujos_funcionales_y_ux.md)
- 🧪 [**04. Pruebas Unitarias y Regresión E2E**](docs/04_pruebas_unitarias_y_regresion_e2e.md)

