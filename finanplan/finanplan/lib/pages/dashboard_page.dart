import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/transacao.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<Transacao> transacoes = [];

  bool carregando = true;
  double receitas = 0;
  double despesas = 0;

  final moeda = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$ ',
  );

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
        '/transacoes/listar?controleId=$controleId',
      );

      final resultado =
          (dados as List).map((e) => Transacao.fromJson(e)).toList();

      if (!mounted) return;

      setState(() {
        transacoes = resultado;

        receitas = transacoes
            .where((t) => t.tipo == 'ENTRADA')
            .fold<double>(0, (total, t) => total + t.valor);

        despesas = transacoes
            .where((t) => t.tipo == 'SAIDA')
            .fold<double>(0, (total, t) => total + t.valor);

        carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => carregando = false);

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
    final saldo = receitas - despesas;
    final metaEconomia = saldo > 0 ? saldo * 0.30 : 0.0;

    return AppScaffold(
      titulo: 'Dashboard',
      body: carregando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: carregar,
              child: ListView(
                padding: const EdgeInsets.all(28),
                children: [
                  const Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Visão geral das suas finanças',
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 28),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final largura = constraints.maxWidth;

                      final double larguraCard;

                      if (largura >= 1100) {
                        larguraCard = (largura - 36) / 4;
                      } else if (largura >= 620) {
                        larguraCard = (largura - 12) / 2;
                      } else {
                        larguraCard = largura;
                      }

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _card(
                            largura: larguraCard,
                            titulo: 'Saldo Total',
                            valor: saldo,
                            legenda: 'Saldo atual',
                            icone: Icons.account_balance_wallet_outlined,
                            corInicial: const Color(0xFF155E63),
                            corFinal: const Color(0xFF267F83),
                          ),
                          _card(
                            largura: larguraCard,
                            titulo: 'Receitas',
                            valor: receitas,
                            legenda: 'Receitas do período',
                            icone: Icons.trending_up_rounded,
                            corInicial: const Color(0xFF176B58),
                            corFinal: const Color(0xFF319879),
                          ),
                          _card(
                            largura: larguraCard,
                            titulo: 'Despesas',
                            valor: despesas,
                            legenda: 'Despesas do período',
                            icone: Icons.trending_down_rounded,
                            corInicial: const Color(0xFF155E63),
                            corFinal: const Color(0xFF287D8A),
                          ),
                          _card(
                            largura: larguraCard,
                            titulo: 'Meta de Economia',
                            valor: metaEconomia,
                            legenda: '30% do saldo positivo',
                            icone: Icons.savings_outlined,
                            corInicial: const Color(0xFF205C78),
                            corFinal: const Color(0xFF318D96),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Transações Recentes',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            transacoes.isEmpty
                                ? 'Suas movimentações aparecerão aqui.'
                                : 'Confira suas últimas movimentações.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withValues(alpha: 0.65),
                            ),
                          ),
                          const SizedBox(height: 18),
                          if (transacoes.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 28),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.receipt_long_outlined,
                                      size: 42,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Nenhuma transação cadastrada.',
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...transacoes.take(5).map((t) {
                              final entrada = t.tipo == 'ENTRADA';

                              return Column(
                                children: [
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: entrada
                                          ? const Color(0xFFE0F4E9)
                                          : const Color(0xFFFCE8E8),
                                      child: Icon(
                                        entrada
                                            ? Icons.arrow_downward_rounded
                                            : Icons.arrow_upward_rounded,
                                        color: entrada
                                            ? const Color(0xFF198754)
                                            : const Color(0xFFDC4545),
                                      ),
                                    ),
                                    title: Text(
                                      t.descricao,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${t.categoria?.nome ?? 'Sem categoria'}'
                                      ' • ${DateFormat('dd/MM/yyyy').format(t.data)}',
                                    ),
                                    trailing: Text(
                                      '${entrada ? '+' : '-'} '
                                      '${moeda.format(t.valor)}',
                                      style: TextStyle(
                                        color: entrada
                                            ? const Color(0xFF198754)
                                            : const Color(0xFFDC4545),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (t != transacoes.take(5).toList().last)
                                    const Divider(height: 1),
                                ],
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _card({
    required double largura,
    required String titulo,
    required double valor,
    required String legenda,
    required IconData icone,
    required Color corInicial,
    required Color corFinal,
  }) {
    return SizedBox(
      width: largura,
      height: 170,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [corInicial, corFinal],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: corInicial.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    icone,
                    color: Colors.white.withValues(alpha: 0.85),
                    size: 23,
                  ),
                ],
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  moeda.format(valor),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                legenda,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
