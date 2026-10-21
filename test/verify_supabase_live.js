/**
 * Sincronización inicial completa y prueba E2E en vivo contra Supabase
 * Proyecto: https://zgbhnwpeiecrhcllswse.supabase.co
 */
const SUPABASE_URL = 'https://zgbhnwpeiecrhcllswse.supabase.co';
const SUPABASE_KEY = 'sb_publishable_FWGeqKTleDFvJxG-McFSUA_-J6kCBk9';

const headers = {
  'Content-Type': 'application/json',
  'apikey': SUPABASE_KEY,
  'Authorization': `Bearer ${SUPABASE_KEY}`,
  'Prefer': 'resolution=merge-duplicates,return=representation'
};

const ACCOUNTS = [
  { id: 'acc-pp', name: 'Personal Pay', icon: '📱', balance: 315400 },
  { id: 'acc-bank', name: 'Banco', icon: '🏦', balance: 129690 },
  { id: 'acc-cash', name: 'Efectivo', icon: '💵', balance: 48500 }
];

const FIXED_BILL_CATEGORIES = [
  { id: 'fcat-home', name: 'Alquiler / Vivienda', icon: '🏠', color: '#8B5CF6' },
  { id: 'fcat-services', name: 'Servicios (Luz/Gas/Int)', icon: '💡', color: '#6366F1' },
  { id: 'fcat-edu', name: 'Colegio / Educación', icon: '🎓', color: '#06B6D4' },
  { id: 'fcat-cards', name: 'Tarjetas / Cuotas', icon: '💳', color: '#D97706' },
  { id: 'fcat-auto', name: 'Seguro / Auto Fijo', icon: '🚗', color: '#3B82F6' },
  { id: 'fcat-family', name: 'Mensualidad / Familia', icon: '💜', color: '#EC4899' },
  { id: 'fcat-subs', name: 'Suscripciones', icon: '☁️', color: '#14B8A6' }
];

const EXPENSE_CATEGORIES = [
  { id: 'cat-super', name: 'Súper/Carne', icon: '🛒', color: '#F59E0B' },
  { id: 'cat-emilis', name: 'Emilis', icon: '💜', color: '#EC4899' },
  { id: 'cat-food', name: 'Comida', icon: '🍔', color: '#F97316' },
  { id: 'cat-auto', name: 'Nafta/Viajes', icon: '🚗', color: '#3B82F6' },
  { id: 'cat-other', name: 'Farmacia/Otros', icon: '✨', color: '#14B8A6' }
];

const INCOME_CATEGORIES = [
  { id: 'inc-sueldo', name: 'Sueldo', icon: '💼', color: '#10B981' },
  { id: 'inc-adelanto', name: 'Adelanto sueldo', icon: '⚡', color: '#059669' },
  { id: 'inc-prestamo', name: 'Préstamo', icon: '🤝', color: '#0EA5E9' },
  { id: 'inc-uber', name: 'Uber / DiDi', icon: '🚕', color: '#F59E0B' },
  { id: 'inc-extra', name: 'Sobrante / Extra', icon: '✨', color: '#8B5CF6' }
];

