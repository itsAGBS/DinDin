import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../models/transaction_model.dart';
import '../services/sync_service.dart';
import '../utils/calculos_mensais.dart';

enum SyncStatus { desconectado, sincronizando, sincronizado, erro }

class TransactionProvider extends ChangeNotifier {
  TransactionProvider({SyncService? syncService, FirebaseAuth? firebaseAuth})
      : _syncService = syncService ?? SyncService(),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance {
    _authSubscription = _firebaseAuth.authStateChanges().listen(_aoMudarUsuario);
  }

  final SyncService _syncService;
  final FirebaseAuth _firebaseAuth;
  late final StreamSubscription<User?> _authSubscription;

  List<TransactionModel> _transacoes = [];
  double _saldo = 0;
  double? _limiteMensal;
  bool _carregando = false;
  String? _uid;
  SyncStatus _syncStatus = SyncStatus.desconectado;

  List<TransactionModel> get transacoes => _transacoes;
  double get saldo => _saldo;
  double? get limiteMensal => _limiteMensal;
  bool get carregando => _carregando;
  List<TransactionModel> get ultimasTransacoes => _transacoes.take(5).toList();
  SyncStatus get syncStatus => _syncStatus;

  double get gastoMesAtual =>
      CalculosMensais.gastoDoMes(_transacoes, DateTime.now());

  double get restanteOrcamento {
    final limite = _limiteMensal;
    if (limite == null) return 0;
    return math.max(0.0, limite - gastoMesAtual).toDouble();
  }

  double get fracaoOrcamento =>
      CalculosMensais.fracaoUsada(gastoMesAtual, _limiteMensal);

  double get percentualOrcamento => fracaoOrcamento * 100;

  bool get orcamentoExcedido {
    final limite = _limiteMensal;
    if (limite == null) return false;
    return CalculosMensais.nivel(gastoMesAtual, limite) ==
        NivelOrcamento.excedido;
  }

  Map<String, double> get despesasPorCategoriaMesAtual =>
      CalculosMensais.despesasPorCategoria(_transacoes, DateTime.now());

  Future<void> carregarDados() async {
    _carregando = true;
    notifyListeners();

    try {
      _transacoes = await DatabaseHelper.instance.getAllTransactions();
      _saldo = await DatabaseHelper.instance.getSaldoAtual();
      _limiteMensal = await DatabaseHelper.instance.getLimiteMensal();
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<void> definirLimiteMensal(double valor) async {
    if (valor <= 0) {
      throw ArgumentError.value(
        valor,
        'valor',
        'O limite deve ser maior que zero',
      );
    }

    await DatabaseHelper.instance.salvarLimiteMensal(valor);
    _limiteMensal = valor;
    notifyListeners();
  }

  Future<void> adicionarTransacao(TransactionModel transacao) async {
    final salva = await DatabaseHelper.instance.insertTransaction(transacao);
    await carregarDados();
    _enviarUmaTransacaoParaNuvem(salva);
  }

  Future<void> editarTransacao(TransactionModel transacao) async {
    await DatabaseHelper.instance.updateTransaction(transacao);
    await carregarDados();
    _enviarUmaTransacaoParaNuvem(transacao);
  }

  Future<void> excluirTransacao(int id) async {
    await DatabaseHelper.instance.deleteTransaction(id);
    await carregarDados();

    final uid = _uid;
    if (uid == null) return;
    try {
      await _syncService.excluirTransacao(uid, id);
    } catch (_) {
      // Sem conexão, a exclusão vale só no aparelho; a nuvem não é atualizada.
    }
  }

  void _aoMudarUsuario(User? user) {
    _uid = user?.uid;
    if (user != null) {
      sincronizarComNuvem();
    } else {
      _syncStatus = SyncStatus.desconectado;
      notifyListeners();
    }
  }

  Future<void> sincronizarComNuvem() async {
    final uid = _uid;
    if (uid == null) return;

    _syncStatus = SyncStatus.sincronizando;
    notifyListeners();

    try {
      final pendentes =
          await DatabaseHelper.instance.getTransacoesNaoSincronizadas();
      for (final t in pendentes) {
        await _syncService.enviarTransacao(uid, t);
        if (t.id != null) {
          await DatabaseHelper.instance.marcarComoSincronizada(t.id!);
        }
      }

      final remotas = await _syncService.buscarTodasTransacoes(uid);
      for (final t in remotas) {
        if (t.id == null) continue;
        final existeLocal =
            await DatabaseHelper.instance.existeTransacaoComId(t.id!);
        if (!existeLocal) {
          await DatabaseHelper.instance.inserirTransacaoDaNuvem(t);
        }
      }

      await carregarDados();
      _syncStatus = SyncStatus.sincronizado;
    } catch (_) {
      _syncStatus = SyncStatus.erro;
    }
    notifyListeners();
  }

  Future<void> _enviarUmaTransacaoParaNuvem(TransactionModel t) async {
    final uid = _uid;
    if (uid == null || t.id == null) return;
    try {
      await _syncService.enviarTransacao(uid, t);
      await DatabaseHelper.instance.marcarComoSincronizada(t.id!);
      _syncStatus = SyncStatus.sincronizado;
    } catch (_) {
      _syncStatus = SyncStatus.erro;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
