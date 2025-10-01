import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/misc/missing_env_screen.dart';
 
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
  final supabaseAnon = const String.fromEnvironment('SUPABASE_ANON_KEY');
  if (supabaseUrl.isEmpty || supabaseAnon.isEmpty) {
    runApp(const MissingEnvApp());
    return;
  }
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnon);
  runApp(const ProviderScope(child: App()));
}
