-- =============================================================================
-- REALITO — ESQUEMA DE BASE DE DATOS EN LA NUBE (SUPABASE / POSTGRESQL)
-- 100% EN ESPAÑOL (Tablas, Columnas y Políticas)
-- =============================================================================

-- 1. Tabla de Cuentas / Billeteras (Personal Pay, Banco, Efectivo, etc.)
CREATE TABLE IF NOT EXISTS public.cuentas (
  id TEXT PRIMARY KEY,
  nombre TEXT NOT NULL,
  icono TEXT NOT NULL DEFAULT '💳',
  saldo BIGINT NOT NULL DEFAULT 0,
  actualizado_en TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Tabla de Categorías (Separadas en: 'fijo', 'gasto_diario', 'ingreso')
CREATE TABLE IF NOT EXISTS public.categorias (
  id TEXT PRIMARY KEY,
  tipo TEXT NOT NULL CHECK (tipo IN ('fijo', 'gasto_diario', 'ingreso')),
  nombre TEXT NOT NULL,
  icono TEXT NOT NULL DEFAULT '🏷️',
  color TEXT NOT NULL DEFAULT '#6366F1',
  actualizado_en TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Tabla de Gastos Fijos Mensuales (Alquiler, Colegio, Servicios, Tarjetas, etc.)
CREATE TABLE IF NOT EXISTS public.gastos_fijos (
  id TEXT PRIMARY KEY,
  mes_anio TEXT NOT NULL, -- Ej: '2026-10', '2026-11'
  titulo TEXT NOT NULL,
  categoria_id TEXT NOT NULL,
  monto_total BIGINT NOT NULL DEFAULT 0,
  monto_pagado BIGINT NOT NULL DEFAULT 0,
  dia_vencimiento INTEGER NOT NULL DEFAULT 10,
  esta_pagado BOOLEAN NOT NULL DEFAULT FALSE,
  nota TEXT DEFAULT '',
  actualizado_en TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Tabla de Movimientos del Mes (Gastos Diarios e Ingresos)
CREATE TABLE IF NOT EXISTS public.movimientos (
  id TEXT PRIMARY KEY,
  mes_anio TEXT NOT NULL, -- Ej: '2026-10'
  etiqueta_dia TEXT NOT NULL, -- Ej: 'Hoy', 'Jueves 15'
  tipo TEXT NOT NULL CHECK (tipo IN ('gasto', 'ingreso')),
  categoria_id TEXT NOT NULL,
  cuenta_id TEXT NOT NULL,
  monto BIGINT NOT NULL DEFAULT 0,
  nota TEXT DEFAULT '',
  actualizado_en TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. Tabla de Transferencias entre mis Cuentas
CREATE TABLE IF NOT EXISTS public.transferencias_cuentas (
  id TEXT PRIMARY KEY,
  cuenta_origen_id TEXT NOT NULL,
  cuenta_destino_id TEXT NOT NULL,
  monto BIGINT NOT NULL DEFAULT 0,
  nota TEXT DEFAULT '',
  etiqueta_fecha TEXT NOT NULL,
  actualizado_en TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. Tabla de Configuración General del Usuario
CREATE TABLE IF NOT EXISTS public.configuracion_usuario (
  id TEXT PRIMARY KEY DEFAULT 'principal',
  cotizacion_dolar_oficial NUMERIC(12, 2) NOT NULL DEFAULT 1015.00,
  fuente_dolar TEXT NOT NULL DEFAULT 'API Venta',
  fecha_proximo_cobro TEXT NOT NULL DEFAULT '2026-11-05',
  moneda_visualizacion TEXT NOT NULL DEFAULT 'ARS',
  tema_visual TEXT NOT NULL DEFAULT 'obsidiana',
  meses_sobrante_transferido JSONB NOT NULL DEFAULT '{}'::jsonb,
  actualizado_en TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 7. Tabla de Respaldo Instantáneo Multi-Dispositivo (Sincronización completa)
CREATE TABLE IF NOT EXISTS public.estado_sincronizado (
  clave_espacio TEXT PRIMARY KEY DEFAULT 'principal',
  datos_json JSONB NOT NULL,
  actualizado_en TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- HABILITAR ACCESO DESDE LA APP (ROW LEVEL SECURITY)
-- =============================================================================
ALTER TABLE public.cuentas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categorias ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gastos_fijos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.movimientos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transferencias_cuentas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.configuracion_usuario ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.estado_sincronizado ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Acceso total cuentas" ON public.cuentas;
CREATE POLICY "Acceso total cuentas"
  ON public.cuentas FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Acceso total categorias" ON public.categorias;
CREATE POLICY "Acceso total categorias"
  ON public.categorias FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Acceso total gastos_fijos" ON public.gastos_fijos;
CREATE POLICY "Acceso total gastos_fijos"
  ON public.gastos_fijos FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Acceso total movimientos" ON public.movimientos;
CREATE POLICY "Acceso total movimientos"
  ON public.movimientos FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Acceso total transferencias_cuentas" ON public.transferencias_cuentas;
CREATE POLICY "Acceso total transferencias_cuentas"
  ON public.transferencias_cuentas FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Acceso total configuracion_usuario" ON public.configuracion_usuario;
CREATE POLICY "Acceso total configuracion_usuario"
  ON public.configuracion_usuario FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Acceso total estado_sincronizado" ON public.estado_sincronizado;
CREATE POLICY "Acceso total estado_sincronizado"
  ON public.estado_sincronizado FOR ALL USING (true) WITH CHECK (true);
