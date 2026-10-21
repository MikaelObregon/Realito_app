import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/transactions/domain/entities/transaction_models.dart';

/// Estado de un registro en la cola de salida (Outbox Pattern)
enum OutboxStatus {
  pending,
  syncing,
  synced,
  failed,
}

/// Operación atómica encolada localmente cuando el usuario opera con o sin internet
class OutboxEntry {
  const OutboxEntry({
    required this.id,
    required this.entityTable,
    required this.entityId,
    required this.operation, // 'INSERT' | 'UPDATE' | 'DELETE'
    required this.payloadJson,
    required this.createdAt,
    this.retryCount = 0,
    this.status = OutboxStatus.pending,
  });

  final String id;
  final String entityTable;
  final String entityId;
  final String operation;
  final String payloadJson;
  final DateTime createdAt;
  final int retryCount;
  final OutboxStatus status;

  OutboxEntry copyWith({
    int? retryCount,
    OutboxStatus? status,
  }) {
    return OutboxEntry(
      id: id,
      entityTable: entityTable,
      entityId: entityId,
      operation: operation,
      payloadJson: payloadJson,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
    );
  }
}

/// Esquema SQL DDL embebido para SQLite + SQLCipher (Drift / sqflite_sqlcipher)
class LocalSqliteSchema {
  LocalSqliteSchema._();

  static const List<String> createTableStatements = [
    '''
    CREATE TABLE IF NOT EXISTS cuentas (
      id TEXT PRIMARY KEY NOT NULL,
      nombre TEXT NOT NULL,
      icono TEXT NOT NULL DEFAULT '💳',
      saldo INTEGER NOT NULL DEFAULT 0,
      actualizado_en TEXT NOT NULL
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS categorias (
      id TEXT PRIMARY KEY NOT NULL,
      tipo TEXT NOT NULL,
      nombre TEXT NOT NULL,
      icono TEXT NOT NULL DEFAULT '🏷️',
      color TEXT NOT NULL DEFAULT '#6366F1',
      actualizado_en TEXT NOT NULL
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS gastos_fijos (
      id TEXT PRIMARY KEY NOT NULL,
      mes_anio TEXT NOT NULL,
      titulo TEXT NOT NULL,
      categoria_id TEXT NOT NULL,
      monto_total INTEGER NOT NULL,
      monto_pagado INTEGER NOT NULL DEFAULT 0,
      dia_vencimiento INTEGER NOT NULL DEFAULT 10,
      esta_pagado INTEGER NOT NULL DEFAULT 0,
      nota TEXT NOT NULL DEFAULT '',
      actualizado_en TEXT NOT NULL
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS movimientos (
      id TEXT PRIMARY KEY NOT NULL,
      mes_anio TEXT NOT NULL,
      etiqueta_dia TEXT NOT NULL DEFAULT 'Hoy',
      tipo TEXT NOT NULL,
      categoria_id TEXT,
      cuenta_id TEXT NOT NULL,
      monto INTEGER NOT NULL,
      nota TEXT NOT NULL DEFAULT '',
      actualizado_en TEXT NOT NULL
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS transferencias_cuentas (
      id TEXT PRIMARY KEY NOT NULL,
      cuenta_origen_id TEXT NOT NULL,
      cuenta_destino_id TEXT NOT NULL,
      monto INTEGER NOT NULL DEFAULT 0,
      nota TEXT NOT NULL DEFAULT '',
      etiqueta_fecha TEXT NOT NULL,
      actualizado_en TEXT NOT NULL
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS configuracion_usuario (
      id TEXT PRIMARY KEY NOT NULL DEFAULT 'principal',
      cotizacion_dolar_oficial REAL NOT NULL DEFAULT 1015.0,
      fuente_dolar TEXT NOT NULL DEFAULT 'API Venta',
      fecha_proximo_cobro TEXT NOT NULL DEFAULT '2026-11-05',
      moneda_visualizacion TEXT NOT NULL DEFAULT 'ARS',
      tema_visual TEXT NOT NULL DEFAULT 'obsidiana',
      meses_sobrante_transferido TEXT NOT NULL DEFAULT '{}',
      actualizado_en TEXT NOT NULL
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS cola_sincronizacion (
      id TEXT PRIMARY KEY NOT NULL,
      tabla_destino TEXT NOT NULL,
      registro_id TEXT NOT NULL,
      operacion TEXT NOT NULL,
      datos_json TEXT NOT NULL,
      reintentos INTEGER NOT NULL DEFAULT 0,
      estado TEXT NOT NULL DEFAULT 'pendiente',
      creado_en TEXT NOT NULL
    );
    ''',
  ];
}

