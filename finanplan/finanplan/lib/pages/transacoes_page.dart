import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/transacao.dart';
import '../models/categoria.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class TransacoesPage extends StatefulWidget {
  const TransacoesPage({super.key});

  @override
  State<TransacoesPage> createState() => _TransacoesPageState();
}

class _TransacoesPageState extends State<TransacoesPage> {
  List<Transacao> transacoes = [];
  List<Categoria> categoriasDisponiveis = [];

  bool carregando = true;

  String busca = '';
  String tipoSelecionado = 'Todos os tipos';
  String categoriaSelecionada = 'Todas as categorias';
  String mesSelecionado = 'Todos os meses';
  String abaSelecionada = 'Todas';

  final TextEditingController buscaController = TextEditingController();

  final moeda = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$ ',
  );

  @override
  void initState() {
    super.initState();
    carregar();
  }

  @override
  void dispose() {
    buscaController.dispose();
    super.dispose();
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
        '/transacoes/listar?controleId=$controleId',
      );

      final dadosCategorias = await ApiService.get(
        '/categoria/listar',
      );

      final resultado =
          (dados as List).map((e) => Transacao.fromJson(e)).toList();

      final novasCategorias =
          (dadosCategorias as List).map((e) => Categoria.fromJson(e)).toList();

      resultado.sort((a, b) => b.data.compareTo(a.data));

      if (!mounted) return;

      setState(() {
        transacoes = resultado;
        categoriasDisponiveis = novasCategorias;
        carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        carregando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  List<Transacao> get transacoesFiltradas {
    return transacoes.where((t) {
      final descricao = t.descricao.toLowerCase();
      final categoria = (t.categoria?.nome ?? 'Sem categoria').toLowerCase();

      final correspondeBusca = descricao.contains(busca.toLowerCase()) ||
          categoria.contains(busca.toLowerCase());

      final correspondeAba = abaSelecionada == 'Todas' ||
          (abaSelecionada == 'Receitas' && t.tipo == 'ENTRADA') ||
          (abaSelecionada == 'Despesas' && t.tipo == 'SAIDA');

      final correspondeTipo = tipoSelecionado == 'Todos os tipos' ||
          (tipoSelecionado == 'Receitas' && t.tipo == 'ENTRADA') ||
          (tipoSelecionado == 'Despesas' && t.tipo == 'SAIDA');

      final correspondeCategoria =
          categoriaSelecionada == 'Todas as categorias' ||
              (t.categoria?.nome ?? 'Sem categoria') == categoriaSelecionada;

      final data = t.data;
      final correspondeMes = mesSelecionado == 'Todos os meses' ||
          DateFormat('MM/yyyy').format(data) == mesSelecionado;

      return correspondeBusca &&
          correspondeAba &&
          correspondeTipo &&
          correspondeCategoria &&
          correspondeMes;
    }).toList();
  }

  List<String> get categorias {
    final lista = transacoes
        .map((t) => t.categoria?.nome ?? 'Sem categoria')
        .toSet()
        .toList();

    lista.sort();
    return lista;
  }

  List<String> get meses {
    final lista = transacoes
        .map((t) => DateFormat('MM/yyyy').format(t.data))
        .toSet()
        .toList();

    lista.sort((a, b) {
      final dataA = DateFormat('MM/yyyy').parse(a);
      final dataB = DateFormat('MM/yyyy').parse(b);
      return dataB.compareTo(dataA);
    });

    return lista;
  }

  double somar(List<Transacao> lista, String tipo) {
    return lista
        .where((t) => t.tipo == tipo)
        .fold<double>(0, (total, t) => total + t.valor);
  }

  void limparFiltros() {
    setState(() {
      busca = '';
      buscaController.clear();
      tipoSelecionado = 'Todos os tipos';
      categoriaSelecionada = 'Todas as categorias';
      mesSelecionado = 'Todos os meses';
      abaSelecionada = 'Todas';
    });
  }

  Future<void> nova() async {
    final descricaoController = TextEditingController();
    final valorController = TextEditingController(text: '0,00');
    final observacaoController = TextEditingController();

    Categoria? categoriaSelecionada;

    String tipo = 'ENTRADA';
    String metodoPagamento = 'Pix';
    DateTime data = DateTime.now();

    final formulario = GlobalKey<FormState>();
    final larguraTela = MediaQuery.of(context).size.width;
    final larguraDialogo = larguraTela < 600 ? larguraTela - 32 : 680.0;

    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, atualizarDialogo) {
            final temaEscuro = Theme.of(context).brightness == Brightness.dark;

            final corTexto =
                temaEscuro ? Colors.white : const Color(0xFF1F2937);

            final corBorda =
                temaEscuro ? const Color(0xFF424A50) : const Color(0xFFE1E7E9);

            const verde = Color(0xFF155E63);

            InputDecoration decoracao({
              required String hint,
              String? prefixo,
              Widget? sufixo,
            }) {
              return InputDecoration(
                hintText: hint,
                prefixText: prefixo,
                suffixIcon: sufixo,
                filled: true,
                fillColor: temaEscuro
                    ? const Color(0xFF20282C)
                    : const Color(0xFFFAFBFC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 15,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: BorderSide(color: corBorda),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: BorderSide(color: corBorda),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: const BorderSide(
                    color: verde,
                    width: 1.5,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: const BorderSide(color: Colors.red),
                ),
              );
            }

            Widget tituloCampo(String texto, {bool opcional = false}) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(
                      texto,
                      style: TextStyle(
                        color: corTexto,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
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
              );
            }

            Widget campo({
              required String titulo,
              required Widget conteudo,
              bool opcional = false,
            }) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  tituloCampo(titulo, opcional: opcional),
                  conteudo,
                ],
              );
            }

            Widget seletorTipo({
              required String texto,
              required String valor,
              required IconData icone,
              required Color cor,
            }) {
              final selecionado = tipo == valor;

              return Expanded(
                child: InkWell(
                  onTap: () {
                    atualizarDialogo(() {
                      tipo = valor;
                      categoriaSelecionada = null;
                    });
                  },
                  borderRadius: BorderRadius.circular(11),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: selecionado
                          ? cor.withValues(alpha: 0.07)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: selecionado ? cor : corBorda,
                        width: selecionado ? 1.6 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icone, size: 19, color: cor),
                        const SizedBox(width: 9),
                        Text(
                          texto,
                          style: TextStyle(
                            color: selecionado ? cor : Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final categoriasDoTipo = categoriasDisponiveis;
            
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
                          22,
                          16,
                          18,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Nova Transação',
                                style: TextStyle(
                                  color: corTexto,
                                  fontSize: 23,
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
                                Row(
                                  children: [
                                    seletorTipo(
                                      texto: 'Receita',
                                      valor: 'ENTRADA',
                                      icone: Icons.arrow_upward_rounded,
                                      cor: const Color(0xFF16845B),
                                    ),
                                    const SizedBox(width: 12),
                                    seletorTipo(
                                      texto: 'Despesa',
                                      valor: 'SAIDA',
                                      icone: Icons.arrow_downward_rounded,
                                      cor: const Color(0xFFD94848),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 22),
                                campo(
                                  titulo: 'Descrição',
                                  conteudo: TextFormField(
                                    controller: descricaoController,
                                    decoration: decoracao(
                                      hint: 'Ex: Salário, Aluguel...',
                                    ),
                                    validator: (valor) {
                                      if (valor == null ||
                                          valor.trim().isEmpty) {
                                        return 'Informe a descrição.';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 18),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final duasColunas =
                                        constraints.maxWidth >= 430;

                                    final valorCampo = campo(
                                      titulo: 'Valor (R\$)',
                                      conteudo: TextFormField(
                                        controller: valorController,
                                        keyboardType: const TextInputType
                                            .numberWithOptions(
                                          decimal: true,
                                        ),
                                        decoration: decoracao(
                                          hint: '0,00',
                                          prefixo: 'R\$ ',
                                        ),
                                        validator: (valor) {
                                          final texto = (valor ?? '')
                                              .trim()
                                              .replaceAll(' ', '')
                                              .replaceAll('.', '')
                                              .replaceAll(',', '.');

                                          final numero = double.tryParse(texto);

                                          if (numero == null || numero <= 0) {
                                            return 'Informe um valor válido.';
                                          }
                                          return null;
                                        },
                                      ),
                                    );

                                    final dataCampo = campo(
                                      titulo: 'Data',
                                      conteudo: InkWell(
                                        onTap: () async {
                                          final escolhida =
                                              await showDatePicker(
                                            context: context,
                                            initialDate: data,
                                            firstDate: DateTime(2000),
                                            lastDate: DateTime(2100),
                                          );

                                          if (escolhida != null) {
                                            atualizarDialogo(() {
                                              data = escolhida;
                                            });
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(11),
                                        child: InputDecorator(
                                          decoration: decoracao(
                                            hint: '',
                                            sufixo: const Icon(
                                              Icons.calendar_month_outlined,
                                              size: 20,
                                            ),
                                          ),
                                          child: Text(
                                            DateFormat('dd/MM/yyyy')
                                                .format(data),
                                            style: TextStyle(color: corTexto),
                                          ),
                                        ),
                                      ),
                                    );

                                    if (!duasColunas) {
                                      return Column(
                                        children: [
                                          valorCampo,
                                          const SizedBox(height: 18),
                                          dataCampo,
                                        ],
                                      );
                                    }

                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(child: valorCampo),
                                        const SizedBox(width: 14),
                                        Expanded(child: dataCampo),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 18),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final duasColunas =
                                        constraints.maxWidth >= 430;

                                    final categoriaCampo = campo(
                                      titulo: 'Categoria',
                                      conteudo: DropdownButtonFormField<int>(
                                        value: categoriaSelecionada?.id,
                                        isExpanded: true,
                                        decoration: decoracao(
                                          hint: 'Selecione uma categoria',
                                        ),
                                        items: categoriasDoTipo.map(
                                          (categoria) {
                                            return DropdownMenuItem<int>(
                                              value: categoria.id,
                                              child: Text(
                                                categoria.nome,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            );
                                          },
                                        ).toList(),
                                        onChanged: (id) {
                                          atualizarDialogo(() {
                                            categoriaSelecionada =
                                                categoriasDoTipo.firstWhere(
                                              (categoria) => categoria.id == id,
                                            );
                                          });
                                        },
                                        validator: (id) {
                                          if (id == null) {
                                            return 'Selecione uma categoria.';
                                          }
                                          return null;
                                        },
                                      ),
                                    );

                                    final metodoCampo = campo(
                                      titulo: 'Método de Pagamento',
                                      conteudo: DropdownButtonFormField<String>(
                                        value: metodoPagamento,
                                        isExpanded: true,
                                        decoration: decoracao(hint: ''),
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'Pix',
                                            child: Text('Pix'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'Dinheiro',
                                            child: Text('Dinheiro'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'Cartão de crédito',
                                            child: Text('Cartão de crédito'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'Cartão de débito',
                                            child: Text('Cartão de débito'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'Transferência',
                                            child: Text('Transferência'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'Boleto',
                                            child: Text('Boleto'),
                                          ),
                                        ],
                                        onChanged: (valor) {
                                          if (valor != null) {
                                            atualizarDialogo(() {
                                              metodoPagamento = valor;
                                            });
                                          }
                                        },
                                      ),
                                    );

                                    if (!duasColunas) {
                                      return Column(
                                        children: [
                                          categoriaCampo,
                                          const SizedBox(height: 18),
                                          metodoCampo,
                                        ],
                                      );
                                    }

                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(child: categoriaCampo),
                                        const SizedBox(width: 14),
                                        Expanded(child: metodoCampo),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 18),
                                campo(
                                  titulo: 'Observação',
                                  opcional: true,
                                  conteudo: TextFormField(
                                    controller: observacaoController,
                                    maxLines: 3,
                                    decoration: decoracao(
                                      hint:
                                          'Adicione uma nota sobre esta transação...',
                                    ),
                                  ),
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
                              label: const Text('Salvar Transação'),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF155E3D),
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

        if (categoriaSelecionada == null) {
          throw Exception('Selecione uma categoria.');
        }

        final textoValor = valorController.text
            .trim()
            .replaceAll(' ', '')
            .replaceAll('.', '')
            .replaceAll(',', '.');

        final valor = double.parse(textoValor);

        await ApiService.post('/transacoes/cadastrar', {
          'descricao': descricaoController.text.trim(),
          'valor': valor,
          'tipo': tipo,
          'data': data.toIso8601String(),
          'controleId': controleId,
          'categoriaId': categoriaSelecionada!.id,
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transação cadastrada com sucesso!'),
          ),
        );

        await carregar();
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }

    descricaoController.dispose();
    valorController.dispose();
    observacaoController.dispose();
  }

  Future<void> excluir(Transacao t) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir transação'),
        content: Text(
          'Deseja excluir "${t.descricao}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await ApiService.delete('/transacoes/excluir/${t.id}');

      if (!mounted) return;

      await carregar();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lista = transacoesFiltradas;
    final receitas = somar(lista, 'ENTRADA');
    final despesas = somar(lista, 'SAIDA');
    final saldo = receitas - despesas;
    final largura = MediaQuery.of(context).size.width;
    final compacto = largura < 1000;

    return AppScaffold(
      titulo: 'Transações',
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: carregar,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Transações',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Gerencie todas as suas movimentações financeiras',
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
                        onPressed: nova,
                        icon: const Icon(Icons.add),
                        label: Text(
                          compacto ? 'Nova' : 'Nova Transação',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF155E63),
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
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final colunas = constraints.maxWidth >= 1100
                          ? 4
                          : constraints.maxWidth >= 600
                              ? 2
                              : 1;

                      final espacamento = 14.0;
                      final larguraCard =
                          (constraints.maxWidth - espacamento * (colunas - 1)) /
                              colunas;

                      return Wrap(
                        spacing: espacamento,
                        runSpacing: espacamento,
                        children: [
                          _cardResumo(
                            largura: larguraCard,
                            titulo: 'Total de Receitas',
                            valor: moeda.format(receitas),
                            legenda:
                                '${lista.where((t) => t.tipo == 'ENTRADA').length} receitas',
                            icone: Icons.trending_up,
                          ),
                          _cardResumo(
                            largura: larguraCard,
                            titulo: 'Total de Despesas',
                            valor: moeda.format(despesas),
                            legenda: receitas > 0
                                ? '${(despesas / receitas * 100).toStringAsFixed(0)}% da receita'
                                : '0% da receita',
                            icone: Icons.trending_down,
                          ),
                          _cardResumo(
                            largura: larguraCard,
                            titulo: 'Saldo do Mês',
                            valor: moeda.format(saldo),
                            legenda: 'Receitas - despesas',
                            icone: Icons.account_balance_wallet_outlined,
                          ),
                          _cardResumo(
                            largura: larguraCard,
                            titulo: 'Transações no Mês',
                            valor: '${lista.length}',
                            legenda:
                                '${lista.where((t) => t.tipo == 'ENTRADA').length} receitas - ${lista.where((t) => t.tipo == 'SAIDA').length} despesas',
                            icone: Icons.receipt_long_outlined,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final estreito = constraints.maxWidth < 750;

                              final filtros = Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _filtro<String>(
                                    valor: mesSelecionado,
                                    icone: Icons.calendar_month,
                                    opcoes: [
                                      'Todos os meses',
                                      ...meses,
                                    ],
                                    alterar: (v) {
                                      setState(() => mesSelecionado = v);
                                    },
                                  ),
                                  _filtro<String>(
                                    valor: tipoSelecionado,
                                    icone: Icons.swap_vert,
                                    opcoes: const [
                                      'Todos os tipos',
                                      'Receitas',
                                      'Despesas',
                                    ],
                                    alterar: (v) {
                                      setState(() => tipoSelecionado = v);
                                    },
                                  ),
                                  _filtro<String>(
                                    valor: categoriaSelecionada,
                                    icone: Icons.sell_outlined,
                                    opcoes: [
                                      'Todas as categorias',
                                      ...categorias,
                                    ],
                                    alterar: (v) {
                                      setState(() => categoriaSelecionada = v);
                                    },
                                  ),
                                ],
                              );

                              final buscaWidget = SizedBox(
                                width: estreito ? constraints.maxWidth : 260,
                                child: TextField(
                                  controller: buscaController,
                                  onChanged: (valor) {
                                    setState(() => busca = valor);
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Buscar transação...',
                                    prefixIcon: const Icon(Icons.search),
                                    isDense: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              );

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  filtros,
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(child: buscaWidget),
                                      TextButton.icon(
                                        onPressed: limparFiltros,
                                        icon: const Icon(
                                          Icons.filter_alt_off,
                                        ),
                                        label: const Text('Limpar'),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 18),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              spacing: 8,
                              children: [
                                _aba('Todas'),
                                _aba('Receitas'),
                                _aba('Despesas'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: largura > 1000 ? largura - 370 : 900,
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 16,
                                    ),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF155E63),
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(10),
                                      ),
                                    ),
                                    child: const Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: _tituloColuna('DESCRIÇÃO'),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: _tituloColuna('CATEGORIA'),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: _tituloColuna('DATA'),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: _tituloColuna('MÉTODO'),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: _tituloColuna('VALOR'),
                                        ),
                                        SizedBox(
                                          width: 60,
                                          child: _tituloColuna('AÇÕES'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (lista.isEmpty)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 48,
                                        horizontal: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            Theme.of(context).cardTheme.color,
                                        borderRadius:
                                            const BorderRadius.vertical(
                                          bottom: Radius.circular(10),
                                        ),
                                      ),
                                      child: const Column(
                                        children: [
                                          Icon(
                                            Icons.receipt_long_outlined,
                                            size: 48,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(height: 12),
                                          Text(
                                            'Nenhuma transação encontrada.',
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    ...lista.map((t) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 13,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              Theme.of(context).cardTheme.color,
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? const Color(0xFF374151)
                                                  : const Color(0xFFE8ECEF),
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                t.descricao,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                t.categoria?.nome ??
                                                    'Sem categoria',
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                DateFormat('dd/MM/yyyy')
                                                    .format(t.data),
                                              ),
                                            ),
                                            const Expanded(
                                              flex: 2,
                                              child: Text('Não informado'),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                '${t.tipo == 'ENTRADA' ? '+' : '-'} ${moeda.format(t.valor)}',
                                                style: TextStyle(
                                                  color: t.tipo == 'ENTRADA'
                                                      ? Colors.green
                                                      : Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 60,
                                              child: IconButton(
                                                tooltip: 'Excluir',
                                                onPressed: () => excluir(t),
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.redAccent,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardTheme.color,
                                      borderRadius: const BorderRadius.vertical(
                                        bottom: Radius.circular(10),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          lista.isEmpty
                                              ? 'Nenhuma transação'
                                              : '${lista.length} transação(ões)',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          onPressed: null,
                                          icon: const Icon(
                                            Icons.chevron_left,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: null,
                                          icon: const Icon(
                                            Icons.chevron_right,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF155E63),
            Color(0xFF218C83),
          ],
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
                size: 23,
              ),
            ],
          ),
          const SizedBox(height: 16),
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

  Widget _filtro<T>({
    required T valor,
    required IconData icone,
    required List<T> opcoes,
    required ValueChanged<T> alterar,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFE0E5E7),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<T>(
        value: valor,
        underline: const SizedBox(),
        icon: const Icon(Icons.keyboard_arrow_down),
        items: opcoes.map((opcao) {
          return DropdownMenuItem<T>(
            value: opcao,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icone, size: 17),
                const SizedBox(width: 8),
                Text(
                  opcao.toString(),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (novoValor) {
          if (novoValor != null) alterar(novoValor);
        },
      ),
    );
  }

  Widget _aba(String texto) {
    final ativa = abaSelecionada == texto;

    return ChoiceChip(
      label: Text(texto),
      selected: ativa,
      showCheckmark: false,
      selectedColor: const Color(0xFF155E63),
      backgroundColor: Theme.of(context).cardTheme.color,
      labelStyle: TextStyle(
        color: ativa ? Colors.white : null,
        fontWeight: ativa ? FontWeight.w600 : FontWeight.normal,
      ),
      onSelected: (_) {
        setState(() => abaSelecionada = texto);
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
    );
  }
}

class _tituloColuna extends StatelessWidget {
  final String texto;

  const _tituloColuna(this.texto);

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
