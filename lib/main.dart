import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = 'https://wjqqqjngzurrjejrblfb.supabase.co';
  const String supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndqcXFxam5nenVycmplanJibGZiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIxNzMzMDUsImV4cCI6MjA2Nzc0OTMwNX0.xFnuSFVeInEIDKYj9zQuZO0j0b15xnzlbyOxnkuWlsA';

  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);

  runApp(const ProviderScope(child: WorshipLamal()));
}
