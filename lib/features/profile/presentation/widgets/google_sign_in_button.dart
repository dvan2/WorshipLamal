import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worship_lamal/features/profile/presentation/providers/auth_provider.dart';

/// Shared button for initiating Google OAuth sign-in or guest identity linking.
class GoogleSignInButton extends ConsumerStatefulWidget {
  final bool enabled;
  final String label;
  final bool linkGuestIdentity;

  const GoogleSignInButton({
    super.key,
    this.enabled = true,
    this.label = 'Continue with Google',
    this.linkGuestIdentity = false,
  });

  @override
  ConsumerState<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends ConsumerState<GoogleSignInButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = !widget.enabled || _isLoading;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: isDisabled ? null : _handleGoogleSignIn,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        icon: _isLoading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.g_mobiledata, size: 24),
        label: Text(widget.label),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .signInWithGoogle(linkGuestIdentity: widget.linkGuestIdentity);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Google Sign-In failed: ${e.toString().replaceAll('AuthException:', '').trim()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
