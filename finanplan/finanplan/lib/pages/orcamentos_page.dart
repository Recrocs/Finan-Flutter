
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/categoria.dart';
import '../models/orcamento.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class OrcamentosPage extends StatefulWidget {
  const OrcamentosPage({super.key});

  @override
  State<OrcamentosPage> createState() => _OrcamentosPageState();
}

class _OrcamentosPageState extends State<OrcamentosPage> {
  List<Orcamento> lista = [];
  List<Categoria> categorias = [];

  bool carregando = true;

  final moeda = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$ ',
  );

  static const Color verde = Color(0xFF155E63);
  static const Color teal = Color(0xFF159F91);

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    try {
      final p = await SharedPreferences.getInstance();
      final controleId = p.getInt('controleId');

      if (controleId == null) {
        throw Exception(
          'Usuário não identificado. Faça login novamente.',
        );
      }

      final dadosOrcamentos = await ApiService.get(
        '/orcamentos/listar?controleId=$controleId',
      );

      final dadosCategorias = await ApiService.get(
        '/categoria/listar',
      );

      final novosOrcamentos = (dadosOrcamentos as List)
          .map((e) => Orcamento.fromJson(e))
          .toList();

      final novasCategorias = (dadosCategorias as List)
          .map((e) => Categoria.fromJson(e))
          .toList();

      if (!mounted) return;

      setState(() {
        lista = novosOrcamentos;
        categorias = novasCategorias;
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

  Future<void> adicionar() async {
    Categoria? categoria;
    bool salvando = false;

    final limiteController = TextEditingController();
    final formulario = GlobalKey<FormState>();

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (modalContext, setModal) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                title: const Text(
                  'Novo orçamento',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: SizedBox(
                  width: 420,
                  child: Form(
                    key: formulario,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<Categoria>(
                          initialValue: categoria,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Categoria',
                            prefixIcon: Icon(Icons.category_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: categorias.map((c) {
                            return DropdownMenuItem<Categoria>(
                              value: c,
                              child: Text(c.nome),
                            );
                          }).toList(),
                          onChanged: salvando
                              ? null
                              : (valor) {
                                  setModal(() {
                                    categoria = valor;
                                  });
                                },
                          validator: (valor) {
                            if (valor == null) {
                              return 'Selecione uma categoria.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: limiteController,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Limite mensal',
                            prefixText: 'R\$ ',
                            prefixIcon: Icon(
                              Icons.account_balance_wallet_outlined,
                            ),
                            border: OutlineInputBorder(),
                          ),
                          validator: (valor) {
                            final numero = double.tryParse(
                              (valor ?? '')
                                  .trim()
                                  .replaceAll(',', '.'),
                            );

                            if (numero == null || numero <= 0) {
                              return 'Informe um limite válido.';
                            }

                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: salvando
                        ? null
                        : () => Navigator.pop(dialogContext),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: verde,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: salvando
                        ? null
                        : () async {
                            if (!formulario.currentState!.validate()) {
                              return;
                            }

                            setModal(() {
                              salvando = true;
                            });

                            try {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              final controleId =
                                  prefs.getInt('controleId');

                              if (controleId == null) {
                                throw Exception(
                                  'Faça login novamente.',
                                );
                              }

                              final limite = double.parse(
                                limiteController.text
                                    .trim()
                                    .replaceAll(',', '.'),
                              );

                              await ApiService.post(
                                '/orcamentos/cadastrar',
                                {
                                  'categoriaId': categoria!.id,
                                  'limite': limite,
                                  'controleId': controleId,
                                },
                              );

                              if (!mounted ||
                                  !dialogContext.mounted) {
                                return;
                              }

                              Navigator.pop(dialogContext);
                              await carregar();

                              if (!mounted) return;

                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Orçamento cadastrado com sucesso!',
                                  ),
                                ),
                              );
                            } catch (e) {
                              if (dialogContext.mounted) {
                                setModal(() {
                                  salvando = false;
                                });
                              }

                              if (!mounted) return;

                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text(
                                    e.toString().replaceFirst(
                                          'Exception: ',
                                          '',
                                        ),
                                  ),
                                ),
                              );
                            }
                          },
                    child: salvando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Salvar orçamento'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      limiteController.dispose();
    }
  }

  Future<void> excluir(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir orçamento'),
          content: const Text(
            'Deseja realmente excluir este orçamento?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      await ApiService.delete('/orcamentos/excluir/$id');

      if (!mounted) return;

      await carregar();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Orçamento excluído com sucesso.'),
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;
    final estreito = largura < 850;

    final totalOrcamento = lista.fold<double>(
      0,
      (total, o) => total + o.limite,
    );

    final totalGasto = lista.fold<double>(
      0,
      (total, o) => total + o.gasto,
    );

    final restante = totalOrcamento - totalGasto;

    return AppScaffold(
      titulo: 'Orçamentos',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            tooltip: 'Novo orçamento',
            onPressed: adicionar,
            icon: const Icon(Icons.add),
          ),
        ),
      ],
      body: carregando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: carregar,
              child: ListView(
                padding: EdgeInsets.all(estreito ? 16 : 28),
                children: [
                  _cabecalho(estreito),
                  const SizedBox(height: 26),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final colunas =
                          constraints.maxWidth >= 950
                              ? 3
                              : constraints.maxWidth >= 500
                                  ? 2
                                  : 1;

                      const espacamento = 16.0;

                      final larguraCard =
                          (constraints.maxWidth -
                                  espacamento * (colunas - 1)) /
                              colunas;

                      return Wrap(
                        spacing: espacamento,
                        runSpacing: espacamento,
                        children: [
                          _cardResumo(
                            largura: larguraCard,
                            titulo: 'Orçamento Total',
                            valor: moeda.format(totalOrcamento),
                            legenda: 'Limites cadastrados',
                            icone: Icons.account_balance_wallet_outlined,
                          ),
                          _cardResumo(
                            largura: larguraCard,
                            titulo: 'Total Gasto no Mês',
                            valor: moeda.format(totalGasto),
                            legenda: 'Gastos dos orçamentos',
                            icone: Icons.payments_outlined,
                          ),
                          _cardResumo(
                            largura: larguraCard,
                            titulo: 'Restante',
                            valor: moeda.format(restante),
                            legenda: restante < 0
                                ? 'Orçamento ultrapassado'
                                : 'Valor ainda disponível',
                            icone: Icons.savings_outlined,
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 22),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final ladoALado =
                          constraints.maxWidth >= 900;

                      final gastos = _painel(
                        titulo: 'Gastos por categoria (mês atual)',
                        child: lista.isEmpty
                            ? _estadoVazio(
                                icone: Icons.pie_chart_outline,
                                mensagem:
                                    'Nenhum gasto registrado neste mês ainda.',
                              )
                            : Column(
                                children: lista.map((o) {
                                  final progresso = o.limite <= 0
                                      ? 0.0
                                      : (o.gasto / o.limite)
                                          .clamp(0.0, 1.0);

                                  final excedeu =
                                      o.gasto > o.limite;

                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(
                                      bottom: 22,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                o.categoria?.nome ??
                                                    'Categoria',
                                                style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              moeda.format(o.gasto),
                                              style: TextStyle(
                                                color: excedeu
                                                    ? Colors.red
                                                    : verde,
                                                fontWeight:
                                                    FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: LinearProgressIndicator(
                                            value: progresso,
                                            minHeight: 9,
                                            backgroundColor:
                                                Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? const Color(
                                                        0xFF374151,
                                                      )
                                                    : const Color(
                                                        0xFFE8EEEE,
                                                      ),
                                            color: excedeu
                                                ? Colors.red
                                                : teal,
                                          ),
                                        ),
                                        const SizedBox(height: 7),
                                        Text(
                                          'Limite: ${moeda.format(o.limite)}',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                      );

                      final orcamentos = _painel(
                        titulo: 'Seus orçamentos',
                        child: lista.isEmpty
                            ? _estadoVazio(
                                icone: Icons
                                    .description_outlined,
                                mensagem:
                                    'Nenhum orçamento cadastrado ainda.',
                              )
                            : Column(
                                children: lista.map((o) {
                                  final excedeu =
                                      o.gasto > o.limite;

                                  return Container(
                                    margin:
                                        const EdgeInsets.only(
                                      bottom: 12,
                                    ),
                                    padding:
                                        const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                                  .brightness ==
                                              Brightness.dark
                                          ? const Color(0xFF273548)
                                          : const Color(0xFFF7F9FA),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Theme.of(context)
                                                    .brightness ==
                                                Brightness.dark
                                            ? const Color(
                                                0xFF374151,
                                              )
                                            : const Color(
                                                0xFFE8ECEF,
                                              ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                o.categoria?.nome ??
                                                    'Categoria',
                                                style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              tooltip:
                                                  'Excluir orçamento',
                                              onPressed: () =>
                                                  excluir(o.id),
                                              icon: const Icon(
                                                Icons
                                                    .delete_outline,
                                                color: Colors.redAccent,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${moeda.format(o.gasto)} de ${moeda.format(o.limite)}',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 13,
                                          ),
                                        ),
                                        if (excedeu) ...[
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Limite excedido',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontWeight:
                                                  FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                      );

                      if (ladoALado) {
                        return Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 6,
                              child: gastos,
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              flex: 4,
                              child: orcamentos,
                            ),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          gastos,
                          const SizedBox(height: 18),
                          orcamentos,
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _cabecalho(bool estreito) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Orçamentos',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 7),
              Text(
                'Defina limites por categoria e acompanhe seus gastos do mês',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: adicionar,
          icon: const Icon(Icons.add),
          label: Text(
            estreito ? 'Novo' : 'Novo Orçamento',
          ),
          style: FilledButton.styleFrom(
            backgroundColor: verde,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF10565F),
            Color(0xFF159F91),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icone,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valor,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 27,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            titulo,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
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

  Widget _painel({
    required String titulo,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 340,
      ),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ??
            Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Theme.of(context).brightness ==
                  Brightness.dark
              ? const Color(0xFF374151)
              : const Color(0xFFDCE4E9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _estadoVazio({
    required IconData icone,
    required String mensagem,
  }) {
    return SizedBox(
      height: 245,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icone,
              size: 48,
              color: Colors.blueGrey.withValues(alpha: 0.65),
            ),
            const SizedBox(height: 16),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
