import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worship_lamal/features/profile/presentation/login_screen.dart';
import 'package:worship_lamal/features/profile/presentation/signup_screen.dart';
import 'package:worship_lamal/features/songs/data/repositories/auth_repository.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _repo = AuthRepository();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // 1. Check if User is Logged In
    final user = _repo.currentUser;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (user.isAnonymous) {
      return _buildGuestView();
    }

    // 2. Otherwise, they are a full User
    return _buildLoggedInView(user);
  }

  Widget _buildGuestView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_outline, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              "Guest Account",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "You can create Setlists, but they will be lost if you delete the app.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Navigate to Signup to "Upgrade" this account
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignUpScreen()),
                );
              },
              child: const Text("Create Account to Save Data"),
            ),
            TextButton(
              onPressed: () {
                // Navigate to Login (if they have an existing account elsewhere)
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text("I already have an account"),
            ),
          ],
        ),
      ),
    );
  }

  // VIEW 1: The Dashboard
  Widget _buildLoggedInView(User user) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_circle, size: 80, color: Colors.blue),
          const SizedBox(height: 16),
          Text(user.email ?? 'Anonymous User'),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () async {
              await _repo.signOut();
              setState(() {}); // Refresh UI
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Welcome Back",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Only Email & Password needed here
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              // Notice: No boolean flag anymore, this is ALWAYS login
              onPressed: () => _handleAuth(),
              child: const Text('Sign In'),
            ),
          ),
          const SizedBox(height: 16),

          // The Link to the new screen
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SignUpScreen()),
              );
            },
            child: const Text("Don't have an account? Sign Up"),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAuth() async {
    // 1. Start Loading
    setState(() => _isLoading = true);

    try {
      // 2. Call the Repository (Sign In Only)
      // We add .trim() to remove accidental spaces users might type
      await _repo.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // 3. Success
      // We call setState to rebuild the widget.
      // Since _repo.currentUser is now valid, build() will switch to the LoggedInView.
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // 4. Error Handling
      if (mounted) {
        // Parse the error to make it user-friendly, or just show the message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Login Failed: ${e.toString().replaceAll('AuthException:', '').trim()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // 5. Stop Loading
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
