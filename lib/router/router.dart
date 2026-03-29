import 'package:go_router/go_router.dart';
import '../views/home_view.dart';
import '../views/add_depense_view.dart';
import '../views/stats_view.dart';
import '../views/import_view.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeView(),
    ),
    GoRoute(
      path: '/add-depense',
      name: 'add-depense',
      builder: (context, state) => const AddDepenseView(),
    ),
    GoRoute(
      path: '/stats',
      name: 'stats',
      builder: (context, state) => const StatsView(),
    ),
    GoRoute(
      path: '/import',
      name: 'import',
      builder: (context, state) => const ImportView(),
    ),
  ],
);
