# 04. Suite de Pruebas Unitarias, E2E y Regresión

El proyecto cuenta con una suite completa de **39 pruebas automatizadas divididas en 8 suites** dentro de la carpeta [`test/`](../test/), diseñada para validar de punta a punta todos los cálculos financieros, flujos de usuario y sincronización con Supabase.

---

## 1. Archivos en la Carpeta `test/`

| Archivo | Descripción |
| :--- | :--- |
| [`test/run_all_tests.js`](../test/run_all_tests.js) | **Ejecutor principal de regresión (Node.js).** Corre las 8 suites (39 casos de prueba), valida toda la lógica sobre la aplicación real y actualiza automáticamente el reporte HTML y el log JSON. |
| [`test/reporte_pruebas_e2e.html`](../test/reporte_pruebas_e2e.html) | **Reporte Visual HTML de Ejecución.** Muestra el dashboard de cobertura (100%), tiempos de ejecución y el detalle caso por caso de las 39 pruebas. |
| [`test/resultados_regresion.json`](../test/resultados_regresion.json) | **Bitácora JSON estructurada** con el resultado detallado de cada caso para auditoría o integración continua (CI). |
| [`test/verify_supabase_live.js`](../test/verify_supabase_live.js) | **Verificador en vivo de Supabase.** Comprueba la conexión contra las 7 tablas en español en la nube (`HTTP 200/201`) y verifica la integridad de los datos sincronizados. |
| [`test/unit/money_formatter_test.dart`](../test/unit/money_formatter_test.dart) | Pruebas unitarias en Dart para formateo de moneda `es-AR`, conversión a USD y evaluador aritmético con `+`. |
| [`test/unit/domain_calculators_test.dart`](../test/unit/domain_calculators_test.dart) | Pruebas unitarias en Dart para Disponible Real, Margen Diario hasta cobro y reglas de cierre de mes. |
| [`test/unit/accounts_and_categories_test.dart`](../test/unit/accounts_and_categories_test.dart) | Pruebas unitarias en Dart para saldos de billeteras, transferencias propias y ABM de categorías. |
| [`test/e2e/realito_full_flows_e2e_test.dart`](../test/e2e/realito_full_flows_e2e_test.dart) | Pruebas integrales End-to-End en Dart que recorren todos los flujos de usuario de principio a fin. |

---

## 2. Cómo Ejecutar las Pruebas de Regresión

Para correr toda la suite de pruebas y regenerar el reporte HTML actualizado, ejecutá desde la raíz del proyecto:

```powershell
node test/run_all_tests.js
```

Para verificar además la sincronización en vivo con las 7 tablas en español de **Supabase**:

```powershell
node test/verify_supabase_live.js
```

---

## 3. Cobertura de las 8 Suites (39 Casos de Prueba)

1. **Suite 1 — Formateo Monetario, Conversión USD y Calculadora (`+`):** 6 casos (formato `es-AR`, signos negativos, conversión con Dólar Oficial Venta Banco Nación, suma de múltiples términos).
2. **Suite 2 — Motor Financiero, Disponible Real y Margen Diario:** 6 casos (cálculo exacto de Disponible en Octubre/Septiembre/Agosto, margen diario según días hasta el próximo cobro, alerta de déficit).
3. **Suite 3 — Flujo E2E de Movimientos Diarios e Ingresos (Alta, Edición, Baja y Filtros):** 6 casos (alta de gasto con descuento en billetera, alta de ingreso, edición cambiando monto/cuenta con reversión de saldo, eliminación, búsqueda en vivo y agrupación por día).
4. **Suite 4 — Flujo E2E de Gastos Fijos Mensuales y Mes Adelantado:** 5 casos (progreso pagado vs. pendiente, tilde de pago en 1 toque, alta con suma `+`, edición de vencimiento y clonado de Octubre a Noviembre).
5. **Suite 5 — Flujo E2E de Cuentas, Ajuste de Saldo y Transferencias Propias:** 5 casos (ajuste manual de saldo real, transferencia entre cuentas propias sin alterar el Disponible del mes, validaciones de seguridad y ABM de billeteras).
6. **Suite 6 — Flujo E2E de Categorías Independientes y Selector de Íconos:** 4 casos (separación estricta entre Fijos, Diarios e Ingresos, creación inline con ícono, edición y protección de categoría mínima).
7. **Suite 7 — Flujo E2E de Cierre de Mes y Transferencia de Saldo a Favor:** 4 casos (visibilidad condicional del banner de sobrante, transferencia en 1 toque al mes siguiente y bloqueo de duplicados).
8. **Suite 8 — Flujo E2E de Reporte Mensual, PDF, Temas y Persistencia:** 3 casos (reporte 100% en ARS con porcentajes verificados, alternancia de tema Obsidiana/Marfil y persistencia completa en `localStorage` + Supabase).

