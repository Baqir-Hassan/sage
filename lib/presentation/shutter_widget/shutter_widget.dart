import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sage/core/configs/theme/app_color.dart';

class ShutterWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final double progress;
  final Duration elapsed;
  final Duration total;
  final bool isPlaying;
  final VoidCallback onTogglePlayback;
  final ValueChanged<double> onSeek;
  final String? imageUrl;

  const ShutterWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.elapsed,
    required this.total,
    required this.isPlaying,
    required this.onTogglePlayback,
    required this.onSeek,
    this.imageUrl,
  });

  @override
  State<ShutterWidget> createState() => _ShutterWidgetState();
}

class _ShutterWidgetState extends State<ShutterWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant ShutterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying != widget.isPlaying) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (widget.isPlaying) {
      _waveController.repeat();
    } else {
      _waveController.stop();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _handleSeek(Offset localPosition, double width) {
    final normalized = (localPosition.dx / width).clamp(0.0, 1.0);
    widget.onSeek(normalized);
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
        ? NetworkImage(widget.imageUrl!)
        : null;

    return Container(
      constraints: const BoxConstraints(maxWidth: 560),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: AppColors.metalDark,
        image: imageProvider != null
            ? DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover,
                colorFilter: const ColorFilter.mode(
                  Colors.black54,
                  BlendMode.darken,
                ),
              )
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.55),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.record_voice_over_rounded,
                          size: 16,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'SAGE LECTURE',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final waveformWidth = constraints.maxWidth;
                      final thumbOffset =
                          (waveformWidth * widget.progress).clamp(0.0, waveformWidth) - 6;

                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (details) =>
                            _handleSeek(details.localPosition, waveformWidth),
                        onHorizontalDragUpdate: (details) =>
                            _handleSeek(details.localPosition, waveformWidth),
                        child: SizedBox(
                          height: 42,
                          width: waveformWidth,
                          child: Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              AnimatedBuilder(
                                animation: _waveController,
                                builder: (context, _) => CustomPaint(
                                  size: Size(waveformWidth, 42),
                                  painter: WaveformPainter(
                                    color: Colors.white.withOpacity(0.18),
                                    animation: _waveController.value,
                                    isBackground: true,
                                  ),
                                ),
                              ),
                              ClipRect(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: widget.progress.clamp(0.0, 1.0),
                                  child: AnimatedBuilder(
                                    animation: _waveController,
                                    builder: (context, _) => CustomPaint(
                                      size: Size(waveformWidth, 42),
                                      painter: WaveformPainter(
                                        color: const Color(0xFFE7B58B),
                                        animation: _waveController.value,
                                        isBackground: false,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: thumbOffset,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF6D6B5),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.25),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(widget.elapsed),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatDuration(widget.total),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: GestureDetector(
                      onTap: widget.onTogglePlayback,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: Icon(
                          widget.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class WaveformPainter extends CustomPainter {
  final Color color;
  final double animation;
  final bool isBackground;

  WaveformPainter({
    required this.color,
    required this.animation,
    required this.isBackground,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final barWidth = 3.0;
    final gap = 2.5;
    final centerY = size.height / 2;
    final totalBars = (size.width / (barWidth + gap)).floor();

    for (int i = 0; i < totalBars; i++) {
      final x = i * (barWidth + gap) + barWidth / 2;
      double amplitude;
      if (isBackground) {
        amplitude = math.sin(i * 0.16) * 0.35 + 0.52;
        amplitude += math.sin(i * 0.06 + animation * math.pi * 2) * 0.12;
      } else {
        amplitude = math.sin(i * 0.13 + animation * math.pi * 2) * 0.32 + 0.58;
        amplitude += math.sin(i * 0.31 + animation * math.pi * 4) * 0.14;
      }

      amplitude = amplitude.clamp(0.16, 0.95);
      final barHeight = size.height * amplitude;
      final top = centerY - barHeight / 2;
      final bottom = centerY + barHeight / 2;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(x - barWidth / 2, top, x + barWidth / 2, bottom),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.animation != animation ||
        oldDelegate.color != color ||
        oldDelegate.isBackground != isBackground;
  }
}
