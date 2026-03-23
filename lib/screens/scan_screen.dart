import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/usage_service.dart';
import '../widgets/auth_wall.dart';
import '../widgets/shimmer_loading.dart';
import 'result_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedType = 'Medical Bill';

  final List<String> _docTypes = [
    'Medical Bill',
    'Contract',
    'Legal Notice',
    'Insurance',
  ];

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

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (photo != null) {
        setState(() {
          _selectedImage = photo;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Could not access camera: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Could not access gallery: $e');
    }
  }

  Future<void> _analyzeText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(
          () => _errorMessage = 'Please type or paste the document text below.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Usage check
    final isSignedIn = AuthService.isSignedIn;
    if (UsageService.needsSignIn(isSignedIn)) {
      await AuthWall.show(context);
      if (mounted) setState(() {});
      setState(() => _isLoading = false);
      return;
    }

    HapticFeedback.mediumImpact();

    try {
      final contextPrefix = '[Document type: $_selectedType] ';
      final result = await ApiService.analyzeText('$contextPrefix$text');
      await StorageService.addToHistory(result);

      // Increment usage only if not signed in
      if (!AuthService.isSignedIn) {
        await UsageService.incrementUse();
      }

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              title: Text(
                'Scan Document',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Hero illustration area
                  if (_selectedImage == null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D9488)
                                  .withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.document_scanner_rounded,
                              size: 80,
                              color: const Color(0xFF0D9488)
                                  .withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Capture or upload a document',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.05, end: 0),
                    const SizedBox(height: 20),
                  ],

                  // Image preview
                  if (_selectedImage != null) ...[
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(
                            File(_selectedImage!.path),
                            height: 250,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Material(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                setState(() => _selectedImage = null);
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(Icons.close_rounded,
                                    color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(duration: 300.ms)
                        .scale(
                          begin: const Offset(0.96, 0.96),
                          end: const Offset(1, 1),
                        ),
                    const SizedBox(height: 20),
                  ],

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: FilledButton.tonal(
                            onPressed: _takePhoto,
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('\u{1F4F7}',
                                    style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Text(
                                  'Camera',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: OutlinedButton(
                            onPressed: _pickFromGallery,
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('\u{1F5BC}\u{FE0F}',
                                    style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Text(
                                  'Gallery',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(delay: 100.ms, duration: 400.ms),

                  const SizedBox(height: 24),

                  // Document type chips
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _docTypes.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final type = _docTypes[index];
                        final isSelected = _selectedType == type;
                        return FilterChip(
                          label: Text(type),
                          selected: isSelected,
                          onSelected: (selected) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedType =
                                  selected ? type : 'Medical Bill';
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
                      .fadeIn(delay: 200.ms, duration: 400.ms),

                  const SizedBox(height: 20),

                  // Text input
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _textController.text.isNotEmpty
                            ? colorScheme.primary.withOpacity(0.3)
                            : Colors.transparent,
                      ),
                    ),
                    child: TextField(
                      controller: _textController,
                      maxLines: 8,
                      minLines: 5,
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText:
                            'Add context or paste document text...',
                        hintStyle: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant
                              .withOpacity(0.5),
                        ),
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.all(24),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 400.ms),

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

                  // Analyze button
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
                                'Analyzing document...',
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
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF0D9488),
                                  Color(0xFF0F766E),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0D9488)
                                      .withOpacity(0.25),
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
                                    'Analyze Document \u2192',
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
                      .fadeIn(delay: 400.ms, duration: 400.ms),

                  if (_isLoading) ...[
                    const SizedBox(height: 32),
                    const ShimmerLoading(),
                  ],

                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
