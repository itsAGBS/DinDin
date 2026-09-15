enum TransactionType { receita, despesa }

class TransactionModel {
  final int? id;
  final String descricao;
  final double valor;
  final DateTime data;
  final String categoria;
  final TransactionType tipo;

  TransactionModel({
    this.id,
    required this.descricao,
    required this.valor,
    required this.data,
    required this.categoria,
    required this.tipo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'descricao': descricao,
      'valor': valor,
      'data': data.toIso8601String(),
      'categoria': categoria,
      'tipo': tipo == TransactionType.receita ? 'receita' : 'despesa',
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      descricao: map['descricao'] as String,
      valor: map['valor'] as double,
      data: DateTime.parse(map['data'] as String),
      categoria: map['categoria'] as String,
      tipo: map['tipo'] == 'receita'
          ? TransactionType.receita
          : TransactionType.despesa,
    );
  }

  TransactionModel copyWith({
    int? id,
    String? descricao,
    double? valor,
    DateTime? data,
    String? categoria,
    TransactionType? tipo,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      descricao: descricao ?? this.descricao,
      valor: valor ?? this.valor,
      data: data ?? this.data,
      categoria: categoria ?? this.categoria,
      tipo: tipo ?? this.tipo,
    );
  }
}

const List<String> categoriasPadrao = [
  'Alimentação',
  'Transporte',
  'Moradia',
  'Lazer',
  'Saúde',
  'Educação',
  'Salário',
  'Outros',
];
