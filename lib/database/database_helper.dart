import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  static const String _chaveLimiteMensal = 'limite_mensal';

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
      version: 3,
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

    await _criarTabelaSettings(db);
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN sincronizado INTEGER NOT NULL DEFAULT 0',
      );
    }

    // Não use else: uma instalação antiga pode precisar executar as duas etapas.
    if (oldVersion < 3) {
      await _criarTabelaSettings(db);
    }
  }

  Future<void> _criarTabelaSettings(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        chave TEXT PRIMARY KEY,
        valor TEXT NOT NULL
      )
    ''');
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

  /// Salva o limite mensal localmente. Ele é uma preferência do dispositivo
  /// e não participa da sincronização das transações com o Firestore.
  Future<void> salvarLimiteMensal(double valor) async {
    final db = await instance.database;
    await db.insert(
      'settings',
      {
        'chave': _chaveLimiteMensal,
        'valor': valor.toStringAsFixed(2),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<double?> getLimiteMensal() async {
    final db = await instance.database;
    final result = await db.query(
      'settings',
      columns: ['valor'],
      where: 'chave = ?',
      whereArgs: [_chaveLimiteMensal],
      limit: 1,
    );

    if (result.isEmpty) return null;
    final valor = result.first['valor'];
    if (valor == null) return null;
    return double.tryParse(valor.toString());
  }

  Future<List<TransactionModel>> getTransacoesNaoSincronizadas() async {
    final db = await instance.database;
    final result = await db.query(
      'transactions',
      where: 'sincronizado = 0',
    );
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  Future<void> marcarComoSincronizada(int id) async {
    final db = await instance.database;
    await db.update(
      'transactions',
      {'sincronizado': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

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
