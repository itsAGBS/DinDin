import 'package:flutter/material.dart';

import 'transaction_model.dart';

/// Categoria usada para classificar uma transação.
///
/// Cada categoria pertence a um único [tipo] (receita ou despesa) — por
/// exemplo, "Salário" só faz sentido como receita, "Alimentação" só como
/// despesa. O ícone é usado tanto no seletor do formulário de cadastro
/// quanto na lista de transações ([TransacaoTile]).
@immutable
class CategoryModel {
  final String nome;
  final IconData icone;
  final TransactionType tipo;

  const CategoryModel({
    required this.nome,
    required this.icone,
    required this.tipo,
  });

  @override
  bool operator ==(Object other) =>
      other is CategoryModel && other.nome == nome && other.tipo == tipo;

  @override
  int get hashCode => Object.hash(nome, tipo);
}

/// Categorias padrão de despesa.
const List<CategoryModel> categoriasDespesa = [
  CategoryModel(
    nome: 'Alimentação',
    icone: Icons.restaurant_outlined,
    tipo: TransactionType.despesa,
  ),
  CategoryModel(
    nome: 'Transporte',
    icone: Icons.directions_bus_outlined,
    tipo: TransactionType.despesa,
  ),
  CategoryModel(
    nome: 'Moradia',
    icone: Icons.home_outlined,
    tipo: TransactionType.despesa,
  ),
  CategoryModel(
    nome: 'Lazer',
    icone: Icons.sports_esports_outlined,
    tipo: TransactionType.despesa,
  ),
  CategoryModel(
    nome: 'Saúde',
    icone: Icons.favorite_border,
    tipo: TransactionType.despesa,
  ),
  CategoryModel(
    nome: 'Educação',
    icone: Icons.school_outlined,
    tipo: TransactionType.despesa,
  ),
  CategoryModel(
    nome: 'Compras',
    icone: Icons.shopping_bag_outlined,
    tipo: TransactionType.despesa,
  ),
  CategoryModel(
    nome: 'Contas',
    icone: Icons.receipt_long_outlined,
    tipo: TransactionType.despesa,
  ),
  CategoryModel(
    nome: 'Outros',
    icone: Icons.category_outlined,
    tipo: TransactionType.despesa,
  ),
];

/// Categorias padrão de receita.
const List<CategoryModel> categoriasReceita = [
  CategoryModel(
    nome: 'Salário',
    icone: Icons.payments_outlined,
    tipo: TransactionType.receita,
  ),
  CategoryModel(
    nome: 'Freelance',
    icone: Icons.laptop_mac_outlined,
    tipo: TransactionType.receita,
  ),
  CategoryModel(
    nome: 'Investimentos',
    icone: Icons.trending_up,
    tipo: TransactionType.receita,
  ),
  CategoryModel(
    nome: 'Presente',
    icone: Icons.card_giftcard_outlined,
    tipo: TransactionType.receita,
  ),
  CategoryModel(
    nome: 'Outros',
    icone: Icons.category_outlined,
    tipo: TransactionType.receita,
  ),
];

const List<CategoryModel> categoriasPadrao = [
  ...categoriasDespesa,
  ...categoriasReceita,
];

/// Categorias disponíveis para o [tipo] informado, usadas para montar o
/// seletor no formulário de cadastro/edição de transação.
List<CategoryModel> categoriasPorTipo(TransactionType tipo) {
  return tipo == TransactionType.despesa ? categoriasDespesa : categoriasReceita;
}

/// Ícone correspondente ao nome de uma categoria (usado na listagem de
/// transações). Cai num ícone genérico caso a categoria não seja mais
/// reconhecida (ex: dado antigo salvo antes de uma mudança na lista).
IconData iconeDaCategoria(String nome) {
  return categoriasPadrao
      .firstWhere(
        (c) => c.nome == nome,
        orElse: () => const CategoryModel(
          nome: 'Outros',
          icone: Icons.category_outlined,
          tipo: TransactionType.despesa,
        ),
      )
      .icone;
}
