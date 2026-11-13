import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../services/theme_service.dart';
import '../widgets/app_drawer.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final TextEditingController nome = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController telefone = TextEditingController();
  final TextEditingController senhaAtual = TextEditingController();
  final TextEditingController novaSenha = TextEditingController();
  final TextEditingController confirmarSenha = TextEditingController();

  int? id;
  DateTime? dataNascimento;

  Uint8List? fotoPerfilBytes;

  String moeda = 'BRL';
  String idioma = 'Português';

  String get chaveFoto => 'fotoPerfil_$id';

  bool carregando = true;
  bool salvando = false;
  bool mostrarSenhaAtual = false;
  bool mostrarNovaSenha = false;
  bool mostrarConfirmarSenha = false;

  @override
  void initState() {
    super.initState();
    carregar();
  }

  @override
  void dispose() {
    nome.dispose();
    email.dispose();
    telefone.dispose();
    senhaAtual.dispose();
    novaSenha.dispose();
    confirmarSenha.dispose();
    super.dispose();
  }

  Future<void> carregar() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      id = prefs.getInt('usuarioId');
      moeda = prefs.getString('moeda') ?? 'BRL';
      idioma = prefs.getString('idioma') ?? 'Português';

      final dataSalva = prefs.getString('dataNascimento');

      if (dataSalva != null && dataSalva.isNotEmpty) {
        dataNascimento = DateTime.tryParse(dataSalva);
      }

      // Carrega a foto salva em Base64.
      final fotoSalva = id != null
    ? prefs.getString(chaveFoto)
    : null;

      if (fotoSalva != null && fotoSalva.isNotEmpty) {
        try {
          fotoPerfilBytes = base64Decode(fotoSalva);
        } catch (e) {
          // Remove valores antigos que eram caminhos de arquivos.
          await prefs.remove(chaveFoto);
          fotoPerfilBytes = null;
          debugPrint('Foto antiga removida: $e');
        }
      }

      nome.text = prefs.getString('nomeUsuario') ?? '';
      email.text = prefs.getString('emailUsuario') ?? '';

      if (id != null) {
        try {
          final resposta = await ApiService.get('/usuarios/buscar/$id');

          if (resposta != null) {
            nome.text = resposta['nome']?.toString() ?? nome.text;
            email.text = resposta['email']?.toString() ?? email.text;

            telefone.text = resposta['Telefone']?.toString() ??
                resposta['telefone']?.toString() ??
                '';
          }
        } catch (e) {
          debugPrint('Erro ao buscar perfil na API: $e');
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar perfil: $e');
    }

    if (!mounted) return;

    setState(() {
      carregando = false;
    });
  }

  Future<void> escolherFoto() async {
    try {
      final imagem = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 500,
        maxHeight: 500,
      );

      if (imagem == null) return;

      final bytes = await imagem.readAsBytes();

      if (bytes.isEmpty) {
        throw Exception('A imagem selecionada está vazia.');
      }

      final prefs = await SharedPreferences.getInstance();

      // Salva os bytes em Base64 para funcionar na Web e no celular.
      if (id == null) {
     throw Exception('Usuário não identificado.');
     }

     await prefs.setString(chaveFoto, base64Encode(bytes));

      if (!mounted) return;

      setState(() {
        fotoPerfilBytes = bytes;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto de perfil alterada!'),
        ),
      );
    } catch (e) {
      debugPrint('Erro ao selecionar foto: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível selecionar a foto. Tente uma imagem menor.',
          ),
        ),
      );
    }
  }

  Future<void> removerFoto() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(chaveFoto);

      if (!mounted) return;

      setState(() {
        fotoPerfilBytes = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto de perfil removida.'),
        ),
      );
    } catch (e) {
      debugPrint('Erro ao remover foto: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível remover a foto.'),
        ),
      );
    }
  }

  Future<void> salvarPerfil() async {
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível identificar o usuário.'),
        ),
      );
      return;
    }

    if (nome.text.trim().isEmpty || email.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha o nome e o e-mail.'),
        ),
      );
      return;
    }

    setState(() {
      salvando = true;
    });

    try {
      await ApiService.put(
        '/usuarios/atualizar/$id',
        {
          'nome': nome.text.trim(),
          'email': email.text.trim(),
          'Telefone': telefone.text.trim(),
        },
      );

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('nomeUsuario', nome.text.trim());
      await prefs.setString('emailUsuario', email.text.trim());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil atualizado com sucesso!'),
        ),
      );
    } catch (e) {
      debugPrint('Erro ao salvar perfil: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível salvar as alterações.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          salvando = false;
        });
      }
    }
  }

  Future<void> escolherDataNascimento() async {
    final hoje = DateTime.now();

    final data = await showDatePicker(
      context: context,
      initialDate: dataNascimento ?? DateTime(hoje.year - 18),
      firstDate: DateTime(1900),
      lastDate: hoje,
      helpText: 'Selecione sua data de nascimento',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );

    if (data == null) return;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'dataNascimento',
      data.toIso8601String(),
    );

    if (!mounted) return;

    setState(() {
      dataNascimento = data;
    });
  }

  String formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');

    return '$dia/$mes/${data.year}';
  }

  Future<void> alterarMoeda(String? valor) async {
    if (valor == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('moeda', valor);

    if (!mounted) return;

    setState(() {
      moeda = valor;
    });
  }

  Future<void> alterarIdioma(String? valor) async {
    if (valor == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('idioma', valor);

    if (!mounted) return;

    setState(() {
      idioma = valor;
    });
  }

  Future<void> alterarTema(bool escuro) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('temaEscuro', escuro);

    temaNotifier.value = escuro ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> atualizarSenha() async {
    if (senhaAtual.text.isEmpty ||
        novaSenha.text.isEmpty ||
        confirmarSenha.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha todos os campos de senha.'),
        ),
      );
      return;
    }

    if (novaSenha.text != confirmarSenha.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('As senhas novas não são iguais.'),
        ),
      );
      return;
    }

    if (novaSenha.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A nova senha deve ter pelo menos 6 caracteres.',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'A alteração de senha precisa estar conectada à API.',
        ),
      ),
    );
  }

  Future<void> confirmarExclusao() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir conta'),
        content: const Text(
          'Tem certeza de que deseja solicitar a exclusão '
          'da sua conta? Essa ação não poderá ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'A exclusão precisa estar conectada à API.',
        ),
      ),
    );
  }

  Widget _secao(String titulo, List<Widget> filhos) {
    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...filhos,
          ],
        ),
      ),
    );
  }

  Widget _rotulo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7, top: 12),
      child: Text(
        texto,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _campo({
    required String titulo,
    required TextEditingController controller,
    TextInputType tipo = TextInputType.text,
    bool senha = false,
    bool mostrarSenha = false,
    VoidCallback? alternarSenha,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _rotulo(titulo),
        TextField(
          controller: controller,
          keyboardType: tipo,
          obscureText: senha && !mostrarSenha,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            suffixIcon: senha
                ? IconButton(
                    onPressed: alternarSenha,
                    icon: Icon(
                      mostrarSenha ? Icons.visibility_off : Icons.visibility,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _fotoPerfil() {
    return Column(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: const Color(0xFFE1F3EF),
          backgroundImage:
              fotoPerfilBytes != null ? MemoryImage(fotoPerfilBytes!) : null,
          child: fotoPerfilBytes == null
              ? Text(
                  nome.text.trim().isNotEmpty
                      ? nome.text.trim()[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: Color(0xFF155E63),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: escolherFoto,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Alterar foto'),
            ),
            if (fotoPerfilBytes != null)
              TextButton.icon(
                onPressed: removerFoto,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remover'),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      titulo: 'Configurações',
      body: carregando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _secao(
                  'Foto de perfil',
                  [
                    Center(
                      child: _fotoPerfil(),
                    ),
                  ],
                ),
                _secao(
                  'Dados pessoais',
                  [
                    _campo(
                      titulo: 'Nome completo',
                      controller: nome,
                    ),
                    _campo(
                      titulo: 'E-mail',
                      controller: email,
                      tipo: TextInputType.emailAddress,
                    ),
                    _campo(
                      titulo: 'Telefone',
                      controller: telefone,
                      tipo: TextInputType.phone,
                    ),
                    _rotulo('Data de nascimento'),
                    OutlinedButton.icon(
                      onPressed: escolherDataNascimento,
                      icon: const Icon(Icons.calendar_month),
                      label: Text(
                        dataNascimento == null
                            ? 'Selecionar data'
                            : formatarData(dataNascimento!),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: salvando ? null : salvarPerfil,
                        icon: salvando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          salvando ? 'Salvando...' : 'Salvar alterações',
                        ),
                      ),
                    ),
                  ],
                ),
                _secao(
                  'Aparência',
                  [
                    ValueListenableBuilder<ThemeMode>(
                      valueListenable: temaNotifier,
                      builder: (context, tema, child) {
                        return SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Modo escuro'),
                          subtitle: const Text(
                            'Ativar tema escuro no aplicativo',
                          ),
                          value: tema == ThemeMode.dark,
                          onChanged: alterarTema,
                        );
                      },
                    ),
                  ],
                ),
                _secao(
                  'Preferências',
                  [
                    _rotulo('Moeda'),
                    DropdownButtonFormField<String>(
                      value: moeda,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'BRL',
                          child: Text('Real brasileiro (BRL)'),
                        ),
                        DropdownMenuItem(
                          value: 'USD',
                          child: Text('Dólar americano (USD)'),
                        ),
                        DropdownMenuItem(
                          value: 'EUR',
                          child: Text('Euro (EUR)'),
                        ),
                      ],
                      onChanged: alterarMoeda,
                    ),
                    _rotulo('Idioma'),
                    DropdownButtonFormField<String>(
                      value: idioma,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Português',
                          child: Text('Português'),
                        ),
                        DropdownMenuItem(
                          value: 'English',
                          child: Text('English'),
                        ),
                        DropdownMenuItem(
                          value: 'Español',
                          child: Text('Español'),
                        ),
                      ],
                      onChanged: alterarIdioma,
                    ),
                  ],
                ),
                _secao(
                  'Segurança',
                  [
                    _campo(
                      titulo: 'Senha atual',
                      controller: senhaAtual,
                      senha: true,
                      mostrarSenha: mostrarSenhaAtual,
                      alternarSenha: () {
                        setState(() {
                          mostrarSenhaAtual = !mostrarSenhaAtual;
                        });
                      },
                    ),
                    _campo(
                      titulo: 'Nova senha',
                      controller: novaSenha,
                      senha: true,
                      mostrarSenha: mostrarNovaSenha,
                      alternarSenha: () {
                        setState(() {
                          mostrarNovaSenha = !mostrarNovaSenha;
                        });
                      },
                    ),
                    _campo(
                      titulo: 'Confirmar nova senha',
                      controller: confirmarSenha,
                      senha: true,
                      mostrarSenha: mostrarConfirmarSenha,
                      alternarSenha: () {
                        setState(() {
                          mostrarConfirmarSenha = !mostrarConfirmarSenha;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: atualizarSenha,
                        icon: const Icon(Icons.lock_outline),
                        label: const Text('Atualizar senha'),
                      ),
                    ),
                  ],
                ),
                _secao(
                  'Conta',
                  [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: confirmarExclusao,
                        icon: const Icon(
                          Icons.delete_forever_outlined,
                          color: Colors.red,
                        ),
                        label: const Text(
                          'Excluir conta',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
