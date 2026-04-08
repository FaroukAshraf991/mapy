import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mapy/core/utils/responsive.dart';
import 'package:mapy/core/widgets/constrained_content_box.dart';
import 'package:mapy/features/map/models/route_info.dart';
import 'package:mapy/services/voice_navigation_service.dart';

class NavigationGuidanceBar extends StatefulWidget {
  final RouteInfo routeInfo;
  final int currentStepIndex;
  final double distanceToNextStep;
  final bool isDark;
  final double currentSpeed;

  const NavigationGuidanceBar({
    super.key,
    required this.routeInfo,
    required this.currentStepIndex,
    required this.distanceToNextStep,
    required this.isDark,
    this.currentSpeed = 0.0,
  });

  @override
  State<NavigationGuidanceBar> createState() => _NavigationGuidanceBarState();
}

class _NavigationGuidanceBarState extends State<NavigationGuidanceBar> {
  late bool _voiceEnabled;

  @override
  void initState() {
    super.initState();
    _voiceEnabled = VoiceNavigationService.isEnabled;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.routeInfo.steps.isEmpty ||
        widget.currentStepIndex >= widget.routeInfo.steps.length) {
      return const SizedBox.shrink();
    }

    final step = widget.routeInfo.steps[widget.currentStepIndex];

    final distanceText = widget.distanceToNextStep > 1000
        ? (widget.distanceToNextStep / 1000).toStringAsFixed(1)
        : widget.distanceToNextStep.round().toString();
    final distanceUnit = widget.distanceToNextStep > 1000 ? 'km' : 'm';

    return ConstrainedContentBox(
      child: Hero(
      tag: 'navigationGuidance',
      child: Container(
        margin: EdgeInsets.symmetric(
            horizontal: context.w(8), vertical: context.h(8)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.r(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: context.w(20),
              offset: Offset(0, context.h(10)),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(context.r(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: context.w(16), vertical: context.h(12)),
              decoration: BoxDecoration(
                color: widget.isDark
                    ? Colors.black.withValues(alpha: 0.65)
                    : Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(context.r(20)),
                border: Border.all(
                  color: widget.isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(context.w(10)),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.blueAccent.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      step.icon,
                      color: Colors.blueAccent,
                      size: context.sp(26),
                    ),
                  ),
                  SizedBox(width: context.w(14)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              '$distanceText $distanceUnit',
                              style: TextStyle(
                                color: widget.isDark
                                    ? Colors.white70
                                    : Colors.black54,
                                fontSize: context.sp(14),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            if (widget.currentSpeed > 0) ...[
                              SizedBox(width: context.w(16)),
                              Flexible(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: context.w(10),
                                    vertical: context.h(4),
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.2),
                                    borderRadius:
                                        BorderRadius.circular(context.r(12)),
                                  ),
                                  child: Text(
                                    '${widget.currentSpeed.round()} km/h',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: context.sp(12),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: context.h(2)),
                        Text(
                          step.instruction,
                          style: TextStyle(
                            color:
                                widget.isDark ? Colors.white : Colors.black87,
                            fontSize: context.sp(19),
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: context.w(12)),
                  Semantics(
                    button: true,
                    label: _voiceEnabled ? 'Mute navigation voice' : 'Unmute navigation voice',
                    child: GestureDetector(
                    onTap: () async {
                      await VoiceNavigationService.setEnabled(!_voiceEnabled);
                      setState(() {
                        _voiceEnabled = VoiceNavigationService.isEnabled;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(context.w(10)),
                      decoration: BoxDecoration(
                        color: widget.isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _voiceEnabled
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        color: widget.isDark ? Colors.white70 : Colors.black54,
                        size: context.sp(22),
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
    ),
    );
  }
}
