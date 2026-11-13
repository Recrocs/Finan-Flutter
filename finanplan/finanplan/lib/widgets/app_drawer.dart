import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../pages/dashboard_page.dart';
import '../pages/transacoes_page.dart';
import '../pages/metas_page.dart';
import '../pages/orcamentos_page.dart';
import '../pages/perfil_page.dart';
import '../pages/login_page.dart';
import '../services/theme_service.dart';

class AppDrawer extends StatelessWidget {
  final String currentPage;
  final bool drawerMode;

  const AppDrawer({
    super.key,
    required this.currentPage,
    this.drawerMode = false,
  });

  
Future<void> sair(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.remove('usuarioId');

  temaNotifier.value = ThemeMode.light;

  if (!context.mounted) return;

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => const LoginPage(),
    ),
    (_) => false,
  );
}

  void abrir(BuildContext context, Widget pagina) {
    if (drawerMode) {
      Navigator.pop(context);
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => pagina),
    );
  }

  @override
  Widget build(BuildContext context) {
    final corPrincipal = const Color(0xFF155E63);

    final corTexto = Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : const Color(0xFF59636E);

    final corFundo = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1F2937)
        : Colors.white;

    return Container(
      width: 245,
      color: corFundo,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 26, 16, 30),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF155E63),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _item(
              context,
              titulo: 'Dashboard',
              icone: Icons.grid_view_rounded,
              pagina: const DashboardPage(),
              ativo: currentPage == 'Dashboard',
              corPrincipal: corPrincipal,
              corTexto: corTexto,
            ),
            _item(
              context,
              titulo: 'Transações',
              icone: Icons.swap_horiz_rounded,
              pagina: const TransacoesPage(),
              ativo: currentPage == 'Transações',
              corPrincipal: corPrincipal,
              corTexto: corTexto,
            ),
            _item(
              context,
              titulo: 'Orçamentos',
              icone: Icons.account_balance_wallet_outlined,
              pagina: const OrcamentosPage(),
              ativo: currentPage == 'Orçamentos',
              corPrincipal: corPrincipal,
              corTexto: corTexto,
            ),
            _item(
              context,
              titulo: 'Metas',
              icone: Icons.flag_outlined,
              pagina: const MetasPage(),
              ativo: currentPage == 'Metas',
              corPrincipal: corPrincipal,
              corTexto: corTexto,
            ),
            _item(
              context,
              titulo: 'Configurações',
              icone: Icons.settings_outlined,
              pagina: const PerfilPage(),
              ativo: currentPage == 'Configurações',
              corPrincipal: corPrincipal,
              corTexto: corTexto,
            ),
            const Spacer(),
            const Divider(
              indent: 20,
              endIndent: 20,
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
              ),
              leading: const Icon(
                Icons.logout_rounded,
                color: Colors.redAccent,
              ),
              title: const Text(
                'Sair',
                style: TextStyle(
                  color: Colors.redAccent,
                ),
              ),
              onTap: () => sair(context),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required String titulo,
    required IconData icone,
    required Widget pagina,
    required bool ativo,
    required Color corPrincipal,
    required Color corTexto,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 3,
      ),
      child: Material(
        color: ativo ? const Color(0xFFE6F4F0) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => abrir(context, pagina),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 13,
            ),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: ativo ? corPrincipal : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icone,
                  size: 21,
                  color: ativo ? corPrincipal : corTexto,
                ),
                const SizedBox(width: 13),
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: ativo ? FontWeight.w600 : FontWeight.normal,
                    color: ativo ? corPrincipal : corTexto,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppScaffold extends StatelessWidget {
  final String titulo;
  final Widget body;
  final List<Widget>? actions;

  const AppScaffold({
    super.key,
    required this.titulo,
    required this.body,
    this.actions,
  });

  Future<void> _alternarTema() async {
    final novoTema = temaNotifier.value == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;

    temaNotifier.value = novoTema;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(
      'temaEscuro',
      novoTema == ThemeMode.dark,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 850;

        final conteudo = Column(
          children: [
            _topbar(context, desktop),
            Expanded(
              child: body,
            ),
          ],
        );

        return Scaffold(
          drawer: desktop
              ? null
              : Drawer(
                  child: AppDrawer(
                    currentPage: titulo,
                    drawerMode: true,
                  ),
                ),
          body: desktop
              ? Row(
                  children: [
                    AppDrawer(
                      currentPage: titulo,
                    ),
                    const VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: Color(0xFFE8ECEF),
                    ),
                    Expanded(
                      child: conteudo,
                    ),
                  ],
                )
              : conteudo,
        );
      },
    );
  }

  Widget _topbar(BuildContext context, bool desktop) {
    final corTexto = Theme.of(context).textTheme.bodyLarge?.color;

    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ??
            Theme.of(context).colorScheme.surface,
        border: const Border(
          bottom: BorderSide(
            color: Color(0xFFE8ECEF),
          ),
        ),
      ),
      child: Row(
        children: [
          if (!desktop) ...[
            Builder(
              builder: (context) => IconButton(
                tooltip: 'Abrir menu',
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
                icon: const Icon(Icons.menu),
              ),
            ),
            const SizedBox(width: 4),
          ],
          if (desktop)
            SizedBox(
              width: 310,
              height: 43,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Pesquisar',
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 21,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF374151)
                      : const Color(0xFFF5F7F8),
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: Text(
                titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const Spacer(),
          IconButton(
            tooltip: 'Alternar tema',
            onPressed: _alternarTema,
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
          const SizedBox(width: 8),
          FutureBuilder<SharedPreferences>(
            future: SharedPreferences.getInstance(),
            builder: (context, snapshot) {
              final prefs = snapshot.data;
              final nome = prefs?.getString('nomeUsuario') ?? 'Usuário';
              final email = prefs?.getString('emailUsuario') ?? '';

              return Row(
                children: [
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: const Color(0xFFE1F3EF),
                    child: Text(
                      nome.isNotEmpty ? nome[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Color(0xFF155E63),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (desktop) ...[
                    const SizedBox(width: 10),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 155,
                          child: Text(
                            nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (email.isNotEmpty)
                          SizedBox(
                            width: 155,
                            child: Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: corTexto?.withValues(
                                  alpha: 0.65,
                                ),
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                    ),
                  ],
                ],
              );
            },
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}
