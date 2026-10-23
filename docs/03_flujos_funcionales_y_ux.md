# 03. Flujos Funcionales, Fórmulas Financieras y Diseño UX

Este documento describe la arquitectura funcional, cálculos matemáticos, pantallas y modales de **Realito**, bajo el **Modelo B ("Presupuesto Mensual Ágil y Disponible Libre")**.

---

## 1. Las 4 Pestañas Principales de la Barra Inferior

La barra de navegación inferior organiza el uso diario en 4 accesos claros más el botón central de acción rápida:
`[🏠 Inicio]   [☑️ Fijos]   [＋ Cargar]   [📊 Reportes]   [⚙️ Ajustes]`

---

### 🏠 Pestaña 1: Inicio (`Dashboard`)
* **Barra de Meses Dinámica y Auto-centrada:**
  - Permite recorrer meses históricos (`Agosto`, `Septiembre`), el mes actual (`Octubre (Actual)`) y los meses futuros (`Noviembre (Próximo)`, `Diciembre`, etc.).
  - El mes actual se posiciona automáticamente en el centro de la pantalla. El usuario puede desplazarse horizontalmente arrastrando con el mouse en PC o deslizando con el dedo en móviles.
  - **Generación dinámica hacia el futuro:** A medida que avanza el calendario, los meses nuevos se crean y etiquetan automáticamente sin requerir intervención manual.
* **Barra de Cotización Dólar Oficial:**
  - Muestra el precio de venta minorista del **Banco Nación** ($ 1.015 ARS). Permite alternar la visualización entre Pesos (`ARS`) y Dólares (`USD`).
* **Tarjeta Principal del Presupuesto (Hero Card):**
  - **Fórmula Matemática Pura:**
    $$\mathbf{Disponible} = \mathbf{Ingresos} - \mathbf{Gastos\ Fijos} - \mathbf{Gastos\ Diarios}$$
  - **Consistencia 1:1:** El monto grande coincide con exactitud con las 3 sub-tarjetas de la pantalla (`Ingresos`, `Gastos Fijos`, `Gastos Diarios`) y con la pestaña de **Reportes**.
  - **Desglose de Fijos Pendientes:** Si aún restan abonar servicios o compromisos fijos, el texto indica con precisión:  
    `Faltan pagar $ X en fijos • Te quedan $ Y libres en el mes`  
    *(o `Todos los gastos fijos del mes están al día • $ Y 100% disponible`)*.
  - **Alerta de Presupuesto Excedido:** Si un mes finaliza en déficit (como Septiembre), la tarjeta adopta un gradiente bordó/rojo de alerta informando el excedente.
* **Calculadora de Disponible Diario hasta el Próximo Cobro:**
  - Evalúa la fecha de cobro de sueldo configurada para el mes (por defecto el día 5):
    $$\mathbf{Margen\ Diario} = \left\lfloor \frac{\mathbf{Disponible\ Libre}}{\mathbf{Días\ restantes\ hasta\ el\ próximo\ cobro}} \right\rfloor$$
  - Informa con claridad: `💡 Podés gastar $ X / día · Quedan N días hasta tu próximo cobro (DD/MM)`.
* **Traspaso de Sobrante Positivo a Fin de Mes:**
  - **Regla de Ocultación Inteligente:** A mitad de mes (ej. día 23), el cartel **permanece 100% oculto** para no generar fricción.
  - **Cuándo aparece:** Únicamente el **último día del mes (día 30/31)** o el **día 1 del mes nuevo** si el mes anterior cerró con saldo positivo disponible.
  - **Acción:** Al confirmar, registra un ingreso en el mes siguiente bajo el concepto `🎉 Sobrante a favor de [Mes Anterior]` en la categoría `inc-extra` y se auto-oculta de inmediato.
