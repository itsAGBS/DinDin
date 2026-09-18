import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finup.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        descricao TEXT NOT NULL,
        valor REAL NOT NULL,
        data TEXT NOT NULL,
        categoria TEXT NOT NULL,
        tipo TEXT NOT NULL,
        sincronizado INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // Migração para quem já tinha o banco na versão 1 (sem sincronização).
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN sincronizado INTEGER NOT NULL DEFAULT 0',
      );
    }
  }

  Future<TransactionModel> insertTransaction(TransactionModel t) async {
    final db = await instance.database;
    final map = t.toMap()..['sincronizado'] = 0;
    final id = await db.insert('transactions', map);
    return t.copyWith(id: id);
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await instance.database;
    final result = await db.query('transactions', orderBy: 'data DESC');
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  Future<int> updateTransaction(TransactionModel t) async {
    final db = await instance.database;
    final map = t.toMap()..['sincronizado'] = 0;
    return db.update('transactions', map, where: 'id = ?', whereArgs: [t.id]);
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getSaldoAtual() async {
    final transactions = await getAllTransactions();
    double saldo = 0;
    for (var t in transactions) {
      saldo += t.tipo == TransactionType.receita ? t.valor : -t.valor;
    }
    return saldo;
  }

  /// Transações que ainda não foram enviadas para o Firestore.
  Future<List<TransactionModel>> getTransacoesNaoSincronizadas() async {
    final db = await instance.database;
    final result = await db.query(
      'transactions',
      where: 'sincronizado = 0',
    );
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  /// Marca uma transação como já sincronizada com a nuvem.
  Future<void> marcarComoSincronizada(int id) async {
    final db = await instance.database;
    await db.update(
      'transactions',
      {'sincronizado': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Insere (ou substitui) uma transação vinda da nuvem, já marcando como
  /// sincronizada. Usado ao restaurar dados de outro dispositivo.
  Future<void> inserirTransacaoDaNuvem(TransactionModel t) async {
    final db = await instance.database;
    final map = t.toMap()..['sincronizado'] = 1;
    await db.insert(
      'transactions',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> existeTransacaoComId(int id) async {
    final db = await instance.database;
    final result = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
