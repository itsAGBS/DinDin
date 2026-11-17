import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/foto_perfil_provider.dart';
import '../providers/preferencias_provider.dart';
import '../theme/app_colors.dart';
import '../utils/moeda.dart';
import '../widgets/avatar_usuario.dart';

enum _AcaoFoto { camera, galeria, remover }

class ConfiguracoesScreen extends StatelessWidget {
  const ConfiguracoesScreen({super.key});

  void _avisar(BuildContext context, String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Future<void> _escolherFoto(BuildContext context) async {
    final foto = context.read<FotoPerfilProvider>();

    final acao = await showModalBottomSheet<_AcaoFoto>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tirar foto'),
              onTap: () => Navigator.pop(sheetContext, _AcaoFoto.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () => Navigator.pop(sheetContext, _AcaoFoto.galeria),
            ),
            if (foto.temFoto)
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: sheetContext.cores.despesa,
                ),
                title: Text(
                  'Remover foto',
                  style: TextStyle(color: sheetContext.cores.despesa),
                ),
                onTap: () => Navigator.pop(sheetContext, _AcaoFoto.remover),
              ),
          ],
        ),
      ),
    );

    if (acao == null || !context.mounted) return;

    final bool ok;
    switch (acao) {
      case _AcaoFoto.camera:
        ok = await foto.escolher(ImageSource.camera);
      case _AcaoFoto.galeria:
        ok = await foto.escolher(ImageSource.gallery);
      case _AcaoFoto.remover:
        ok = await foto.remover();
    }

    if (!ok && context.mounted) {
      _avisar(context, 'Não foi possível atualizar a foto. Tente novamente.');
    }
  }

  Future<void> _editarNome(BuildContext context) async {
    final salvou = await showDialog<bool>(
      context: context,
      builder: (_) => const _DialogoEditarNome(),
    );
    if (salvou == true && context.mounted) {
      _avisar(context, 'Nome atualizado.');
    }
  }

  Future<void> _alterarSenha(BuildContext context) async {
    final salvou = await showDialog<bool>(
      context: context,
      builder: (_) => const _DialogoAlterarSenha(),
    );
    if (salvou == true && context.mounted) {
      _avisar(context, 'Senha alterada com sucesso.');
    }
  }

  Future<void> _escolherMoeda(BuildContext context) async {
    final prefs = context.read<PreferenciasProvider>();

    final escolhida = await showModalBottomSheet<Moeda>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final moeda in Moeda.values)
              ListTile(
                title: Text('${moeda.nome} (${moeda.simbolo})'),
                subtitle: Text('Exemplo: ${moeda.formatar(1234.5)}'),
                trailing: moeda == prefs.moeda
                    ? Icon(Icons.check, color: sheetContext.cores.azul)
                    : null,
                onTap: () => Navigator.pop(sheetContext, moeda),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text(
                'A moeda muda apenas o símbolo e o formato exibidos. '
                'Os valores já lançados não são convertidos.',
                style: TextStyle(
                  fontSize: 12,
                  color: sheetContext.cores.textoSecundario,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (escolhida != null) {
      await prefs.definirMoeda(escolhida);
    }
  }

  Future<void> _sair(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text(
          'Você precisará entrar novamente para acessar o DinDin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: dialogContext.cores.despesa,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmar != true || !context.mounted) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await context.read<AuthProvider>().sair();
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Não foi possível sair. Tente novamente.')),
      );
      return;
    }

    // O AuthGate já troca a home para o login, mas telas empilhadas por cima
    // (como esta) continuariam visíveis. Voltamos até a raiz.
    navigator.popUntil((rota) => rota.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final auth = context.watch<AuthProvider>();
    final prefs = context.watch<PreferenciasProvider>();
    final foto = context.watch<FotoPerfilProvider>();

    final nome = auth.user?.displayName?.trim() ?? '';
    final email = auth.user?.email ?? 'Não informado';
    final podeAlterarSenha = auth.possuiSenha;

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // ---------- Cabeçalho do perfil ----------
            Center(
              child: Column(
                children: [
                  Semantics(
                    button: true,
                    label: 'Alterar foto de perfil',
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: foto.processando ? null : () => _escolherFoto(context),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const AvatarUsuario(raio: 48),
                          if (foto.processando)
                            const SizedBox(
                              width: 96,
                              height: 96,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: cores.azul,
                                shape: BoxShape.circle,
                                border: Border.all(color: cores.fundo, width: 2),
                              ),
                              child: const Icon(
                                Icons.photo_camera,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    nome.isEmpty ? 'Sem nome' : nome,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: cores.textoPrincipal,
                    ),
                  ),
                  Text(
                    email,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: cores.textoSecundario,
                    ),
                  ),
                ],
              ),
            ),

            // ---------- Perfil ----------
            const _TituloSecao('Perfil'),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Nome'),
                    subtitle: Text(nome.isEmpty ? 'Toque para adicionar' : nome),
                    trailing: const Icon(Icons.edit_outlined, size: 20),
                    onTap: () => _editarNome(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.mail_outline),
                    title: const Text('E-mail'),
                    subtitle: Text(email),
                  ),
                ],
              ),
            ),

            // ---------- Preferências ----------
            const _TituloSecao('Preferências'),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.dark_mode_outlined,
                                color: cores.textoSecundario),
                            const SizedBox(width: 16),
                            Text(
                              'Modo escuro',
                              style: TextStyle(
                                fontSize: 16,
                                color: cores.textoPrincipal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<ThemeMode>(
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment(
                                value: ThemeMode.system,
                                label: Text('Sistema'),
                              ),
                              ButtonSegment(
                                value: ThemeMode.light,
                                label: Text('Desligado'),
                              ),
                              ButtonSegment(
                                value: ThemeMode.dark,
                                label: Text('Ligado'),
                              ),
                            ],
                            selected: {prefs.themeMode},
                            onSelectionChanged: (selecao) => context
                                .read<PreferenciasProvider>()
                                .definirTema(selecao.first),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.payments_outlined),
                    title: const Text('Moeda'),
                    subtitle: Text('${prefs.moeda.nome} (${prefs.moeda.simbolo})'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _escolherMoeda(context),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.event_note_outlined),
                    title: const Text('Resumo mensal automático'),
                    subtitle: const Text(
                      'Ao abrir o app em um novo mês, mostra o resumo do mês anterior',
                    ),
                    value: prefs.resumoMensalAtivo,
                    onChanged: (ativo) => context
                        .read<PreferenciasProvider>()
                        .definirResumoMensal(ativo),
                  ),
                ],
              ),
            ),

            // ---------- Conta ----------
            const _TituloSecao('Conta'),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    enabled: podeAlterarSenha,
                    leading: const Icon(Icons.lock_reset_outlined),
                    title: const Text('Alterar senha'),
                    subtitle: podeAlterarSenha
                        ? null
                        : const Text('Sua conta usa o login com o Google'),
                    trailing: podeAlterarSenha ? const Icon(Icons.chevron_right) : null,
                    onTap: podeAlterarSenha ? () => _alterarSenha(context) : null,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.logout, color: cores.despesa),
                    title: Text(
                      'Sair da conta',
                      style: TextStyle(color: cores.despesa),
                    ),
                    onTap: () => _sair(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TituloSecao extends StatelessWidget {
  const _TituloSecao(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
      child: Text(
        texto,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: context.cores.textoSecundario,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Diálogo: editar nome
// ---------------------------------------------------------------------------

class _DialogoEditarNome extends StatefulWidget {
  const _DialogoEditarNome();

  @override
  State<_DialogoEditarNome> createState() => _DialogoEditarNomeState();
}

class _DialogoEditarNomeState extends State<_DialogoEditarNome> {
  late final TextEditingController _controller;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    final nomeAtual = context.read<AuthProvider>().user?.displayName ?? '';
    _controller = TextEditingController(text: nomeAtual);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final nome = _controller.text.trim();
    if (nome.isEmpty) {
      setState(() => _erro = 'Digite seu nome.');
      return;
    }

    setState(() {
      _salvando = true;
      _erro = null;
    });

    final erro = await context.read<AuthProvider>().atualizarNome(nome);
    if (!mounted) return;

    if (erro != null) {
      setState(() {
        _salvando = false;
        _erro = erro;
      });
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar nome'),
      content: TextField(
        controller: _controller,
        enabled: !_salvando,
        autofocus: true,
        maxLength: 40,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _salvar(),
        decoration: InputDecoration(
          labelText: 'Nome',
          errorText: _erro,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _salvando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _salvando ? null : _salvar,
          child: _salvando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Diálogo: alterar senha
// ---------------------------------------------------------------------------

class _DialogoAlterarSenha extends StatefulWidget {
  const _DialogoAlterarSenha();

  @override
  State<_DialogoAlterarSenha> createState() => _DialogoAlterarSenhaState();
}

class _DialogoAlterarSenhaState extends State<_DialogoAlterarSenha> {
  final _atualController = TextEditingController();
  final _novaController = TextEditingController();
  final _confirmacaoController = TextEditingController();

  bool _mostrarSenhas = false;
  bool _salvando = false;
  String? _erro;

  @override
  void dispose() {
    _atualController.dispose();
    _novaController.dispose();
    _confirmacaoController.dispose();
    super.dispose();
  }

  String? _validar() {
    final atual = _atualController.text;
    final nova = _novaController.text;

    if (atual.isEmpty) return 'Digite sua senha atual.';
    if (nova.length < 6) return 'A nova senha precisa ter pelo menos 6 caracteres.';
    if (nova == atual) return 'A nova senha deve ser diferente da atual.';
    if (nova != _confirmacaoController.text) return 'As senhas não são iguais.';
    return null;
  }

  Future<void> _salvar() async {
    final problema = _validar();
    if (problema != null) {
      setState(() => _erro = problema);
      return;
    }

    setState(() {
      _salvando = true;
      _erro = null;
    });

    final erro = await context.read<AuthProvider>().alterarSenha(
          senhaAtual: _atualController.text,
          novaSenha: _novaController.text,
        );
    if (!mounted) return;

    if (erro != null) {
      setState(() {
        _salvando = false;
        _erro = erro;
      });
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return AlertDialog(
      scrollable: true,
      title: const Text('Alterar senha'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _atualController,
            enabled: !_salvando,
            obscureText: !_mostrarSenhas,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(labelText: 'Senha atual'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _novaController,
            enabled: !_salvando,
            obscureText: !_mostrarSenhas,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(labelText: 'Nova senha'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmacaoController,
            enabled: !_salvando,
            obscureText: !_mostrarSenhas,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _salvar(),
            decoration: const InputDecoration(labelText: 'Confirme a nova senha'),
          ),
          const SizedBox(height: 4),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            title: const Text('Mostrar senhas'),
            value: _mostrarSenhas,
            onChanged: _salvando
                ? null
                : (valor) => setState(() => _mostrarSenhas = valor ?? false),
          ),
          if (_erro != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _erro!,
                  style: TextStyle(color: cores.despesa, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _salvando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _salvando ? null : _salvar,
          child: _salvando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }
}
