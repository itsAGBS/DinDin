import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/moeda.dart';
import '../providers/auth_provider.dart';
import '../providers/preferencias_provider.dart';
import '../theme/app_colors.dart';
import 'configurar_bloqueio_screen.dart';
import 'login_screen.dart';

/// Tela de configurações do usuário, acessada a partir do ícone de
/// perfil no dashboard. Reúne: foto e nome, e-mail cadastrado,
/// preferências do app, troca de senha, acesso à segurança (bloqueio) e
/// logout.
class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      appBar: AppBar(
        backgroundColor: AppColors.fundo,
        elevation: 0,
        title: const Text(
          'Configurações',
          style: TextStyle(fontFamily: 'Poppins', color: Colors.black87),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: const [
          _CabecalhoPerfil(),
          SizedBox(height: 24),
          _SecaoPreferencias(),
          SizedBox(height: 16),
          _SecaoConta(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Cabeçalho: foto, nome (editável) e e-mail
// ---------------------------------------------------------------------

class _CabecalhoPerfil extends StatelessWidget {
  const _CabecalhoPerfil();

  Future<void> _trocarFoto(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? arquivo = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (arquivo == null || !context.mounted) return;

    final sucesso =
        await context.read<AuthProvider>().atualizarFoto(File(arquivo.path));

    if (!sucesso && context.mounted) {
      final erro = context.read<AuthProvider>().erro;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro ?? 'Não foi possível atualizar a foto.')),
      );
    }
  }

  Future<void> _editarNome(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final controlador = TextEditingController(text: auth.user?.displayName ?? '');

    final novoNome = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar nome'),
        content: TextField(
          controller: controlador,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nome'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controlador.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (novoNome == null || novoNome.isEmpty || !context.mounted) return;

    final sucesso = await auth.atualizarNome(novoNome);
    if (!sucesso && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.erro ?? 'Não foi possível atualizar o nome.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final nome = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!
        : 'Sem nome cadastrado';
    final iniciais = nome == 'Sem nome cadastrado'
        ? '?'
        : nome.trim().split(RegExp(r'\s+')).take(2).map((p) => p[0]).join().toUpperCase();

    ImageProvider? imagemAvatar;
    if (auth.fotoLocalPath != null) {
      imagemAvatar = FileImage(File(auth.fotoLocalPath!));
    } else if (user?.photoURL != null) {
      imagemAvatar = NetworkImage(user!.photoURL!);
    }

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.destaque,
              backgroundImage: imagemAvatar,
              child: imagemAvatar == null
                  ? Text(
                      iniciais,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            Positioned(
              right: -4,
              bottom: -4,
              child: InkWell(
                onTap: auth.processando ? null : () => _trocarFoto(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.acao,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.fundo, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => _editarNome(context),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  nome,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.edit, size: 16, color: Colors.black45),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user?.email ?? '',
          style: const TextStyle(fontFamily: 'Poppins', color: Colors.black54, fontSize: 13),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Preferências do app
// ---------------------------------------------------------------------

class _SecaoPreferencias extends StatelessWidget {
  const _SecaoPreferencias();

  Future<void> _escolherMoeda(BuildContext context) async {
    final preferencias = context.read<PreferenciasProvider>();
    final escolhida = await showModalBottomSheet<Moeda>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: Moeda.values
              .map((m) => ListTile(
                    title: Text(m.rotulo, style: const TextStyle(fontFamily: 'Poppins')),
                    trailing: m == preferencias.moeda ? const Icon(Icons.check, color: AppColors.acao) : null,
                    onTap: () => Navigator.of(context).pop(m),
                  ))
              .toList(),
        ),
      ),
    );

    if (escolhida != null) {
      await preferencias.definirMoeda(escolhida);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preferencias = context.watch<PreferenciasProvider>();

    return _CartaoSecao(
      titulo: 'Preferências',
      filhos: [
        SwitchListTile(
          title: const Text('Modo escuro'),
          subtitle: const Text('Usar tema escuro no app'),
          value: preferencias.modoEscuro,
          onChanged: preferencias.definirModoEscuro,
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.attach_money),
          title: const Text('Moeda'),
          subtitle: Text(preferencias.moeda.rotulo),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _escolherMoeda(context),
        ),
        const Divider(height: 1),
        SwitchListTile(
          title: const Text('Resumo mensal automático'),
          subtitle: const Text('Receber um resumo dos seus gastos todo mês'),
          value: preferencias.resumoMensalAutomatico,
          onChanged: preferencias.definirResumoMensalAutomatico,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Conta: segurança, senha e logout
// ---------------------------------------------------------------------

class _SecaoConta extends StatelessWidget {
  const _SecaoConta();

  Future<void> _alterarSenha(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => const _DialogoAlterarSenha(),
    );
  }

  Future<void> _sair(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sair', style: TextStyle(color: AppColors.despesa)),
          ),
        ],
      ),
    );

    if (confirmar != true || !context.mounted) return;

    await context.read<AuthProvider>().sair();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return _CartaoSecao(
      titulo: 'Conta',
      filhos: [
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: const Text('Segurança (biometria/PIN)'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ConfigurarBloqueioScreen()),
          ),
        ),
        if (auth.temSenha) ...[
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.password_outlined),
            title: const Text('Alterar senha'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _alterarSenha(context),
          ),
        ] else ...[
          const Divider(height: 1),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Login via Google'),
            subtitle: Text('A senha da sua conta é gerenciada pelo Google'),
          ),
        ],
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.logout, color: AppColors.despesa),
          title: const Text('Sair da conta', style: TextStyle(color: AppColors.despesa)),
          onTap: () => _sair(context),
        ),
      ],
    );
  }
}

