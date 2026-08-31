import 'package:flutter/material.dart';
{{#if riverpod}}import 'package:flutter_riverpod/flutter_riverpod.dart';
{{/if}}{{#if bloc}}import 'package:flutter_bloc/flutter_bloc.dart';
import 'app/app_cubit.dart';
{{/if}}import 'app/app.dart';

void main() {
{{#if riverpod}}  runApp(const ProviderScope(child: App()));
{{/if}}{{#if bloc}}  runApp(BlocProvider<AppCubit>(create: (_) => AppCubit(), child: const App()));
{{/if}}{{#if none}}  runApp(const App());
{{/if}}}
