import 'package:flutter/material.dart';
import 'package:worship_lamal/features/songs/data/repositories/auth_repository.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _repo = AuthRepository();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Check if we are currently a Guest
    final isGuest = _repo.currentUser?.isAnonymous ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(isGuest ? "Save Your Account" : "Create Account"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            if (isGuest) ...[
              const Text(
                "Upgrade to save your setlists permanently.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ],
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _handleSignUp(isGuest),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isGuest ? 'Save Account' : 'Create Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSignUp(bool isGuest) async {
    // 1. Validation
    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (isGuest) {
        // SCENARIO A: Upgrade the existing Guest user
        // This keeps the same User ID, so data is preserved!
        await _repo.upgradeGuestAccount(email, password);

        if (mounted) {
          Navigator.pop(context); // Return to Profile Tab
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account saved successfully!')),
          );
        }
      } else {
        // SCENARIO B: Brand new user
        await _repo.signUp(email, password);

        if (mounted) {
          Navigator.pop(context); // Return to Login
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account Created! Please Sign In.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Parse common Supabase errors
        String message = e.toString();
        if (message.contains("User already registered")) {
          message = "This email is already in use.";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.replaceAll('AuthException:', '').trim()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
