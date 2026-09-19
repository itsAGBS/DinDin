import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/bloqueio_provider.dart';
import '../theme/app_colors.dart';

/// Tela de configuração da proteção de acesso. Acessada a partir do dashboard (ícone de cadeado na AppBar).

class ConfigurarBloqueioScreen extends StatelessWidget {
  const ConfigurarBloqueioScreen({super.key});

  Future<void> _ativarBloqueio(BuildContext context) async {
    final pin = await _pedirNovoPin(context);
    if (pin == null || !context.mounted) return;
    await context.read<BloqueioProvider>().ativarComPin(pin);
  }

  Future<void> _desativarBloqueio(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Desativar proteção?'),
        content: const Text(
          'O app deixará de pedir biometria/PIN ao abrir. Você pode '
          'reativar quando quiser.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Desativar'),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      await context.read<BloqueioProvider>().desativarBloqueio();
    }
  }

  Future<void> _alterarPin(BuildContext context) async {
    final pin = await _pedirNovoPin(context);
    if (pin == null || !context.mounted) return;
    await context.read<BloqueioProvider>().alterarPin(pin);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN atualizado.')),
      );
    }
  }

  /// Pede um PIN de 4 dígitos duas vezes (criação + confirmação).
  
  Future<String?> _pedirNovoPin(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _DialogoNovoPin(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bloqueio = context.watch<BloqueioProvider>();

    return Scaffold(
      backgroundColor: AppColors.fundo,
      appBar: AppBar(title: const Text('Segurança')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SwitchListTile(
              title: const Text('Bloqueio ao abrir o app'),
              subtitle: const Text(
                'Pede biometria/PIN sempre que o DinDin é aberto',
              ),
              value: bloqueio.bloqueioAtivado,
              onChanged: (ativar) =>
                  ativar ? _ativarBloqueio(context) : _desativarBloqueio(context),
            ),
          ),
          if (bloqueio.bloqueioAtivado) ...[
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  if (bloqueio.biometriaDisponivelNoAparelho)
                    SwitchListTile(
                      title: const Text('Usar biometria'),
                      subtitle: const Text(
                        'Digital ou reconhecimento facial do aparelho',
                      ),
                      value: bloqueio.biometriaAtivada,
                      onChanged: (ativar) =>
                          context.read<BloqueioProvider>().definirBiometriaAtivada(ativar),
                    )
                  else
                    const ListTile(
                      title: Text('Biometria indisponível'),
                      subtitle: Text(
                        'Este aparelho não tem biometria cadastrada no sistema',
                      ),
                    ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.pin_outlined),
                    title: const Text('Alterar PIN'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _alterarPin(context),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Dialogo que pede um PIN de 4 dígitos e a confirmação,
/// só fechando com sucesso quando as duas digitações são idênticas.
class _DialogoNovoPin extends StatefulWidget {
  const _DialogoNovoPin();

  @override
  State<_DialogoNovoPin> createState() => _DialogoNovoPinState();
}

class _DialogoNovoPinState extends State<_DialogoNovoPin> {
  final _pinController = TextEditingController();
  final _confirmacaoController = TextEditingController();
  String? _erro;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmacaoController.dispose();
    super.dispose();
  }

  void _confirmar() {
    final pin = _pinController.text;
    final confirmacao = _confirmacaoController.text;

    if (pin.length != 4) {
      setState(() => _erro = 'O PIN deve ter 4 dígitos.');
      return;
    }
    if (pin != confirmacao) {
      setState(() => _erro = 'Os PINs digitados não são iguais.');
      return;
    }

    Navigator.of(context).pop(pin);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Definir PIN'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Novo PIN (4 dígitos)'),
          ),
          TextField(
            controller: _confirmacaoController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Confirme o PIN'),
          ),
          if (_erro != null) ...[
            const SizedBox(height: 4),
            Text(_erro!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _confirmar,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