* **Buscador en Tiempo Real y Lista de Movimientos:**
  - Búsqueda instantánea por notas, rubros y días.
  - Filtros directos: `Todos`, `Solo Gastos`, `Solo Ingresos`.
  - Agrupación por día con total gastado en cada encabezado diario.

---

### ☑️ Pestaña 2: Gastos Fijos (`Checklist Mensual`)
* **Seguimiento y Vencimientos:** Monitorea el total presupuestado, monto abonado y saldo pendiente.
* **Pagos Totales y Parciales:** Permite tildar un compromiso completo en un toque o registrar entregas parciales (ej. seña de alquiler o adelanto).
* **Copia al Mes Adelantado:** Botón `📋 Copiar gastos fijos de [Mes Actual] a [Mes Próximo] para actualizar montos` para trasladar toda la plantilla mensual en 1 toque.
* **Filtros Rápidos:** `Todos`, `Faltan Pagar` y `Pagados`.
* **Editor con Suma Rápida:** Admite expresiones matemáticas directas (ej. `20000+13000`) y creación de categorías fijas inline.

---

### 📊 Pestaña 3: Reportes & Estadísticas (`Reportes`)
Reemplazó a la antigua pestaña de cuentas bancarias en la barra inferior, centralizando la inteligencia financiera del mes:
1. **4 Tarjetas Ejecutivas:** Ingresos Totales, Saldo Disponible Libre, Gastos Fijos Totales y Gastos Diarios.
2. **Gráfico 1 — ¿A dónde fue tu ingreso este mes?:** Barra tricolor que muestra el porcentaje consumido por Gastos Fijos, Gastos Diarios y el porcentaje que quedó como Disponible Libre.
3. **Gráfico 1.B — Desglose 100% de Gastos Fijos por Rubro:** Distribución interna de los compromisos fijos (Alquiler, Servicios, Educación, Tarjetas, Seguros, Familia).
4. **Gráfico 2 — Gastos Diarios por Rubro:** Barras progresivas ordenadas de mayor a menor gasto del mes.
5. **📄 Descarga de Reporte PDF:** Genera y exporta la hoja mensual en formato PDF para archivo o envío por WhatsApp.

---

### ⚙️ Pestaña 4: Ajustes (`Configuración del Sistema`)
* **Tema Visual:** Alternancia en 1 toque entre **Obsidiana** (oscuro `#0F172A`) y **Salvia & Marfil** (claro `#F5F2EB`).
* **Administración de Categorías:** ABM independiente de Categorías Fijas, Diarias e Ingresos con selector de 28 emojis.
* **Ajuste de Cotización Dólar Oficial:** Actualización desde Banco Nación o fijación manual.
* **Fecha de Cobro Mensual:** Configuración del día de cobro para el cálculo de margen diario.
* **Respaldo Local / Nube:** Exportación e importación de copias de seguridad en formato JSON.

---

## 2. Modal de Carga Rápida (`＋ Cargar`) — Flujo de 2 Segundos

El modal flotante central (`＋`) optimiza la carga de gastos diarios sin requerir pasos innecesarios:
1. **Paso 1 — Fecha:** `Hoy`, `Ayer` o `📅 Otro día` (grilla táctil compacta de días del mes).
2. **Paso 2 — Categoría:** Selector táctil en un toque (`Súper`, `Comida`, `Nafta`, `Farmacia`, etc.).
3. **Monto y Nota:** Teclado numérico ergonómico con tecla `+` para acumular tickets y detalle opcional.
4. **Guardar:** Registra el movimiento al instante, actualiza los totales y persiste en almacenamiento seguro.

---

## 3. Seguridad y Sanitización contra Inyecciones (XSS)

Todos los textos ingresados por el usuario (notas de movimientos, títulos de servicios y nombres de categorías) son procesados por la función de escape:

```javascript
function escapeHtml(str) {
  if (str === null || str === undefined) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}
```

Esto garantiza que ningún carácter especial distorsione la estructura del DOM ni permita la ejecución de scripts no autorizados.
