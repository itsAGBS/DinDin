import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../models/transaction_model.dart';
import '../services/sync_service.dart';

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
  bool _carregando = false;
  String? _uid;
  SyncStatus _syncStatus = SyncStatus.desconectado;

  List<TransactionModel> get transacoes => _transacoes;
  double get saldo => _saldo;
  bool get carregando => _carregando;
  List<TransactionModel> get ultimasTransacoes => _transacoes.take(5).toList();
  SyncStatus get syncStatus => _syncStatus;

  Future<void> carregarDados() async {
    _carregando = true;
    notifyListeners();
    _transacoes = await DatabaseHelper.instance.getAllTransactions();
    _saldo = await DatabaseHelper.instance.getSaldoAtual();
    _carregando = false;
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
      // Sem conexão ou erro no Firestore: a exclusão local já valeu,
      // e não há como "marcar como pendente" uma exclusão sem manter
      // um registro extra (fora do escopo desta fase). Se o documento
      // continuar na nuvem, ele volta a aparecer localmente na próxima
      // sincronização completa.
    }
  }

  /// Dispara ao logar ou deslogar. Ao logar, faz uma sincronização
  /// completa (sobe pendências locais, baixa o que só existe na nuvem).
  void _aoMudarUsuario(User? user) {
    _uid = user?.uid;
    if (user != null) {
      sincronizarComNuvem();
    } else {
      _syncStatus = SyncStatus.desconectado;
      notifyListeners();
    }
  }

  /// Sincronização completa: envia tudo que está pendente localmente e
  /// traz de volta qualquer transação que exista na nuvem mas não no
  /// aparelho atual (ex: usuário logou em um dispositivo novo).
  Future<void> sincronizarComNuvem() async {
    final uid = _uid;
    if (uid == null) return;

    _syncStatus = SyncStatus.sincronizando;
    notifyListeners();

    try {
      final pendentes = await DatabaseHelper.instance.getTransacoesNaoSincronizadas();
      for (final t in pendentes) {
        await _syncService.enviarTransacao(uid, t);
        if (t.id != null) {
          await DatabaseHelper.instance.marcarComoSincronizada(t.id!);
        }
      }

      final remotas = await _syncService.buscarTodasTransacoes(uid);
      for (final t in remotas) {
        if (t.id == null) continue;
        final existeLocal = await DatabaseHelper.instance.existeTransacaoComId(t.id!);
        if (!existeLocal) {
          await DatabaseHelper.instance.inserirTransacaoDaNuvem(t);
        }
      }

      await carregarDados();
      _syncStatus = SyncStatus.sincronizado;
    } catch (_) {
      // Provavelmente sem internet. Os dados locais continuam intactos;
      // a sincronização será tentada novamente na próxima chamada
      // (próximo login, próxima transação adicionada, etc).
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
