# 💸 Realito — Control de Finanzas Personales (Argentina)

**Realito** es una aplicación de finanzas personales diseñada específicamente para el uso diario en Argentina bajo el **Modelo B ("Presupuesto Mensual Ágil y Disponible Libre")**. Permite controlar en segundos tu **Saldo Disponible Real en Pesos (`ARS`) y Dólares (`USD`)**, cuánto podés gastar por día hasta tu próximo cobro, tus **Gastos Fijos mensuales**, tus **Movimientos Diarios** y tus **Reportes Estadísticos**, con sincronización automática en tiempo real en **Supabase** (con 7 tablas 100% en español).

---

## ✨ Características Principales

- **📊 Disponible Puro y Consistencia Matemática 1:1:**
  - El saldo principal refleja con exactitud la fórmula:
    $$\mathbf{Disponible} = \mathbf{Ingresos} - \mathbf{Gastos\ Fijos} - \mathbf{Gastos\ Diarios}$$
  - Coincidencia perfecta entre Inicio, el desglose diario y la pestaña de Reportes.
- **💡 Margen Diario Automático hasta el Próximo Cobro:**
  - Divide tu disponible libre por los días que faltan hasta tu próximo sueldo (`💡 Podés gastar $ X / día · Quedan N días`).
- **⚡ Carga Rápida en 2 Segundos (Botón `＋` Central):**
  - Carga inmediata sin fricción: **Monto + Categoría (+ nota opcional) y Guardar**.
  - Teclado numérico ergonómico con tecla `+` para acumular múltiples tickets en una sola entrada.
- **☑️ Checklist de Gastos Fijos y Mes Adelantado:**
  - Seguimiento de vencimientos, pagos parciales o totales en 1 toque y botón para clonar compromisos fijos al mes siguiente (`Noviembre`, `Diciembre`, etc.).
- **📊 Pestaña de Reportes & Estadísticas:**
  - Tarjetas de balance mensual, gráfico de destino del ingreso (% Fijos, % Diarios, % Libre), desglose al 100% de gastos fijos por categoría y barras de gastos diarios.
- **📄 Descarga y Compartido de Reporte Mensual en PDF:**
  - Genera el reporte del mes en formato PDF. En dispositivos móviles abre automáticamente el menú nativo para compartir por WhatsApp o guardar en el teléfono.
- **🎉 Traspaso Inteligente de Sobrante a Fin de Mes:**
  - Oculto durante el mes para no molestar. Se habilita únicamente el último día del mes (31/10) o el día 1 del nuevo mes si quedó dinero a favor.
  - Se registra automáticamente como un ingreso de `🎉 Sobrante a favor de [Mes Anterior]` en la categoría `inc-extra` y se auto-oculta de inmediato.
- **📅 Navegación y Generación Dinámica de Meses:**
  - Barra superior auto-centrada en el mes actual con etiquetas `Actual` y `Próximo`. A medida que avanza el calendario, los meses nuevos se crean solos hacia el futuro.
- **🛡️ Seguridad contra Inyección HTML (XSS):**
  - Función de sanitización [`escapeHtml()`](index.html) activa en todas las notas de gastos, títulos de servicios y categorías dinámicas.
- **💵 Cotización del Dólar Oficial (Venta — Banco Nación):**
  - Referencia integrada con el precio minorista oficial de venta y botón para alternar toda la app entre `Pesos (ARS)` y `Dólares (USD)`.
- **☁️ Sincronización Automática en Supabase (100% en Español):**
  - Sincronización silenciosa en segundo plano contra 7 tablas PostgreSQL en español (`movimientos`, `gastos_fijos`, `categorias`, `configuracion_usuario`, `estado_sincronizado`, `cuentas`, `transferencias_cuentas`).
- **🎨 Dos Temas Visuales:**
  - Modo oscuro **Obsidiana** (`#0F172A`) y modo claro cálido **Salvia & Marfil** (`#F5F2EB`).

---

## 📂 Estructura del Proyecto

```text
Realito_app/
├── web/                                       # App Web / PWA lista para usar e instalar en el celular
│   ├── index.html                             # Aplicación completa conectada a Supabase (Modelo B)
│   └── manifest.json                          # Manifiesto de instalación móvil (PWA)
├── supabase/
│   └── migrations/
│       └── 0001_initial_schema.sql            # Esquema SQL con las 7 tablas en español
├── lib/                                       # Arquitectura modular en Flutter / Dart
│   ├── core/                                  # Base de datos local, formateadores, red, sync y temas
│   └── features/                              # Módulos: dashboard, planning, reports, settings, transactions
├── test/                                      # Suite de 42 pruebas (Unitarias + E2E + Supabase en vivo)
│   ├── run_all_tests.js                       # Runner automatizado de regresión (42/42 tests — 100%)
│   ├── verify_supabase_live.js                # Verificador de conexión y tablas en Supabase
│   ├── reporte_pruebas_e2e.html               # Reporte visual HTML interactivo de las pruebas
│   ├── resultados_regresion.json              # Resultados en formato JSON
│   ├── unit/                                  # Pruebas unitarias en Dart
│   └── e2e/                                   # Pruebas punta a punta en Dart
└── docs/                                      # Documentación completa y actualizada del proyecto
    ├── 01_estructura_del_proyecto.md          # Detalle carpeta por carpeta y archivo por archivo
    ├── 02_base_de_datos_supabase_espanol.md   # Documentación de las 7 tablas en español en Supabase
    ├── 03_flujos_funcionales_y_ux.md          # Fórmulas financieras, pantallas, modales y PDF
    └── 04_pruebas_unitarias_y_regresion_e2e.md# Guía de pruebas unitarias, E2E y regresión (42 casos)
```

---

## 🗄️ Tablas en Base de Datos (Supabase — Español)

El esquema SQL ([`supabase/migrations/0001_initial_schema.sql`](supabase/migrations/0001_initial_schema.sql)) crea y mantiene sincronizadas las siguientes **7 tablas**:

1. **`movimientos`** (`id`, `mes_anio`, `etiqueta_dia`, `tipo`, `categoria_id`, `cuenta_id`, `monto`, `nota`, `actualizado_en`)
2. **`gastos_fijos`** (`id`, `mes_anio`, `titulo`, `categoria_id`, `monto_total`, `monto_pagado`, `dia_vencimiento`, `esta_pagado`, `nota`, `actualizado_en`)
3. **`categorias`** (`id`, `tipo`, `nombre`, `icono`, `color`, `actualizado_en`)
4. **`configuracion_usuario`** (`id`, `cotizacion_dolar_oficial`, `fuente_dolar`, `fecha_proximo_cobro`, `moneda_visualizacion`, `tema_visual`, `meses_sobrante_transferido`, `actualizado_en`)
5. **`estado_sincronizado`** (`clave_espacio`, `datos_json`, `actualizado_en`)
6. **`cuentas`** (`id`, `nombre`, `icono`, `saldo`, `actualizado_en`)
7. **`transferencias_cuentas`** (`id`, `cuenta_origen_id`, `cuenta_destino_id`, `monto`, `nota`, `etiqueta_fecha`, `actualizado_en`)

---

## 🧪 Ejecución de Pruebas (Unitarias + E2E)

Para ejecutar las **42 pruebas automatizadas** (8 suites con 100% de éxito) y actualizar el reporte HTML en [`test/reporte_pruebas_e2e.html`](test/reporte_pruebas_e2e.html):

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
