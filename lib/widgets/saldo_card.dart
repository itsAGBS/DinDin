import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../theme/app_colors.dart';

class SaldoCard extends StatefulWidget {
  final double saldo;

  const SaldoCard({super.key, required this.saldo});

  @override
  State<SaldoCard> createState() => _SaldoCardState();
}

class _SaldoCardState extends State<SaldoCard> {
  static const _chaveSaldoVisivel = 'saldo_visivel';
  static const _storage = FlutterSecureStorage();

  bool _saldoVisivel = true;

  double get saldo => widget.saldo;

  @override
  void initState() {
    super.initState();
    _carregarPreferenciaVisibilidade();
  }

  Future<void> _carregarPreferenciaVisibilidade() async {
    try {
      final valor = await _storage.read(key: _chaveSaldoVisivel);
      if (valor != null && mounted) {
        setState(() => _saldoVisivel = valor == 'true');
      }
    } catch (_) {
      // Mantem o padrao (saldo visivel) se a leitura falhar.
    }
  }

  Future<void> _alternarVisibilidadeSaldo() async {
    final novoValor = !_saldoVisivel;
    setState(() => _saldoVisivel = novoValor);
    try {
      await _storage.write(key: _chaveSaldoVisivel, value: '$novoValor');
    } catch (_) {
      // Falha ao persistir nao deve impedir a alternancia na tela.
    }
  }

  static const _saldoMascarado = 'R\$ ••••••';

  String _formatarMoeda(double valor) {
    final sinal = valor < 0 ? '-' : '';
    final valorAbsoluto = valor.abs().toStringAsFixed(2).replaceAll('.', ',');
    return '${sinal}R\$ $valorAbsoluto';
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final corFundo = cores.corDoSaldo(saldo);
    final neutro = saldo == 0;
    final positivo = saldo >= 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(20),
        border: neutro && cores.saldoDestaqueBorda != null
            ? Border.all(color: cores.saldoDestaqueBorda!)
            : null,
        boxShadow: [
          BoxShadow(
            color: corFundo.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Saldo atual',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: _alternarVisibilidadeSaldo,
                    tooltip: _saldoVisivel ? 'Ocultar saldo' : 'Mostrar saldo',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: Icon(
                      _saldoVisivel
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  positivo ? Icons.trending_up : Icons.trending_down,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _saldoVisivel ? _formatarMoeda(saldo) : _saldoMascarado,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
