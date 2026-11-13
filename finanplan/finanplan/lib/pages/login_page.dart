import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'cadastro_page.dart';
import 'dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final senha = TextEditingController();
  bool carregando = false;
  bool esconderSenha = true;

  Future<void> entrar() async {
    if (email.text.isEmpty || senha.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha email e senha.')));
      return;
    }
    setState(() => carregando = true);
    try {
      final dados = await ApiService.post('/usuarios/login', {'email': email.text.trim(), 'senha': senha.text});
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('usuarioId', dados['usuario']['id']);
      await prefs.setInt('controleId', dados['controleId']);
      await prefs.setString('nomeUsuario', dados['usuario']['nome']);
      await prefs.setString('emailUsuario', dados['usuario']['email']);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const DashboardPage()), (_) => false);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF155E63), Color(0xFF1F647B)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(children: [
                    const Icon(Icons.account_balance_wallet, size: 65, color: Color(0xFF155E63)),
                    const SizedBox(height: 12),
                    const Text('Finanplan', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                    const Text('Controle suas finanças', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 28),
                    TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email), border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    TextField(controller: senha, obscureText: esconderSenha, decoration: InputDecoration(labelText: 'Senha', prefixIcon: const Icon(Icons.lock), border: const OutlineInputBorder(), suffixIcon: IconButton(icon: Icon(Icons.visibility), onPressed: () => setState(() => esconderSenha = !esconderSenha)))),
                    const SizedBox(height: 20),
                    SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: carregando ? null : entrar, child: carregando ? const CircularProgressIndicator() : const Text('ENTRAR'))),
                    const SizedBox(height: 16),
                    TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CadastroPage())), child: const Text('Ainda não tenho cadastro')),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