/// Motor de Base de Datos Local Offline-First para Realito (100% en español).
/// En producción persiste sobre SQLite cifrado con SQLCipher y encola cada
/// cambio hacia las tablas en español de Supabase (`cuentas`, `categorias`,
/// `gastos_fijos`, `movimientos`, `transferencias_cuentas`, `configuracion_usuario`).
class AppDatabase {
  final List<OutboxEntry> _outboxQueue = [];
  final StreamController<List<OutboxEntry>> _outboxController =
      StreamController<List<OutboxEntry>>.broadcast();

  List<OutboxEntry> get pendingOutboxEntries => _outboxQueue
      .where((e) => e.status == OutboxStatus.pending || e.status == OutboxStatus.failed)
      .toList(growable: false);

  Stream<List<OutboxEntry>> watchOutboxQueue() => _outboxController.stream;

  /// Registra un movimiento (`movimientos`) + su evento en la cola de sincronización
  Future<void> recordTransactionWithOutbox(TransactionEntity tx) async {
    final entry = OutboxEntry(
      id: 'outbox-mov-${tx.id}-${DateTime.now().microsecondsSinceEpoch}',
      entityTable: 'movimientos',
      entityId: tx.id,
      operation: 'INSERT',
      payloadJson: jsonEncode({
        'id': tx.id,
        'mes_anio': tx.monthKey,
        'etiqueta_dia': tx.dayLabel,
        'tipo': tx.type == TransactionType.income ? 'ingreso' : 'gasto',
        'categoria_id': tx.categoryId,
        'cuenta_id': tx.accountId,
        'monto': (tx.amountMinor / 100).round(),
        'nota': tx.note,
        'actualizado_en': tx.transactionDate.toIso8601String(),
      }),
      createdAt: DateTime.now(),
    );
    _outboxQueue.add(entry);
    _outboxController.add(List.unmodifiable(_outboxQueue));
  }

  /// Registra alta/edición/baja de un Gasto Fijo (`gastos_fijos`) + Outbox
  Future<void> recordMonthlyBillChangeWithOutbox({
    required MonthlyBillEntity bill,
    required String operation, // 'INSERT' | 'UPDATE' | 'DELETE'
  }) async {
    final entry = OutboxEntry(
      id: 'outbox-fijo-${bill.id}-${DateTime.now().microsecondsSinceEpoch}',
      entityTable: 'gastos_fijos',
      entityId: bill.id,
      operation: operation,
      payloadJson: jsonEncode({
        'id': bill.id,
        'mes_anio': bill.monthKey,
        'titulo': bill.title,
        'categoria_id': bill.categoryId,
        'monto_total': (bill.amountMinor / 100).round(),
        'monto_pagado': ((bill.paidAmountMinor ?? 0) / 100).round(),
        'esta_pagado': bill.isPaid,
        'nota': bill.note,
      }),
      createdAt: DateTime.now(),
    );
    _outboxQueue.add(entry);
    _outboxController.add(List.unmodifiable(_outboxQueue));
  }

  /// Marca un registro del Outbox como sincronizado tras confirmación de Supabase
  Future<void> markOutboxSynced(String outboxId) async {
    final index = _outboxQueue.indexWhere((e) => e.id == outboxId);
    if (index != -1) {
      _outboxQueue[index] = _outboxQueue[index].copyWith(
        status: OutboxStatus.synced,
      );
      _outboxController.add(List.unmodifiable(_outboxQueue));
    }
  }

  /// Incrementa el contador de reintentos si hubo corte de red
  Future<void> markOutboxFailed(String outboxId) async {
    final index = _outboxQueue.indexWhere((e) => e.id == outboxId);
    if (index != -1) {
      final current = _outboxQueue[index];
      _outboxQueue[index] = current.copyWith(
        retryCount: current.retryCount + 1,
        status: OutboxStatus.failed,
      );
      _outboxController.add(List.unmodifiable(_outboxQueue));
    }
  }
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

