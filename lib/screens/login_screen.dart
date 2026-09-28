import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../utils/page_transitions.dart';
import '../widgets/dindin_logo.dart';
import 'cadastro_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _senhaVisivel = false;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final sucesso = await auth.entrar(
      email: _emailController.text,
      senha: _senhaController.text,
    );

    if (!sucesso && mounted && auth.erro != null) {
      _mostrarErro(auth.erro!);
    }
  }

  Future<void> _entrarComGoogle() async {
    final auth = context.read<AuthProvider>();
    final sucesso = await auth.entrarComGoogle();

    if (!sucesso && mounted && auth.erro != null) {
      _mostrarErro(auth.erro!);
    }
  }

  Future<void> _esqueciSenha() async {
    if (_emailController.text.trim().isEmpty) {
      _mostrarErro('Digite seu e-mail no campo acima para redefinir a senha.');
      return;
    }

    final auth = context.read<AuthProvider>();
    final sucesso = await auth.redefinirSenha(_emailController.text);

    if (!mounted) return;

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enviamos um e-mail para redefinir sua senha.'),
        ),
      );
    } else if (auth.erro != null) {
      _mostrarErro(auth.erro!);
    }
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: context.cores.despesa),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cores = context.cores;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: DinDinLogo(markSize: 64)),
                const SizedBox(height: 12),
                Text(
                  'Entre para continuar',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: cores.textoSecundario),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cores.cardFundo,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: cores.sombra,
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'E-mail',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (valor) {
                            if (valor == null || valor.trim().isEmpty) {
                              return 'Digite seu e-mail';
                            }
                            if (!valor.contains('@') || !valor.contains('.')) {
                              return 'E-mail inválido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _senhaController,
                          obscureText: !_senhaVisivel,
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _senhaVisivel
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: cores.textoSecundario,
                              ),
                              onPressed: () =>
                                  setState(() => _senhaVisivel = !_senhaVisivel),
                            ),
                          ),
                          validator: (valor) {
                            if (valor == null || valor.isEmpty) {
                              return 'Digite sua senha';
                            }
                            return null;
                          },
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: auth.processando ? null : _esqueciSenha,
                            child: const Text('Esqueci minha senha'),
                          ),
                        ),
                        const SizedBox(height: 4),
                        FilledButton(
                          onPressed: auth.processando ? null : _entrar,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: auth.processando
                                ? const SizedBox(
                                    key: ValueKey('carregando'),
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Entrar', key: ValueKey('rotulo')),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                'ou',
                                style: TextStyle(color: cores.textoSecundario),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 18),
                        OutlinedButton.icon(
                          onPressed: auth.processando ? null : _entrarComGoogle,
                          icon: const Icon(Icons.g_mobiledata, size: 28),
                          label: const Text('Entrar com Google'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Não tem conta?',
                      style: TextStyle(color: cores.textoSecundario),
                    ),
                    TextButton(
                      onPressed: auth.processando
                          ? null
                          : () {
                              Navigator.of(context).push(
                                rotaComTransicaoSuave(const CadastroScreen()),
                              );
                            },
                      child: const Text('Cadastre-se'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
