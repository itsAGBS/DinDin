import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/transaction_model.dart';

class SyncService {
  SyncService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _colecaoDoUsuario(String uid) {
    return _firestore.collection('users').doc(uid).collection('transactions');
  }

  Future<void> enviarTransacao(String uid, TransactionModel transacao) async {
    final dados = transacao.toMap()..remove('sincronizado');
    await _colecaoDoUsuario(uid)
        .doc(transacao.id.toString())
        .set(dados);
  }

  Future<void> excluirTransacao(String uid, int id) async {
    await _colecaoDoUsuario(uid).doc(id.toString()).delete();
  }

  Future<List<TransactionModel>> buscarTodasTransacoes(String uid) async {
    final snapshot = await _colecaoDoUsuario(uid).get();
    return snapshot.docs.map((doc) {
      final dados = Map<String, dynamic>.from(doc.data());
      dados['id'] = int.parse(doc.id);
      return TransactionModel.fromMap(dados);
    }).toList();
  }
}

