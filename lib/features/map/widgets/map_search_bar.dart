import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mapy/core/constants/app_strings.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class MapSearchBar extends StatefulWidget {
  final bool isDark;
  final bool isRouting;
  final String userName;
  final VoidCallback onSearchTap;
  final VoidCallback onAvatarTap;
  final Function(String)? onVoiceResult;

  const MapSearchBar({
    super.key,
    required this.isDark,
    required this.isRouting,
    required this.userName,
    required this.onSearchTap,
    required this.onAvatarTap,
    this.onVoiceResult,
  });

  @override
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    final available = await _speech.initialize(
      onError: (_) => setState(() => _isListening = false),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _isListening = false);
        }
      },
    );

    if (!available) return;

    setState(() => _isListening = true);
    _speech.listen(
      onResult: (result) {
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          setState(() => _isListening = false);
          widget.onVoiceResult?.call(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(32)),
        boxShadow: [
          BoxShadow(
            color:
                widget.isDark ? Colors.black45 : Colors.black.withValues(alpha: 0.1),
            blurRadius: context.w(20),
            offset: Offset(0, context.h(10)),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.r(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: context.w(12), vertical: context.h(8)),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? Colors.black.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(context.r(32)),
              border: Border.all(
                color: widget.isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: InkWell(
              onTap: widget.onSearchTap,
              borderRadius: BorderRadius.circular(context.r(32)),
              child: Row(
                children: [
                  SizedBox(width: context.w(8)),
                  Image.asset(
                      'assets/icon/ticon.png',
                      width: context.sp(28),
                      height: context.sp(28),
                    ),
                  SizedBox(width: context.w(14)),
                  Expanded(
                    child: Text(
                      AppStrings.searchHere,
                      style: TextStyle(
                        fontSize: context.sp(17),
                        color: widget.isDark ? Colors.white70 : Colors.black87,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (widget.isRouting)
                    Padding(
                      padding: EdgeInsets.only(right: context.w(12)),
                      child: SizedBox(
                        width: context.w(20),
                        height: context.h(20),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.blueAccent),
                      ),
                    ),
                  // Mic button
                  GestureDetector(
                    onTap: _toggleListening,
                    child: Padding(
                      padding: EdgeInsets.only(right: context.w(10)),
                      child: _isListening
                          ? AnimatedBuilder(
                              animation: _pulseAnim,
                              builder: (_, __) => Opacity(
                                opacity: _pulseAnim.value,
                                child: Icon(
                                  Icons.mic,
                                  color: Colors.redAccent,
                                  size: context.sp(22),
                                ),
                              ),
                            )
                          : Icon(
                              Icons.mic_none_rounded,
                              color: widget.isDark
                                  ? Colors.white60
                                  : Colors.black54,
                              size: context.sp(22),
                            ),
                    ),
                  ),
                  Hero(
                    tag: 'profileAvatar',
                    child: GestureDetector(
                      onTap: widget.onAvatarTap,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.cyanAccent.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                          boxShadow: [
                            if (widget.isDark)
                              BoxShadow(
                                color: Colors.cyanAccent.withValues(alpha: 0.2),
                                blurRadius: context.w(8),
                                spreadRadius: context.w(1),
                              ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: context.r(18),
                          backgroundColor: widget.isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.blueAccent.withValues(alpha: 0.15),
                          child: Text(
                            widget.userName.isNotEmpty
                                ? widget.userName[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              color: widget.isDark ? Colors.white : Colors.blueAccent,
                              fontSize: context.sp(14),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
