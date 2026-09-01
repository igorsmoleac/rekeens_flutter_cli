{{#if go_router}}import 'package:go_router/go_router.dart';
import '../features/home/presentation/pages/home_page.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    // ShellRoute wraps child routes with a shared widget (e.g. a Scaffold with
    // a BottomNavigationBar). Uncomment and adapt to use nested routes:
    // ShellRoute(
    //   builder: (context, state, child) => MainShell(child: child),
    //   routes: [
    //     GoRoute(
    //       path: '/settings',
    //       builder: (context, state) => const SettingsPage(),
    //     ),
    //     GoRoute(
    //       path: '/profile',
    //       builder: (context, state) => const ProfilePage(),
    //     ),
    //   ],
    // ),
  ],
);
{{/if}}{{#unless go_router}}class AppRouter {
  static const String home = '/';
}
{{/unless}}
