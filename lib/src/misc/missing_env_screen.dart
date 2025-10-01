import 'package:flutter/material.dart';

class MissingEnvApp extends StatelessWidget {
  const MissingEnvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MissingEnvScreen(),
    );
  }
}

class MissingEnvScreen extends StatelessWidget {
  const MissingEnvScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Konfiguration fehlt')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: const [
            Text(
              'SUPABASE_URL und/oder SUPABASE_ANON_KEY fehlen.\n\n'
              'Bitte starte die App mit Dart-Defines oder nutze die env.example.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Option A: env.example verwenden (lokal):\n'
              'flutter run --dart-define-from-file=env.example\n\n'
              'Option B: einzelne Defines setzen:\n'
              'flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...\n\n'
              'Android Studio: Run/Debug Configurations -> Additional run args',
            ),
          ],
        ),
      ),
    );
  }
}