const monthlyBills = [
  { id: 'b-nov-1', monthKey: '2026-11', title: 'Alquiler', categoryId: 'fcat-home', amount: 780000, paid: 0, dueDay: 5, isPaid: false, note: 'Mes adelantado listo para actualizar' },
  { id: 'b-nov-2', monthKey: '2026-11', title: 'Colegio', categoryId: 'fcat-edu', amount: 177072, paid: 0, dueDay: 15, isPaid: false, note: '' },
  { id: 'b-oct-1', monthKey: '2026-10', title: 'Alquiler', categoryId: 'fcat-home', amount: 780000, paid: 780000, dueDay: 5, isPaid: true, note: 'Pagado mes completo' },
  { id: 'b-oct-2', monthKey: '2026-10', title: 'Luz Marina', categoryId: 'fcat-family', amount: 257000, paid: 257000, dueDay: 10, isPaid: true, note: '7.000 + 200.000 + 30.000 + 20.000' },
  { id: 'b-oct-3', monthKey: '2026-10', title: 'Colegio', categoryId: 'fcat-edu', amount: 177072, paid: 0, dueDay: 15, isPaid: false, note: 'Cuota mensual colegio' },
  { id: 'b-oct-4', monthKey: '2026-10', title: 'Seguro Auto', categoryId: 'fcat-auto', amount: 150000, paid: 40000, dueDay: 18, isPaid: false, note: '15gasolina+10limpiador+15gasolina' },
  { id: 'b-oct-5', monthKey: '2026-10', title: 'Día de las Madres', categoryId: 'fcat-family', amount: 60000, paid: 37000, dueDay: 18, isPaid: false, note: '8 cartera + 29 aros' },
  { id: 'b-oct-6', monthKey: '2026-10', title: 'Go Cuotas', categoryId: 'fcat-cards', amount: 52892, paid: 52892, dueDay: 12, isPaid: true, note: 'Cuotas del mes' },
  { id: 'b-oct-7', monthKey: '2026-10', title: 'Emilis (Fijo Mes)', categoryId: 'fcat-family', amount: 50000, paid: 0, dueDay: 20, isPaid: false, note: 'Mensualidad Emilis' },
  { id: 'b-oct-8', monthKey: '2026-10', title: 'Personal Pay / Tarjeta', categoryId: 'fcat-cards', amount: 48570, paid: 48570, dueDay: 8, isPaid: true, note: 'Resumen mensual' },
  { id: 'b-oct-9', monthKey: '2026-10', title: 'Luz', categoryId: 'fcat-services', amount: 42527, paid: 0, dueDay: 16, isPaid: false, note: 'Factura electricidad' },
  { id: 'b-oct-10', monthKey: '2026-10', title: 'Corte de pelo', categoryId: 'fcat-family', amount: 33000, paid: 33000, dueDay: 10, isPaid: true, note: '20.000 + 13.000' },
  { id: 'b-oct-11', monthKey: '2026-10', title: 'Internet', categoryId: 'fcat-services', amount: 24371, paid: 24371, dueDay: 14, isPaid: true, note: 'Fibra hogar' },
  { id: 'b-oct-12', monthKey: '2026-10', title: 'Cholas', categoryId: 'fcat-family', amount: 20000, paid: 20000, dueDay: 12, isPaid: true, note: 'Calzado' },
  { id: 'b-oct-13', monthKey: '2026-10', title: 'Gemini y iCloud', categoryId: 'fcat-subs', amount: 13500, paid: 13500, dueDay: 15, isPaid: true, note: '8.500 + 5.000' },
  { id: 'b-oct-14', monthKey: '2026-10', title: 'Gas', categoryId: 'fcat-services', amount: 9923, paid: 0, dueDay: 19, isPaid: false, note: 'Servicio de gas' },
  { id: 'b-sep-1', monthKey: '2026-09', title: 'Alquiler', categoryId: 'fcat-home', amount: 780000, paid: 300000, dueDay: 5, isPaid: false, note: 'Pago parcial 300.000' },
  { id: 'b-sep-2', monthKey: '2026-09', title: 'Inscripción Jardín', categoryId: 'fcat-edu', amount: 200000, paid: 200000, dueDay: 10, isPaid: true, note: 'Matrícula jardín' },
  { id: 'b-sep-3', monthKey: '2026-09', title: 'Colegio', categoryId: 'fcat-edu', amount: 177072, paid: 177072, dueDay: 15, isPaid: true, note: 'Cuota septiembre' },
  { id: 'b-sep-4', monthKey: '2026-09', title: 'Luz Marina', categoryId: 'fcat-family', amount: 120000, paid: 120000, dueDay: 10, isPaid: true, note: '20.000 + 100.000' },
  { id: 'b-sep-5', monthKey: '2026-09', title: 'Seguro Auto', categoryId: 'fcat-auto', amount: 106059, paid: 106059, dueDay: 18, isPaid: true, note: 'Nafta y pastillas de freno' },
  { id: 'b-aug-1', monthKey: '2026-08', title: 'Alquiler', categoryId: 'fcat-home', amount: 780000, paid: 780000, dueDay: 5, isPaid: true, note: 'Pagado completo' },
  { id: 'b-aug-2', monthKey: '2026-08', title: 'Mecánico', categoryId: 'fcat-auto', amount: 600000, paid: 600000, dueDay: 11, isPaid: true, note: 'Arreglo general auto' },
  { id: 'b-aug-3', monthKey: '2026-08', title: 'Transferencia Fiat', categoryId: 'fcat-auto', amount: 200000, paid: 200000, dueDay: 8, isPaid: true, note: 'Trámite transferencia' },
  { id: 'b-aug-4', monthKey: '2026-08', title: 'Colegio', categoryId: 'fcat-edu', amount: 173310, paid: 173310, dueDay: 15, isPaid: true, note: 'Cuota agosto' }
];

