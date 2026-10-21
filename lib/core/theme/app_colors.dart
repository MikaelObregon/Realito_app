import 'package:flutter/material.dart';

/// Paleta de colores renovada de Realito:
/// - Modo Claro: "Salvia & Marfil Cálido" (evita el blanco frío/triste de hospital)
/// - Modo Oscuro: "Obsidiana & Esmeralda Fintech" (profundo, moderno y de alto contraste)
abstract final class AppColors {
  // Identidad Principal (Esmeralda Realito & Bosque Profundo)
  static const Color primaryLight = Color(0xFF065F46);
  static const Color primaryAccent = Color(0xFF10B981);
  static const Color primaryDark = Color(0xFF34D399);

  // Secundario (Índigo / Pizarra)
  static const Color secondaryLight = Color(0xFF1E293B);
  static const Color secondaryDark = Color(0xFF94A3B8);

  // Fondos Modo Claro: Marfil/Arena cálido + Tarjetas Crema suave
  static const Color backgroundLight = Color(0xFFF2EFE9);
  static const Color surfaceLight = Color(0xFFFFFDF9);
  static const Color surfaceVariantLight = Color(0xFFE6E1D6);

  // Fondos Modo Oscuro: Obsidiana Fintech + Pizarra elevada 100% sólida
  static const Color backgroundDark = Color(0xFF0B1120);
  static const Color surfaceDark = Color(0xFF151F32);
  static const Color surfaceVariantDark = Color(0xFF1E293B);

  // Semánticos Financieros
  static const Color incomeLight = Color(0xFF059669);
  static const Color incomeDark = Color(0xFF34D399);

  static const Color expenseLight = Color(0xFFE11D48);
  static const Color expenseDark = Color(0xFFFB7185);

  static const Color transferLight = Color(0xFF2563EB);
  static const Color transferDark = Color(0xFF60A5FA);

  // Alertas y Destacados (Ámbar Dorado)
  static const Color warningLight = Color(0xFFD97706);
  static const Color warningDark = Color(0xFFFBBF24);

  // Píldoras de Dólar Oficial (Venta)
  static const Color usdBadgeBgLight = Color(0xFFD1FAE5);
  static const Color usdBadgeTextLight = Color(0xFF065F46);
  static const Color usdBadgeBgDark = Color(0xFF064E3B);
  static const Color usdBadgeTextDark = Color(0xFF6EE7B7);
}
