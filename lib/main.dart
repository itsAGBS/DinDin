import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/transaction_model.dart';
import 'providers/transaction_provider.dart';

void main() {
  runApp(const DinDinApp());
}

class DinDinApp extends StatelessWidget {
  const DinDinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TransactionProvider()..carregarDados(),
      child: MaterialApp(
        title: 'DinDin',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          useMaterial3: true,
        ),
        home: const TelaTesteBanco(),
      ),
    );
  }
}

// Tela temporaria so para testar se o banco de dados local esta funcionando.
// Sera substituida pelo Dashboard de verdade.
class TelaTesteBanco extends StatelessWidget {
  const TelaTesteBanco({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('DinDin - Teste do banco')),
      body: Center(
        child: Text('Saldo atual: R\$ ${provider.saldo.toStringAsFixed(2)}\n'
            'Transacoes: ${provider.transacoes.length}'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<TransactionProvider>().adicionarTransacao(
            TransactionModel(
              descricao: 'Teste',
              valor: 50,
              data: DateTime.now(),
              categoria: 'Outros',
              tipo: TransactionType.despesa,
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}