const transactions = [
  { id: 't-oct-inc1', monthKey: '2026-10', dayLabel: '1 Oct', type: 'income', categoryId: 'inc-sueldo', accountId: 'acc-bank', amount: 1767474, note: 'Sueldo Neto' },
  { id: 't-oct-inc2', monthKey: '2026-10', dayLabel: 'Martes 13', type: 'income', categoryId: 'inc-adelanto', accountId: 'acc-bank', amount: 700000, note: 'Adelanto de sueldo' },
  { id: 't-oct-1', monthKey: '2026-10', dayLabel: 'Jueves 15', type: 'expense', categoryId: 'cat-super', accountId: 'acc-pp', amount: 9029, note: 'Fiambre' },
  { id: 't-oct-2', monthKey: '2026-10', dayLabel: 'Jueves 15', type: 'expense', categoryId: 'cat-auto', accountId: 'acc-pp', amount: 4110, note: 'Denuncia de venta Captiva' },
  { id: 't-oct-3', monthKey: '2026-10', dayLabel: 'Jueves 15', type: 'expense', categoryId: 'cat-auto', accountId: 'acc-pp', amount: 3900, note: 'DiDi' },
  { id: 't-oct-4', monthKey: '2026-10', dayLabel: 'Miércoles 14', type: 'expense', categoryId: 'cat-emilis', accountId: 'acc-pp', amount: 45000, note: 'Emilis (25.000 + 20.000)' },
  { id: 't-oct-5', monthKey: '2026-10', dayLabel: 'Lunes 12', type: 'expense', categoryId: 'cat-emilis', accountId: 'acc-pp', amount: 23000, note: 'Emilis (5.000 + 18.000)' },
  { id: 't-oct-6', monthKey: '2026-10', dayLabel: 'Lunes 12', type: 'expense', categoryId: 'cat-super', accountId: 'acc-cash', amount: 7400, note: 'Jamón y queso' },
  { id: 't-oct-7', monthKey: '2026-10', dayLabel: 'Sábado 10', type: 'expense', categoryId: 'cat-other', accountId: 'acc-pp', amount: 33000, note: 'Corte de pelo' },
  { id: 't-oct-8', monthKey: '2026-10', dayLabel: 'Sábado 10', type: 'expense', categoryId: 'cat-emilis', accountId: 'acc-pp', amount: 14000, note: 'Emilis' },
  { id: 't-oct-9', monthKey: '2026-10', dayLabel: 'Sábado 10', type: 'expense', categoryId: 'cat-food', accountId: 'acc-pp', amount: 9500, note: 'Mostaza' },
  { id: 't-oct-10', monthKey: '2026-10', dayLabel: 'Viernes 9', type: 'expense', categoryId: 'cat-emilis', accountId: 'acc-pp', amount: 20000, note: 'Emilis' },
  { id: 't-oct-14', monthKey: '2026-10', dayLabel: 'Martes 6', type: 'expense', categoryId: 'cat-super', accountId: 'acc-bank', amount: 45100, note: 'Carne' },
  { id: 't-oct-15', monthKey: '2026-10', dayLabel: 'Martes 6', type: 'expense', categoryId: 'cat-super', accountId: 'acc-cash', amount: 30788, note: 'Verduras' },
  { id: 't-oct-16', monthKey: '2026-10', dayLabel: 'Martes 6', type: 'expense', categoryId: 'cat-food', accountId: 'acc-pp', amount: 13800, note: 'Burger (6.100 + 7.700)' },
  { id: 't-sep-inc1', monthKey: '2026-09', dayLabel: '1 Sep', type: 'income', categoryId: 'inc-sueldo', accountId: 'acc-bank', amount: 1765593, note: 'Sueldo Septiembre' },
  { id: 't-sep-1', monthKey: '2026-09', dayLabel: 'Miércoles 16', type: 'expense', categoryId: 'cat-other', accountId: 'acc-bank', amount: 310000, note: 'Pasaporte Papá' },
  { id: 't-sep-2', monthKey: '2026-09', dayLabel: 'Sábado 5', type: 'expense', categoryId: 'cat-super', accountId: 'acc-bank', amount: 285000, note: 'Compras mayoristas' },
  { id: 't-aug-inc1', monthKey: '2026-08', dayLabel: '1 Ago', type: 'income', categoryId: 'inc-sueldo', accountId: 'acc-bank', amount: 2569000, note: 'Sueldo Agosto' },
  { id: 't-aug-1', monthKey: '2026-08', dayLabel: 'Jueves 13', type: 'expense', categoryId: 'cat-auto', accountId: 'acc-bank', amount: 250000, note: 'Mecánico adicional' }
];

