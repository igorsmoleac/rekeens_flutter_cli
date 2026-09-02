{{#if go_router}}import 'package:go_router/go_router.dart';
import '../features/home/presentation/pages/home_page.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
  ],
);
{{/if}}{{#unless go_router}}class AppRouter {
  static const String home = '/';
}
{{/unless}}
