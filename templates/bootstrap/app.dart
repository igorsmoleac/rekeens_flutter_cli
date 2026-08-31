import 'package:flutter/material.dart';
{{#if go_router}}import 'router.dart';
{{/if}}{{#unless go_router}}import '../features/home/presentation/pages/home_page.dart';
{{/unless}}{{#if l10n}}import '../l10n/app_localizations.dart';
{{/if}}
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp{{#if go_router}}.router{{/if}}(
      title: '{{project_name}}',
      theme: ThemeData(
        useMaterial3: {{#if material3}}true{{/if}}{{#unless material3}}false{{/unless}},
{{#if material3}}        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
{{/if}}{{#unless material3}}        primarySwatch: Colors.blue,
{{/unless}}      ),
{{#if l10n}}      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
{{/if}}{{#if go_router}}      routerConfig: appRouter,
{{/if}}{{#unless go_router}}      home: const HomePage(),
{{/unless}}    );
  }
}