const accountTransfers = [
  { id: 'tr-1', fromId: 'acc-bank', toId: 'acc-pp', amount: 150000, note: 'Fondeo billetera diaria', dateLabel: 'Martes 13' },
  { id: 'tr-2', fromId: 'acc-bank', toId: 'acc-cash', amount: 40000, note: 'Retiro efectivo cajero', dateLabel: 'Jueves 8' }
];

async function syncAllTables() {
  const nowIso = new Date().toISOString();

  // 1. gastos_fijos
  const gastosFijosRows = monthlyBills.map(b => ({
    id: b.id,
    mes_anio: b.monthKey,
    titulo: b.title,
    categoria_id: b.categoryId,
    monto_total: b.amount,
    monto_pagado: b.paid,
    dia_vencimiento: b.dueDay,
    esta_pagado: b.isPaid,
    nota: b.note,
    actualizado_en: nowIso
  }));
  const rBills = await fetch(`${SUPABASE_URL}/rest/v1/gastos_fijos?on_conflict=id`, {
    method: 'POST',
    headers,
    body: JSON.stringify(gastosFijosRows)
  });
  console.log('Upsert gastos_fijos:', rBills.status, `(${gastosFijosRows.length} registros)`);

  // 2. movimientos
  const movimientosRows = transactions.map(t => ({
    id: t.id,
    mes_anio: t.monthKey,
    etiqueta_dia: t.dayLabel,
    tipo: t.type === 'income' ? 'ingreso' : 'gasto',
    categoria_id: t.categoryId,
    cuenta_id: t.accountId,
    monto: t.amount,
    nota: t.note,
    actualizado_en: nowIso
  }));
  const rMovs = await fetch(`${SUPABASE_URL}/rest/v1/movimientos?on_conflict=id`, {
    method: 'POST',
    headers,
    body: JSON.stringify(movimientosRows)
  });
  console.log('Upsert movimientos:', rMovs.status, `(${movimientosRows.length} registros)`);

  // 3. transferencias_cuentas
  const trRows = accountTransfers.map(tr => ({
    id: tr.id,
    cuenta_origen_id: tr.fromId,
    cuenta_destino_id: tr.toId,
    monto: tr.amount,
    nota: tr.note,
    etiqueta_fecha: tr.dateLabel,
    actualizado_en: nowIso
  }));
  const rTr = await fetch(`${SUPABASE_URL}/rest/v1/transferencias_cuentas?on_conflict=id`, {
    method: 'POST',
    headers,
    body: JSON.stringify(trRows)
  });
  console.log('Upsert transferencias_cuentas:', rTr.status, `(${trRows.length} registros)`);

  // 4. estado_sincronizado
  const fullSnapshot = {
    ACCOUNTS,
    FIXED_BILL_CATEGORIES,
    EXPENSE_CATEGORIES,
    INCOME_CATEGORIES,
    monthlyBills,
    transactions,
    accountTransfers,
    OFICIAL_SELL_RATE: 1015,
    nextPaydayDateStr: '2026-11-05',
    transferredPositiveMonths: {},
    isDarkObsidian: true
  };
  const rSnap = await fetch(`${SUPABASE_URL}/rest/v1/estado_sincronizado?on_conflict=clave_espacio`, {
    method: 'POST',
    headers,
    body: JSON.stringify([{
      clave_espacio: 'principal',
      datos_json: fullSnapshot,
      actualizado_en: nowIso
    }])
  });
  console.log('Upsert estado_sincronizado:', rSnap.status, '(1 snapshot maestro)');
}

syncAllTables();

