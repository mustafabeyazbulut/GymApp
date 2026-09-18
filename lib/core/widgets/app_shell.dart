// lib/core/widgets/app_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../../l10n/generated/app_localizations.dart';
import 'app_drawer.dart';

/// [AppHeaderBar]'dan [AppDrawer]'ı açar; header bu Scaffold'un birkaç
/// seviye altında yer alır (her shell dalının kendi Scaffold'u vardır) —
/// `Scaffold.of(context)` her zaman yalnızca daha yakın, çekmecesiz dal
/// Scaffold'unu bulurdu, bu yüzden header bunun yerine doğrudan bu tek
/// paylaşılan örneğe ulaşır.
final GlobalKey<ScaffoldState> appShellScaffoldKey = GlobalKey<ScaffoldState>();

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      key: appShellScaffoldKey,
      drawer: const AppDrawer(),
      body: SafeArea(child: navigationShell),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg + bottomInset,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(color: AppColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: NavigationBar(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: (index) => navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                ),
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.home_outlined),
                    selectedIcon: const Icon(Icons.home),
                    label: l10n.navHome,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.calendar_month_outlined),
                    selectedIcon: const Icon(Icons.calendar_month),
                    label: l10n.navClasses,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.show_chart_outlined),
                    selectedIcon: const Icon(Icons.show_chart),
                    label: l10n.navProgress,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.person_outline),
                    selectedIcon: const Icon(Icons.person),
                    label: l10n.navMembership,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
