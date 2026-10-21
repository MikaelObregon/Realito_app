# 02. Base de Datos en Supabase (Esquema 100% en Español)

La aplicación **Realito** se sincroniza automáticamente en segundo plano con una base de datos PostgreSQL alojada en **Supabase**. Tanto los nombres de las tablas como todas sus columnas están definidos íntegramente en **español**.

- **Archivo SQL de migración:** [`supabase/migrations/0001_initial_schema.sql`](../supabase/migrations/0001_initial_schema.sql)
- **Script de verificación en vivo:** [`test/verify_supabase_live.js`](../test/verify_supabase_live.js)

---

## 1. Diagrama de las 7 Tablas en Español

```mermaid
erDiagram
    CUENTAS ||--o{ MOVIMIENTOS : "cuenta_id"
    CUENTAS ||--o{ TRANSFERENCIAS_CUENTAS : "cuenta_origen_id / cuenta_destino_id"
    CATEGORIAS ||--o{ MOVIMIENTOS : "categoria_id"
    CATEGORIAS ||--o{ GASTOS_FIJOS : "categoria_id"

    CUENTAS {
        text id PK "Ej: acc-pp, acc-bank, acc-cash"
        text nombre "Ej: Personal Pay, Banco, Efectivo"
        text icono "Ej: 📱, 🏦, 💵"
        bigint saldo "Saldo actual en Pesos (ARS)"
        timestamptz actualizado_en
    }

    CATEGORIAS {
        text id PK "Ej: fcat-home, cat-super, inc-sueldo"
        text tipo "fijo | gasto_diario | ingreso"
        text nombre "Nombre visible del rubro"
        text icono "Emoji representativo"
        text color "Color hexadecimal (#10B981, etc.)"
        timestamptz actualizado_en
    }

    GASTOS_FIJOS {
        text id PK "Identificador del compromiso mensual"
        text mes_anio "Formato YYYY-MM (ej: 2026-10)"
        text titulo "Ej: Alquiler, Luz, Tarjeta Visa"
        text categoria_id FK "Referencia a categorias.id"
        bigint monto_total "Monto total en ARS"
        bigint monto_pagado "Monto abonado hasta el momento"
        integer dia_vencimiento "Día del mes (1 al 31)"
        boolean esta_pagado "true = Pagado completo"
        text nota "Detalle opcional"
        timestamptz actualizado_en
    }

    MOVIMIENTOS {
        text id PK "Identificador del movimiento"
        text mes_anio "Formato YYYY-MM (ej: 2026-10)"
        text etiqueta_dia "Ej: Jueves 15, Martes 13"
        text tipo "gasto | ingreso"
        text categoria_id FK "Referencia a categorias.id"
        text cuenta_id FK "Referencia a cuentas.id"
        bigint monto "Monto en ARS"
        text nota "Descripción o desglose de suma"
        timestamptz actualizado_en
    }

    TRANSFERENCIAS_CUENTAS {
        text id PK "Identificador del pase"
        text cuenta_origen_id FK "Cuenta desde donde sale"
        text cuenta_destino_id FK "Cuenta hacia donde entra"
        bigint monto "Monto transferido en ARS"
        text nota "Motivo de la transferencia"
        text etiqueta_fecha "Fecha legible"
        timestamptz actualizado_en
    }

    CONFIGURACION_USUARIO {
        text id PK "Valor fijo: 'principal'"
        numeric cotizacion_dolar_oficial "Precio de Venta Banco Nación"
        text fuente_dolar "Banco Nación (Venta)"
        date fecha_proximo_cobro "Fecha para cálculo de margen diario"
        text moneda_visualizacion "ARS | USD"
        text tema_visual "obsidiana | marfil"
        jsonb meses_sobrante_transferido "Control de cierres de mes transferidos"
        timestamptz actualizado_en
    }

    ESTADO_SINCRONIZADO {
        text clave_espacio PK "Valor fijo: 'principal'"
        jsonb datos_json "Snapshot completo multi-dispositivo"
        timestamptz actualizado_en
    }
```

---

## 2. Descripción Tabla por Tabla

| # | Nombre de la Tabla | Propósito en la App |
| :--- | :--- | :--- |
| **1** | `cuentas` | Guarda tus billeteras y cuentas activas (`Personal Pay`, `Banco`, `Efectivo` y cualquier otra que agregues), su ícono y su saldo actual en Pesos (`ARS`). |
| **2** | `categorias` | Almacena las 3 familias de rubros separadas por la columna `tipo`: **`fijo`** (Gastos Fijos), **`gasto_diario`** (Gastos Diarios) e **`ingreso`** (Ingresos). |
| **3** | `gastos_fijos` | Checklist mensual de pagos fijos por cada mes (`mes_anio`), con su día de vencimiento (`1` al `31`), monto total, monto pagado parcial o total y estado (`esta_pagado`). |
| **4** | `movimientos` | Todos los gastos diarios e ingresos cargados mes a mes, vinculados a la cuenta utilizada (`cuenta_id`), su categoría (`categoria_id`) y su día (`etiqueta_dia`). |
| **5** | `transferencias_cuentas` | Historial de pases de dinero entre tus propias cuentas (ej. de `Banco` a `Personal Pay`). Ajusta los saldos de ambas cuentas sin distorsionar los gastos ni ingresos del mes. |
| **6** | `configuracion_usuario` | Guarda tus preferencias globales: cotización vigente del Dólar Oficial (Venta — Banco Nación), fecha de tu próximo cobro, moneda activa (`ARS`/`USD`) y tema visual (`obsidiana`/`marfil`). |
| **7** | `estado_sincronizado` | Guarda una fotografía instantánea (`datos_json`) de todo el estado de la app bajo la clave `'principal'` para que al abrir la app en otro teléfono se hidrate toda la información en una sola lectura rápida. |

---

## 3. Cómo Funciona la Sincronización Automática (Sin Configuración Manual)

La conexión a la base de datos trabaja **100% por detrás de forma transparente**, sin mostrar paneles técnicos en la pantalla de Ajustes:

1. **Al abrir la aplicación (`pullFromSupabaseCloud`):**
   - La app consulta automáticamente Supabase en segundo plano y descarga la última versión sincronizada para que cualquier teléfono o computadora muestre exactamente los mismos saldos y movimientos.
2. **Al realizar cualquier cambio (`scheduleSupabaseCloudSync` → `pushAllToSupabaseCloud`):**
   - Cada vez que cargás un gasto/ingreso, editás un movimiento, marcás un gasto fijo como pagado, transferís entre cuentas o cambiás el tema visual, la app guarda primero en memoria local (`localStorage` en `< 5 ms`) y a los `600 ms` sincroniza automáticamente las **7 tablas en español** mediante `UPSERT` (`Prefer: resolution=merge-duplicates`).

