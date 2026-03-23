import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/usage_service.dart';
import '../widgets/auth_wall.dart';
import '../widgets/paywall.dart';
import '../widgets/usage_banner.dart';
import '../widgets/shimmer_loading.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedType = 'All';

  final List<String> _textTypes = [
    'All',
    'Email',
    'Contract',
    'Medical Bill',
    'Legal',
    'Marketing',
  ];

  static const String _emailExample =
      'Hi, I noticed your account has been flagged for unusual activity. To avoid suspension, please verify your identity by clicking the link below within 24 hours. Failure to do so will result in permanent account closure. This is an automated message \u2014 do not reply.';

  static const String _contractExample =
      'The Company reserves the right to modify these terms at any time without prior notice. By continuing to use the service, you agree to be bound by the modified terms. The Company shall not be liable for any indirect, incidental, or consequential damages arising from your use of the service.';

  static const String _marketingExample =
      'LAST CHANCE! Only 3 spots remaining at this price. Our exclusive program has helped 10,000+ people achieve financial freedom. Join now for just \$997 (was \$4,997 \u2014 80% OFF). This offer expires in 2 hours. Don\'t miss out on the opportunity of a lifetime!';

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _analyzeText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() => _errorMessage = 'Please enter some text to analyze.');
      return;
    }

    // Check usage limits
    final isSignedIn = AuthService.isSignedIn;
    final isProUser = UsageService.isPro();
    final status = UsageService.canUse(isSignedIn, isProUser);

    if (status == UsageStatus.requiresSignIn) {
      final result = await AuthWall.show(context);
      if (result != true) return;
      setState(() {}); // Refresh UI after sign-in
      return;
    }

    if (status == UsageStatus.requiresDailyWait) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Daily limit reached. Come back tomorrow or upgrade to Pro!'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      await Paywall.show(context, onPurchased: () => setState(() {}));
      return;
    }

    if (status == UsageStatus.requiresPro) {
      await Paywall.show(context, onPurchased: () => setState(() {}));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    HapticFeedback.mediumImpact();

    try {
      final contextPrefix =
          _selectedType != 'All' ? '[Text type: $_selectedType] ' : '';
      final result = await ApiService.analyzeText('$contextPrefix$text');
      await StorageService.addToHistory(result);
      await UsageService.incrementUse(isSignedIn);

      if (!mounted) return;

      HapticFeedback.lightImpact();

      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              ResultScreen(result: result),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.03),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'An unexpected error occurred: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pasteFromClipboard() async {
    HapticFeedback.selectionClick();
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      setState(() {
        _textController.text = data.text!;
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: _textController.text.length),
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Text pasted from clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final analysisCount = StorageService.getAnalysisCount();

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              title: Text(
                'Contextify',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton.filled(
                    onPressed: () {},
                    style: IconButton.styleFrom(
                      backgroundColor:
                          colorScheme.primaryContainer.withValues(alpha: 0.5),
                      foregroundColor: colorScheme.onPrimaryContainer,
                    ),
                    icon: const Icon(Icons.person_rounded, size: 20),
                  ),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Greeting banner card (glassmorphism)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primaryContainer.withValues(alpha: 0.4),
                          colorScheme.primaryContainer.withValues(alpha: 0.15),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What would you like to decode?',
                          style: GoogleFonts.dmSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          analysisCount > 0
                              ? '$analysisCount texts decoded so far'
                              : 'Paste any text to uncover what\'s hidden',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.05, end: 0),

                  const SizedBox(height: 12),

                  // Usage banner
                  const UsageBanner(),

                  const SizedBox(height: 20),

                  // Filter chips row
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _textTypes.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final type = _textTypes[index];
                        final isSelected = _selectedType == type;
                        return FilterChip(
                          label: Text(type),
                          selected: isSelected,
                          onSelected: (selected) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedType = selected ? type : 'All';
                            });
                          },
                          showCheckmark: false,
                          selectedColor: colorScheme.primaryContainer,
                          labelStyle: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 100.ms, duration: 400.ms),

                  const SizedBox(height: 20),

                  // Text input area
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _textController.text.isNotEmpty
                            ? colorScheme.primary.withValues(alpha: 0.3)
                            : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _textController,
                          maxLines: 8,
                          minLines: 5,
                          style: theme.textTheme.bodyLarge,
                          decoration: InputDecoration(
                            hintText: 'Paste any text here...',
                            hintStyle: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                            ),
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.fromLTRB(
                                24, 20, 24, 4),
                            suffixIcon: Padding(
                              padding: const EdgeInsets.only(right: 8, top: 4),
                              child: IconButton(
                                icon: Icon(
                                  Icons.content_paste_rounded,
                                  color: colorScheme.primary,
                                  size: 22,
                                ),
                                onPressed: _pasteFromClipboard,
                                tooltip: 'Paste from clipboard',
                              ),
                            ),
                          ),
                        ),
                        // Character count
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '${_textController.text.length} chars',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 400.ms),

                  // Error message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded,
                              color: colorScheme.onErrorContainer, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 300.ms)
                        .shake(hz: 3, duration: 400.ms),
                  ],

                  const SizedBox(height: 20),

                  // Analyze Button or Loading
                  SizedBox(
                    height: 56,
                    child: _isLoading
                        ? Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  minHeight: 6,
                                  color: colorScheme.primary,
                                  backgroundColor:
                                      colorScheme.primaryContainer,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Analyzing with AI...',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF0D9488),
                                  const Color(0xFF0F766E),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0D9488)
                                      .withValues(alpha: 0.25),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _analyzeText,
                                borderRadius: BorderRadius.circular(16),
                                child: Center(
                                  child: Text(
                                    'Decode Text \u2192',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 400.ms),

                  // Loading skeleton
                  if (_isLoading) ...[
                    const SizedBox(height: 32),
                    const ShimmerLoading(),
                  ],

                  // Example suggestions (when text is empty)
                  if (!_isLoading && _textController.text.isEmpty) ...[
                    const SizedBox(height: 40),
                    _buildExamplesSection(theme, colorScheme),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamplesSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Try an example',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              _buildExampleCard(
                theme: theme,
                colorScheme: colorScheme,
                emoji: '\u{1F4E7}',
                title: 'Suspicious Email',
                preview: 'Account flagged for unusual activity...',
                accentColor: const Color(0xFF0D9488),
                text: _emailExample,
              ),
              const SizedBox(width: 12),
              _buildExampleCard(
                theme: theme,
                colorScheme: colorScheme,
                emoji: '\u{1F4DC}',
                title: 'Contract Clause',
                preview: 'The Company reserves the right to...',
                accentColor: const Color(0xFF7C3AED),
                text: _contractExample,
              ),
              const SizedBox(width: 12),
              _buildExampleCard(
                theme: theme,
                colorScheme: colorScheme,
                emoji: '\u{1F4E2}',
                title: 'Marketing Trick',
                preview: 'LAST CHANCE! Only 3 spots remaining...',
                accentColor: const Color(0xFFF59E0B),
                text: _marketingExample,
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms, duration: 600.ms);
  }

  Widget _buildExampleCard({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required String emoji,
    required String title,
    required String preview,
    required Color accentColor,
    required String text,
  }) {
    return SizedBox(
      width: 280,
      child: Material(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _textController.text = text;
              _textController.selection = TextSelection.fromPosition(
                TextPosition(offset: _textController.text.length),
              );
            });
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: accentColor, width: 4),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  preview,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
