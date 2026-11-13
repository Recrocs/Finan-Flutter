import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/meta.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class MetasPage extends StatefulWidget {
  const MetasPage({super.key});

  @override
  State<MetasPage> createState() => _MetasPageState();
}

class _MetasPageState extends State<MetasPage> {
  List<Meta> metas = [];
  bool carregando = true;

  final moeda = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$ ',
  );

  static const verde = Color(0xFF155E63);
  static const verdeEscuro = Color(0xFF124D40);
  static const verdeClaro = Color(0xFF218C83);

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final controleId = prefs.getInt('controleId');

      if (controleId == null) {
        throw Exception(
          'Usuário não identificado. Faça login novamente.',
        );
      }

      final dados = await ApiService.get(
        '/metas/listar?controleId=$controleId',
      );

      final novasMetas = (dados as List).map((e) => Meta.fromJson(e)).toList();

      if (!mounted) return;

      setState(() {
        metas = novasMetas;
        carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        carregando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  double get totalGuardado {
    return metas.fold<double>(
      0,
      (total, meta) => total + meta.valorAtual,
    );
  }

  double get totalAlvo {
    return metas.fold<double>(
      0,
      (total, meta) => total + meta.valorAlvo,
    );
  }

  int get quantidadeConcluidas {
    return metas.where((meta) {
      return meta.valorAlvo > 0 && meta.valorAtual >= meta.valorAlvo;
    }).length;
  }

  int get quantidadeAtivas {
    return metas.length - quantidadeConcluidas;
  }

  Future<void> adicionar() async {
    final titulo = TextEditingController();
    final descricao = TextEditingController();
    final alvo = TextEditingController();
    final guardado = TextEditingController(text: '0');
    final dataController = TextEditingController();
    final iconeController = TextEditingController();

    DateTime? dataLimite;

    final formulario = GlobalKey<FormState>();

    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, atualizarDialogo) {
            final escuro = Theme.of(context).brightness == Brightness.dark;

            final corTexto = escuro ? Colors.white : const Color(0xFF263238);

            final corBorda =
                escuro ? const Color(0xFF424A50) : const Color(0xFFE0E7E9);

            final largura = MediaQuery.of(context).size.width;
            final larguraDialogo = largura < 600 ? largura - 32 : 680.0;

            InputDecoration decoracao(String hint) {
              return InputDecoration(
                hintText: hint,
                filled: true,
                fillColor:
                    escuro ? const Color(0xFF20282C) : const Color(0xFFF8FAFB),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 15,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: corBorda),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: corBorda),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: verde,
                    width: 1.5,
                  ),
                ),
              );
            }

            Widget campo({
              required String rotulo,
              required Widget input,
              bool opcional = false,
            }) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Text(
                          rotulo,
                          style: TextStyle(
                            color: corTexto,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        if (opcional) ...[
                          const SizedBox(width: 5),
                          const Text(
                            '(opcional)',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  input,
                ],
              );
            }

            Widget linhaCampos(
              Widget primeiro,
              Widget segundo,
              double larguraDisponivel,
            ) {
              if (larguraDisponivel < 430) {
                return Column(
                  children: [
                    primeiro,
                    const SizedBox(height: 18),
                    segundo,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: primeiro),
                  const SizedBox(width: 16),
                  Expanded(child: segundo),
                ],
              );
            }

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 20,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: corBorda),
              ),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: larguraDialogo,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.9,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          24,
                          20,
                          14,
                          18,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Nova Meta',
                                style: TextStyle(
                                  color: corTexto,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Fechar',
                              onPressed: () {
                                Navigator.pop(dialogContext, false);
                              },
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: corBorda),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: formulario,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                campo(
                                  rotulo: 'Título',
                                  input: TextFormField(
                                    controller: titulo,
                                    decoration: decoracao(
                                      'Ex: Reserva de Emergência',
                                    ),
                                    validator: (valor) {
                                      if (valor == null ||
                                          valor.trim().isEmpty) {
                                        return 'Informe o título.';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 18),
                                campo(
                                  rotulo: 'Descrição',
                                  opcional: true,
                                  input: TextFormField(
                                    controller: descricao,
                                    decoration: decoracao(
                                      'Ex: Para imprevistos',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final primeiro = campo(
                                      rotulo: 'Valor alvo (R\$)',
                                      input: TextFormField(
                                        controller: alvo,
                                        keyboardType: const TextInputType
                                            .numberWithOptions(
                                          decimal: true,
                                        ),
                                        decoration: decoracao('0,00'),
                                        validator: (valor) {
                                          final numero = double.tryParse(
                                            (valor ?? '')
                                                .trim()
                                                .replaceAll('.', '')
                                                .replaceAll(',', '.'),
                                          );

                                          if (numero == null || numero <= 0) {
                                            return 'Informe um valor válido.';
                                          }
                                          return null;
                                        },
                                      ),
                                    );

                                    final segundo = campo(
                                      rotulo: 'Valor já guardado (R\$)',
                                      input: TextFormField(
                                        controller: guardado,
                                        keyboardType: const TextInputType
                                            .numberWithOptions(
                                          decimal: true,
                                        ),
                                        decoration: decoracao('0,00'),
                                        validator: (valor) {
                                          final numero = double.tryParse(
                                            (valor ?? '')
                                                .trim()
                                                .replaceAll('.', '')
                                                .replaceAll(',', '.'),
                                          );

                                          if (numero == null || numero < 0) {
                                            return 'Informe um valor válido.';
                                          }

                                          final valorAlvo = double.tryParse(
                                            alvo.text
                                                .trim()
                                                .replaceAll('.', '')
                                                .replaceAll(',', '.'),
                                          );

                                          if (valorAlvo != null &&
                                              numero > valorAlvo) {
                                            return 'Não pode superar o alvo.';
                                          }

                                          return null;
                                        },
                                      ),
                                    );

                                    return linhaCampos(
                                      primeiro,
                                      segundo,
                                      constraints.maxWidth,
                                    );
                                  },
                                ),
                                const SizedBox(height: 18),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final primeiro = campo(
                                      rotulo: 'Data limite',
                                      opcional: true,
                                      input: InkWell(
                                        onTap: () async {
                                          final escolhida =
                                              await showDatePicker(
                                            context: context,
                                            initialDate:
                                                dataLimite ?? DateTime.now(),
                                            firstDate: DateTime.now().subtract(
                                              const Duration(days: 1),
                                            ),
                                            lastDate: DateTime(2100),
                                          );

                                          if (escolhida != null) {
                                            atualizarDialogo(() {
                                              dataLimite = escolhida;
                                              dataController.text =
                                                  DateFormat('dd/MM/yyyy')
                                                      .format(escolhida);
                                            });
                                          }
                                        },
                                        child: IgnorePointer(
                                          child: TextFormField(
                                            controller: dataController,
                                            decoration: decoracao(
                                              'dd/mm/aaaa',
                                            ).copyWith(
                                              suffixIcon: const Icon(
                                                Icons.calendar_month_outlined,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );

                                    final segundo = campo(
                                      rotulo: 'Ícone (Material Icons)',
                                      opcional: true,
                                      input: TextFormField(
                                        controller: iconeController,
                                        decoration: decoracao(
                                          'Ex: flight, home, shield',
                                        ),
                                      ),
                                    );

                                    return linhaCampos(
                                      primeiro,
                                      segundo,
                                      constraints.maxWidth,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Divider(height: 1, color: corBorda),
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                Navigator.pop(dialogContext, false);
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 15,
                                ),
                                side: BorderSide(color: corBorda),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Cancelar'),
                            ),
                            FilledButton.icon(
                              onPressed: () {
                                if (formulario.currentState!.validate()) {
                                  Navigator.pop(dialogContext, true);
                                }
                              },
                              icon: const Icon(Icons.check, size: 19),
                              label: const Text('Salvar Meta'),
                              style: FilledButton.styleFrom(
                                backgroundColor: verdeEscuro,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (resultado == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final controleId = prefs.getInt('controleId');

        if (controleId == null) {
          throw Exception('Faça login novamente.');
        }

        double converterValor(String texto) {
          return double.parse(
            texto.trim().replaceAll('.', '').replaceAll(',', '.'),
          );
        }

        await ApiService.post(
          '/metas/cadastrar',
          {
            'titulo': titulo.text.trim(),
            'descricao': descricao.text.trim(),
            'valorAlvo': converterValor(alvo.text),
            'valorAtual': converterValor(guardado.text),
            'controleId': controleId,
          },
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meta cadastrada com sucesso!'),
          ),
        );

        await carregar();
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
            ),
          ),
        );
      }
    }

    titulo.dispose();
    descricao.dispose();
    alvo.dispose();
    guardado.dispose();
    dataController.dispose();
    iconeController.dispose();
  }

  Future<void> depositar(Meta meta) async {
    final valor = TextEditingController();

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Depositar em ${meta.titulo}'),
          content: TextField(
            controller: valor,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: const InputDecoration(
              labelText: 'Valor',
              prefixText: 'R\$ ',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final numero = double.tryParse(
                  valor.text.trim().replaceAll('.', '').replaceAll(',', '.'),
                );

                if (numero == null || numero <= 0) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Informe um valor válido para depositar.',
                      ),
                    ),
                  );
                  return;
                }

                try {
                  await ApiService.patch(
                    '/metas/depositar/${meta.id}',
                    {'valor': numero},
                  );

                  if (!mounted) return;
                  if (!dialogContext.mounted) return;

                  Navigator.pop(dialogContext);
                  await carregar();
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().replaceFirst('Exception: ', ''),
                      ),
                    ),
                  );
                }
              },
              child: const Text('Depositar'),
            ),
          ],
        ),
      );
    } finally {
      valor.dispose();
    }
  }

  Future<void> excluir(Meta meta) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir meta'),
        content: Text(
          'Deseja excluir a meta "${meta.titulo}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await ApiService.delete('/metas/excluir/${meta.id}');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meta excluída com sucesso!'),
        ),
      );

      await carregar();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  Widget _cardResumo({
    required double largura,
    required String titulo,
    required String valor,
    required String legenda,
    required IconData icone,
  }) {
    return Container(
      width: largura,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [verdeEscuro, verdeClaro],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ),
              Icon(
                icone,
                color: Colors.white,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 17),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valor,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            legenda,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cartaoMeta(Meta meta) {
    final progresso = meta.valorAlvo <= 0
        ? 0.0
        : (meta.valorAtual / meta.valorAlvo).clamp(0.0, 1.0);

    final concluida = meta.valorAlvo > 0 && meta.valorAtual >= meta.valorAlvo;

    final temaEscuro = Theme.of(context).brightness == Brightness.dark;

    final corTexto = temaEscuro ? Colors.white : const Color(0xFF263238);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ??
            Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: temaEscuro ? const Color(0xFF374151) : const Color(0xFFE5EAEC),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: verde.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.savings_outlined,
                  color: verde,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  meta.titulo,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: corTexto,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Opções',
                onSelected: (opcao) {
                  if (opcao == 'depositar') {
                    depositar(meta);
                  } else if (opcao == 'excluir') {
                    excluir(meta);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'depositar',
                    child: Row(
                      children: [
                        Icon(Icons.add_circle_outline),
                        SizedBox(width: 10),
                        Text('Depositar'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'excluir',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        SizedBox(width: 10),
                        Text('Excluir'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (meta.descricao.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              meta.descricao,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progresso',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
              Text(
                '${(progresso * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: verde,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progresso,
              minHeight: 9,
              backgroundColor: temaEscuro
                  ? const Color(0xFF374151)
                  : const Color(0xFFE7EEEC),
              valueColor: const AlwaysStoppedAnimation<Color>(
                verdeClaro,
              ),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      moeda.format(meta.valorAtual),
                      style: TextStyle(
                        color: corTexto,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Economizado',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    moeda.format(meta.valorAlvo),
                    style: TextStyle(
                      color: corTexto,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Valor alvo',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (concluida) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 17,
                  ),
                  SizedBox(width: 7),
                  Text(
                    'Meta concluída!',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      titulo: 'Metas',
      actions: [
        IconButton(
          onPressed: adicionar,
          tooltip: 'Nova Meta',
          icon: const Icon(Icons.add),
        ),
      ],
      body: carregando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: carregar,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final largura = constraints.maxWidth;
                  final compacto = largura < 650;

                  final colunas = largura >= 1100
                      ? 3
                      : largura >= 650
                          ? 2
                          : 1;

                  const espacamento = 16.0;

                  final larguraCard =
                      (largura - espacamento * (colunas - 1)) / colunas;

                  return ListView(
                    padding: EdgeInsets.all(compacto ? 16 : 26),
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Metas Financeiras',
                                  style: TextStyle(
                                    fontSize: 29,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 7),
                                Text(
                                  'Acompanhe seus objetivos de economia',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          FilledButton.icon(
                            onPressed: adicionar,
                            icon: const Icon(Icons.add, size: 19),
                            label: Text(
                              compacto ? 'Nova' : 'Nova Meta',
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: verde,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      Wrap(
                        spacing: espacamento,
                        runSpacing: espacamento,
                        children: [
                          _cardResumo(
                            largura: larguraCard,
                            titulo: 'Total Economizado',
                            valor: moeda.format(totalGuardado),
                            legenda: 'de ${moeda.format(totalAlvo)}',
                            icone: Icons.trending_up,
                          ),
                          _cardResumo(
                            largura: larguraCard,
                            titulo: 'Metas Ativas',
                            valor: '$quantidadeAtivas',
                            legenda: 'Metas em andamento',
                            icone: Icons.track_changes,
                          ),
                          _cardResumo(
                            largura: larguraCard,
                            titulo: 'Concluídas',
                            valor: '$quantidadeConcluidas',
                            legenda: 'Metas atingidas',
                            icone: Icons.emoji_events_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Suas metas',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '${metas.length} ${metas.length == 1 ? 'meta' : 'metas'}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (metas.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 65,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color ??
                                Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFF374151)
                                  : const Color(0xFFE5EAEC),
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  color: verde.withValues(alpha: 0.09),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.flag_outlined,
                                  size: 38,
                                  color: verde,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Nenhuma meta cadastrada ainda.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Crie sua primeira meta e acompanhe '
                                'seu progresso financeiro.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                onPressed: adicionar,
                                icon: const Icon(Icons.add),
                                label: const Text('Criar primeira meta'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: verde,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Wrap(
                          spacing: espacamento,
                          runSpacing: espacamento,
                          children: metas.map((meta) {
                            return SizedBox(
                              width: larguraCard,
                              child: _cartaoMeta(meta),
                            );
                          }).toList(),
                        ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}
