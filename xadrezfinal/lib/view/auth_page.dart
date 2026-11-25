import 'package:flutter/material.dart';
import '../service/auth_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final pass = TextEditingController();
  final confirmPass = TextEditingController();
  final name = TextEditingController();
  bool register = false;
  bool busy = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    email.dispose();
    pass.dispose();
    confirmPass.dispose();
    name.dispose();
    super.dispose();
  }

  Future<void> run() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      if (register) {
        await AuthService().register(name.text, email.text, pass.text);
      } else {
        await AuthService().login(email.text, pass.text);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível autenticar: $e')),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> resetPassword() async {
    if (email.text.trim().isEmpty || !email.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um e-mail válido primeiro.')),
      );
      return;
    }
    try {
      await AuthService().reset(email.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E-mail de recuperação enviado.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar recuperação: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sports_esports,
                        size: 76, color: Color(0xFF81B64C)),
                    const SizedBox(height: 12),
                    const Text(
                      'Chess.com App',
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 28),
                    if (register) ...[
                      TextFormField(
                        controller: name,
                        textCapitalization: TextCapitalization.words,
                        decoration:
                            const InputDecoration(labelText: 'Nome completo'),
                        validator: (value) => value == null || value.trim().isEmpty
                            ? 'Informe seu nome.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      validator: (value) => value == null ||
                              !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                  .hasMatch(value.trim())
                          ? 'Informe um e-mail válido.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: pass,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                              () => obscurePassword = !obscurePassword),
                          icon: Icon(obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off),
                        ),
                      ),
                      validator: (value) => value == null || value.length < 6
                          ? 'A senha precisa ter pelo menos 6 caracteres.'
                          : null,
                    ),
                    if (register) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: confirmPass,
                        obscureText: true,
                        decoration: const InputDecoration(
                            labelText: 'Confirmar senha'),
                        validator: (value) => value != pass.text
                            ? 'As senhas não coincidem.'
                            : null,
                      ),
                    ],
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: busy ? null : run,
                        child: busy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(register ? 'Criar conta' : 'Entrar'),
                      ),
                    ),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => setState(() {
                                register = !register;
                                _formKey.currentState?.reset();
                              }),
                      child: Text(register ? 'Já tenho conta' : 'Criar uma conta'),
                    ),
                    if (!register)
                      TextButton(
                        onPressed: busy ? null : resetPassword,
                        child: const Text('Esqueci minha senha'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
