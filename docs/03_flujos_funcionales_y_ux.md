# 03. Flujos Funcionales, Fórmulas Financieras y Diseño UX

Este documento describe cómo funciona cada pestaña, modal y cálculo financiero dentro de **Realito**.

---

## 1. Las 4 Pestañas Principales de la App

### 🏠 Pestaña 1: Inicio (`Dashboard`)
- **Selector de Meses Deslizable:** Permite navegar entre meses históricos (`Agosto`, `Septiembre`), el mes actual (`Octubre`) y el mes adelantado (`Noviembre ⏭️`) usando el dedo, la rueda del mouse o las flechas laterales.
- **Barra de Dólar Oficial (Venta — Banco Nación):** Muestra el precio de venta minorista de referencia del **Banco de la Nación Argentina**. Al tocarla permite actualizar el valor oficial del banco o fijar un valor manual.
- **Tarjeta Principal de Disponible Real:**
  $$\text{Disponible del Mes} = \text{Ingresos del Mes} - \text{Gastos Fijos Totales} - \text{Gastos Diarios}$$
  - Incluye el cálculo automático de **Margen Diario hasta el próximo cobro**:
    $$\text{Gasto Diario Recomendado} = \left\lfloor \frac{\text{Disponible del Mes}}{\text{Días hasta el próximo cobro}} \right\rfloor$$
- **Pase de Saldo a Favor al Mes Siguiente:**
  - Aparece únicamente cuando un mes cerrado (o el último día del mes en curso) termina con saldo positivo (`Disponible > 0`), permitiendo transferirlo como ingreso extraordinario al mes siguiente con 1 toque.
- **Gráfico de Gastos Diarios por Rubro:** Barras porcentuales ordenadas de mayor a menor peso sobre el gasto diario del mes.
- **Listado de Movimientos Agrupados por Día:**
  - Incluye **buscador en tiempo real** (por nota, rubro, cuenta o día) y filtros rápidos (`Todos`, `Solo Gastos`, `Solo Ingresos`).
  - Cada grupo diario muestra en su encabezado el total gastado en ese día.

---

### ☑️ Pestaña 2: Gastos Fijos (`Checklist Mensual`)
- **Resumen y Barra de Progreso:** Muestra el total de compromisos fijos del mes, cuánto ya está pagado y cuánto falta pagar.
- **Clonación al Mes Adelantado (`Noviembre ⏭️`):** Incluye un botón rápido para copiar la estructura de gastos fijos del mes actual al mes siguiente y adelantar pagos o actualizar montos.
- **Filtros de Estado:** `Todos`, `Faltan Pagar` y `Pagados`.
- **Alta y Edición de Gastos Fijos:**
  - Permite ingresar montos directos o sumas rápidas con `+` (ej. `20000+13000`), registrar pagos parciales, elegir día de vencimiento (`Día 5`, `Día 10`, `Día 15`, `Día 20` o cualquier día del `1` al `31`) y crear nuevas categorías fijas con selector de íconos en el mismo modal.

---

### 🏦 Pestaña 3: Cuentas (`Mis Cuentas y Transferencias`)
- **Estado de Billeteras en Vivo:** Muestra el saldo disponible actual en cada cuenta (`Personal Pay`, `Banco`, `Efectivo`, etc.).
- **Botón `Ajustar saldo`:** Permite cuadrar en cualquier momento el saldo real exacto que tenés en tu billetera o banco.
- **Transferencias entre Cuentas Propias:**
  - Permite pasar dinero de una cuenta origen a una cuenta destino (ej. retirar efectivo del cajero o fondear `Personal Pay` desde `Banco`) descontando de una y sumando en la otra **sin alterar el Disponible del mes ni inflar los gastos**.

---

### ⚙️ Pestaña 4: Ajustes (`Personalización y Reporte Mensual`)
- **Apariencia Visual:** Alterna en 1 toque entre el modo oscuro **Obsidiana** (`#0F172A`) y el modo claro cálido **Salvia & Marfil** (`#F5F2EB`).
- **Gestión Independiente de Categorías y Cuentas:**
  - Listas separadas para administrar **Categorías de Gastos Fijos**, **Categorías de Gastos Diarios**, **Categorías de Ingresos** y **Cuentas / Billeteras**, cada una con selector visual de 28 íconos para agregar o editar.
- **Reporte Mensual y Descarga / Compartido de PDF:**
  - **`📊 Ver Reporte + Gráficos`:** Abre el resumen ejecutivo del mes 100% en Pesos con gráficos de distribución de ingresos, desglose por rubro y texto formateado listo para copiar a WhatsApp o Notas.
  - **`📑 Descargar PDF`:** Abre la **Hoja A4 Blanca** dentro de la app, genera el archivo `Reporte_Realito_<Mes>.pdf` y:
    - En **teléfonos móviles (Android / iPhone)** despliega automáticamente el **menú nativo de Compartir** con el archivo `.pdf` adjunto (para enviarlo por WhatsApp, Mail o guardarlo en Archivos).
    - En **computadora** descarga directamente el archivo `.pdf`.

---

## 2. Modales Compactos y Selector de Fecha Rápido

Tanto el modal de **Nuevo Movimiento (`🧾 Cargar Gasto` / `＋ Ingreso`)** como el de **Editar Movimiento** están diseñados sin scroll horizontal y con controles táctiles directos:
- **Calculadora con Suma Rápida (`+`):** Permite sumar varios ítems en un mismo movimiento (ej. `12000+4500`) guardando automáticamente el desglose en la nota.
- **Selector de Fecha de 3 Botones + Grilla del Mes:**
  - En lugar del calendario nativo del navegador, ofrece 3 botones limpios: **`Hoy`**, **`Ayer`** y **`📅 Otro día ▾` / `📅 Cambiar día ▾`**, que despliega una grilla compacta con todos los días del mes (`1` al `31`) para elegir el día exacto con un solo toque.