class _DialogoAlterarSenha extends StatefulWidget {
  const _DialogoAlterarSenha();

  @override
  State<_DialogoAlterarSenha> createState() => _DialogoAlterarSenhaState();
}

class _DialogoAlterarSenhaState extends State<_DialogoAlterarSenha> {
  final _senhaAtualController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmacaoController = TextEditingController();
  String? _erroLocal;

  @override
  void dispose() {
    _senhaAtualController.dispose();
    _novaSenhaController.dispose();
    _confirmacaoController.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final novaSenha = _novaSenhaController.text;

    if (novaSenha.length < 6) {
      setState(() => _erroLocal = 'A nova senha precisa ter pelo menos 6 caracteres.');
      return;
    }
    if (novaSenha != _confirmacaoController.text) {
      setState(() => _erroLocal = 'As senhas novas não são iguais.');
      return;
    }

    setState(() => _erroLocal = null);

    final auth = context.read<AuthProvider>();
    final sucesso = await auth.alterarSenha(
      senhaAtual: _senhaAtualController.text,
      novaSenha: novaSenha,
    );

    if (!mounted) return;
    if (sucesso) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha atualizada.')),
      );
    } else {
      setState(() => _erroLocal = auth.erro ?? 'Não foi possível alterar a senha.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final processando = context.watch<AuthProvider>().processando;

    return AlertDialog(
      title: const Text('Alterar senha'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _senhaAtualController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Senha atual'),
          ),
          TextField(
            controller: _novaSenhaController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Nova senha'),
          ),
          TextField(
            controller: _confirmacaoController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Confirme a nova senha'),
          ),
          if (_erroLocal != null) ...[
            const SizedBox(height: 8),
            Text(_erroLocal!, style: const TextStyle(color: AppColors.despesa, fontSize: 12)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: processando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: processando ? null : _confirmar,
          child: processando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Cartão reutilizável de seção (título + lista de opções)
// ---------------------------------------------------------------------

class _CartaoSecao extends StatelessWidget {
  final String titulo;
  final List<Widget> filhos;

  const _CartaoSecao({required this.titulo, required this.filhos});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            titulo,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: Column(children: filhos),
        ),
      ],
    );
  }
}
