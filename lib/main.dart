import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';

Future<void> main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = 'https://wjqqqjngzurrjejrblfb.supabase.co';
  const String supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndqcXFxam5nenVycmplanJibGZiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIxNzMzMDUsImV4cCI6MjA2Nzc0OTMwNX0.xFnuSFVeInEIDKYj9zQuZO0j0b15xnzlbyOxnkuWlsA';

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);

  final session = Supabase.instance.client.auth.currentSession;

  // 2. If no session exists, create a Guest Account immediately
  if (session == null) {
    await Supabase.instance.client.auth.signInAnonymously();
  }

  runApp(const ProviderScope(child: WorshipLamal()));
}
