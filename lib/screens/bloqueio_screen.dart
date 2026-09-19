import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/bloqueio_provider.dart';
import '../theme/app_colors.dart';

const _tamanhoPin = 4;

/// Tela de bloqueio exibida sempre que o app é aberto (ou volta do segundo plano) com a proteção ativada.
/// Pede biometria automaticamente quando disponível, com o PIN numérico como alternativa.

class BloqueioScreen extends StatefulWidget {
  const BloqueioScreen({super.key});

  @override
  State<BloqueioScreen> createState() => _BloqueioScreenState();
}

class _BloqueioScreenState extends State<BloqueioScreen> {
  String _pinDigitado = '';
  bool _jaTentouBiometriaAutomatica = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tentarBiometriaAutomaticamente();
  }

  void _tentarBiometriaAutomaticamente() {
    if (_jaTentouBiometriaAutomatica) return;
    _jaTentouBiometriaAutomatica = true;

    final bloqueio = context.read<BloqueioProvider>();
    if (bloqueio.biometriaAtivada && bloqueio.biometriaDisponivelNoAparelho) {
      // Espera o primeiro frame terminar antes de abrir o prompt nativo.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<BloqueioProvider>().desbloquearComBiometria();
      });
    }
  }

  void _digitar(String numero) {
    if (_pinDigitado.length >= _tamanhoPin) return;
    setState(() => _pinDigitado += numero);

    if (_pinDigitado.length == _tamanhoPin) _confirmarPin();
  }

  void _apagar() {
    if (_pinDigitado.isEmpty) return;
    setState(() => _pinDigitado = _pinDigitado.substring(0, _pinDigitado.length - 1));
  }

  Future<void> _confirmarPin() async {
    final bloqueio = context.read<BloqueioProvider>();
    final correto = await bloqueio.desbloquearComPin(_pinDigitado);

    if (!mounted) return;
    if (!correto) setState(() => _pinDigitado = '');
  }

  Future<void> _sairDaConta() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text(
          'Esqueceu o PIN? Você pode sair da conta e entrar novamente '
          'com seu e-mail e senha.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      await context.read<AuthProvider>().sair();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloqueio = context.watch<BloqueioProvider>();
    final mostrarBiometria =
        bloqueio.biometriaAtivada && bloqueio.biometriaDisponivelNoAparelho;

    return Scaffold(
      backgroundColor: AppColors.destaque,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 48),
              const SizedBox(height: 16),
              const Text(
                'DinDin bloqueado',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                mostrarBiometria
                    ? 'Use a biometria ou digite seu PIN'
                    : 'Digite seu PIN para continuar',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 32),
              _IndicadorPin(preenchidos: _pinDigitado.length, total: _tamanhoPin),
              const SizedBox(height: 12),
              SizedBox(
                height: 20,
                child: bloqueio.erro != null
                    ? Text(
                        bloqueio.erro!,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: AppColors.alerta,
                          fontSize: 13,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              _TecladoNumerico(
                habilitado: !bloqueio.processando,
                onDigitar: _digitar,
                onApagar: _apagar,
              ),
              const Spacer(),
              if (mostrarBiometria)
                TextButton.icon(
                  onPressed: bloqueio.processando
                      ? null
                      : () => context.read<BloqueioProvider>().desbloquearComBiometria(),
                  icon: const Icon(Icons.fingerprint, color: Colors.white),
                  label: const Text(
                    'Usar biometria',
                    style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
                  ),
                ),
              TextButton(
                onPressed: _sairDaConta,
                child: const Text(
                  'Esqueci o PIN / sair da conta',
                  style: TextStyle(fontFamily: 'Poppins', color: Colors.white54, fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _IndicadorPin extends StatelessWidget {
  final int preenchidos;
  final int total;

  const _IndicadorPin({required this.preenchidos, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final ativo = i < preenchidos;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ativo ? Colors.white : Colors.white24,
          ),
        );
      }),
    );
  }
}

class _TecladoNumerico extends StatelessWidget {
  final bool habilitado;
  final ValueChanged<String> onDigitar;
  final VoidCallback onApagar;

  const _TecladoNumerico({
    required this.habilitado,
    required this.onDigitar,
    required this.onApagar,
  });

  @override
  Widget build(BuildContext context) {
    const linhas = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'apagar'],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: linhas.map((linha) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: linha.map((tecla) {
              if (tecla.isEmpty) return const SizedBox(width: 64, height: 64);

              if (tecla == 'apagar') {
                return _BotaoTecla(
                  habilitado: habilitado,
                  onTap: onApagar,
                  child: const Icon(Icons.backspace_outlined, color: Colors.white),
                );
              }

              return _BotaoTecla(
                habilitado: habilitado,
                onTap: () => onDigitar(tecla),
                child: Text(
                  tecla,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _BotaoTecla extends StatelessWidget {
  final bool habilitado;
  final VoidCallback onTap;
  final Widget child;

  const _BotaoTecla({
    required this.habilitado,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: habilitado ? onTap : null,
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: 64,
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.08),
        ),
        child: child,
      ),
    );
  }
}
