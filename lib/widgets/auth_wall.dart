import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

class AuthWall extends StatefulWidget {
  final VoidCallback? onSignedIn;

  const AuthWall({super.key, this.onSignedIn});

  /// Show the auth wall as a modal bottom sheet
  static Future<bool?> show(BuildContext context, {VoidCallback? onSignedIn}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => AuthWall(onSignedIn: onSignedIn),
    );
  }

  @override
  State<AuthWall> createState() => _AuthWallState();
}

class _AuthWallState extends State<AuthWall> {
  bool _isLoading = false;

  String? _errorMessage;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = await AuthService.signInWithGoogle();
      if (user != null && mounted) {
        widget.onSignedIn?.call();
        Navigator.pop(context, true);
      } else if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Sign-in was cancelled. Please try again.';
        });
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        setState(() {
          _isLoading = false;
          _errorMessage = msg;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in failed: $msg')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 8, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),

          // Close button
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              onPressed: () => Navigator.pop(context, false),
              icon: Icon(Icons.close_rounded,
                  color: colorScheme.onSurfaceVariant),
            ),
          ),

          // Lock icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF0D9488).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '\u{1F512}',
                style: TextStyle(fontSize: 36),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Headline
          Text(
            'Free Trial Complete',
            style: GoogleFonts.dmSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            'You\'ve used 3 free analyses. Sign in with Google for unlimited access \u2014 completely free!',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          // Error message
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _errorMessage!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: colorScheme.onErrorContainer,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Google Sign-In button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: _isLoading ? null : _signInWithGoogle,
              style: OutlinedButton.styleFrom(
                backgroundColor: colorScheme.surface,
                side: BorderSide(
                  color: colorScheme.outlineVariant,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: colorScheme.primary,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Google "G" placeholder
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF4285F4),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'G',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF4285F4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Continue with Google',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Privacy text
          Text(
            'We only access your name and email',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
