import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/transaction_model.dart';

class TransactionProvider extends ChangeNotifier {
  List<TransactionModel> _transacoes = [];
  double _saldo = 0;
  bool _carregando = false;

  List<TransactionModel> get transacoes => _transacoes;
  double get saldo => _saldo;
  bool get carregando => _carregando;
  List<TransactionModel> get ultimasTransacoes => _transacoes.take(5).toList();

  Future<void> carregarDados() async {
    _carregando = true;
    notifyListeners();
    _transacoes = await DatabaseHelper.instance.getAllTransactions();
    _saldo = await DatabaseHelper.instance.getSaldoAtual();
    _carregando = false;
    notifyListeners();
  }

  Future<void> adicionarTransacao(TransactionModel transacao) async {
    await DatabaseHelper.instance.insertTransaction(transacao);
    await carregarDados();
  }

  Future<void> editarTransacao(TransactionModel transacao) async {
    await DatabaseHelper.instance.updateTransaction(transacao);
    await carregarDados();
  }

  Future<void> excluirTransacao(int id) async {
    await DatabaseHelper.instance.deleteTransaction(id);
    await carregarDados();
  }
}
