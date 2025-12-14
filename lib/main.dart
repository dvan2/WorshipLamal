import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/song_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://wjqqqjngzurrjejrblfb.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndqcXFxam5nenVycmplanJibGZiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIxNzMzMDUsImV4cCI6MjA2Nzc0OTMwNX0.xFnuSFVeInEIDKYj9zQuZO0j0b15xnzlbyOxnkuWlsA',
  );
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SongListScreen(),
    ),
  );
}
