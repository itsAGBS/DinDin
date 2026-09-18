import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/transaction_model.dart';

/// Encapsula a comunicação com o Firestore para a sincronização das
/// transações. Cada usuário tem sua própria subcoleção:
/// users/{uid}/transactions/{id}
///
/// O {id} do documento no Firestore é sempre o mesmo id inteiro usado no
/// SQLite local, para não precisar manter dois identificadores diferentes
/// para a mesma transação.
class SyncService {
  SyncService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _colecaoDoUsuario(String uid) {
    return _firestore.collection('users').doc(uid).collection('transactions');
  }

  /// Envia (cria ou sobrescreve) uma transação para a nuvem.
  Future<void> enviarTransacao(String uid, TransactionModel transacao) async {
    final dados = transacao.toMap()..remove('sincronizado');
    await _colecaoDoUsuario(uid)
        .doc(transacao.id.toString())
        .set(dados);
  }

  /// Remove uma transação da nuvem.
  Future<void> excluirTransacao(String uid, int id) async {
    await _colecaoDoUsuario(uid).doc(id.toString()).delete();
  }

  /// Busca todas as transações do usuário salvas na nuvem.
  Future<List<TransactionModel>> buscarTodasTransacoes(String uid) async {
    final snapshot = await _colecaoDoUsuario(uid).get();
    return snapshot.docs.map((doc) {
      final dados = Map<String, dynamic>.from(doc.data());
      dados['id'] = int.parse(doc.id);
      return TransactionModel.fromMap(dados);
    }).toList();
  }
}
