import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worship_lamal/features/profile/data/repositories/auth_repository.dart';
import 'package:worship_lamal/features/setlists/data/remote/setlists_api.dart';
import 'package:worship_lamal/features/setlists/data/repositories/setlist_repository.dart';
import 'package:worship_lamal/features/songs/data/remote/songs_api.dart';
import 'package:worship_lamal/features/songs/data/repositories/songs_repository.dart';
import 'package:worship_lamal/features/userkey/data/remote/user_keys_api.dart';
import 'package:worship_lamal/features/userkey/data/repositories/user_keys_repository.dart';

class MockSongsApi extends Mock implements SongsApi {}
class MockSongsRepository extends Mock implements SongsRepository {}
class MockSetlistsApi extends Mock implements SetlistsApi {}
class MockSetlistRepository extends Mock implements SetlistRepository {}
class MockUserKeysApi extends Mock implements UserKeysApi {}
class MockUserKeysRepository extends Mock implements UserKeysRepository {}
class MockAuthRepository extends Mock implements AuthRepository {}
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockUser extends Mock implements User {}
