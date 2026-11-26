import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worship_lamal/core/services/push_notification_provider.dart';
import 'package:worship_lamal/features/profile/data/repositories/auth_repository.dart';
import 'package:worship_lamal/features/profile/presentation/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign In")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
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
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(),
                      )
                    : const Text('Sign In'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email and password.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final isGuest = repo.currentUser?.isAnonymous ?? false;

      if (isGuest) {
        GuestDataSummary summary = const GuestDataSummary();
        try {
          summary = await repo.getGuestDataSummary();
        } catch (_) {
          // Do not block legitimate login on transient check failures.
        }

        if (summary.hasAny) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          final confirmed = await _confirmLeaveGuestData(summary);
          if (confirmed != true) return;
          if (!mounted) return;
          setState(() => _isLoading = true);
        }

        if (kIsWeb) {
          try {
            final sub = await ref
                .read(pushNotificationServiceProvider)
                .getCurrentSubscription();
            if (sub != null) {
              await ref
                  .read(pushSubscriptionRepositoryProvider)
                  .deleteSubscription(sub.endpoint);
            }
          } catch (_) {
            // Do not block login if push cleanup fails.
          }
        }
      }

      await repo.signIn(email, password);

      if (mounted) {
        // Success! Pop back to ProfileTab (which will auto-refresh to show Logged In view)
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool?> _confirmLeaveGuestData(GuestDataSummary summary) {
    final items = <String>[
      if (summary.hasSetlists) 'setlists',
      if (summary.hasUserKeys) 'custom song keys',
      if (summary.hasFavorites) 'favorites',
    ];

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Switch Away From Guest Session?'),
        content: Text(
          'Your guest session has unsaved ${items.join(', ')}. '
          'Signing into an existing account will leave this guest data behind.\n\n'
          'To keep your guest data, cancel and use "Create Account / Sync Data" instead.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continue Sign In'),
          ),
        ],
      ),
    );
  }
}
