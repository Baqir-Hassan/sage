import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const MusicPlayerWidget(),
    );
  }
}

class MusicPlayerWidget extends StatefulWidget {
  const MusicPlayerWidget({super.key});

  @override
  State<MusicPlayerWidget> createState() => _MusicPlayerWidgetState();
}

class _MusicPlayerWidgetState extends State<MusicPlayerWidget>
    with SingleTickerProviderStateMixin {
  bool isPlaying = true;
  bool isShuffled = false;
  double progress = 0.35; // 0.0 to 1.0
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  String _formatTime(double progress, double totalSeconds) {
    final seconds = (progress * totalSeconds).round();
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final totalDuration = 220.0; // 3:40 in seconds

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          width: 380,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            image: const DecorationImage(
              image: NetworkImage(
                'https://images.unsplash.com/photo-1493225255756-d9584f8606e9?w=800&q=80',
              ),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black54,
                BlendMode.darken,
              ),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Subtle gradient overlay for depth
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.4),
                      ],
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: Spotify icon + playlist name
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.music_note,
                              size: 14,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'ARCADE 800',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Song title
                      const Text(
                        'Hanju Akhiyan De Vehre - Remix',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Artist name
                      const Text(
                        'Nusrat Fateh Ali Khan, Afternight Vibes',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const Spacer(),

                      // Waveform Progress Bar
                      GestureDetector(
                        onTapDown: (details) {
                          final box = context.findRenderObject() as RenderBox;
                          final localPosition = box.globalToLocal(details.globalPosition);
                          setState(() {
                            progress = ((localPosition.dx - 16) / (380 - 32)).clamp(0.0, 1.0);
                          });
                        },
                        onHorizontalDragUpdate: (details) {
                          setState(() {
                            progress += details.delta.dx / (380 - 32);
                            progress = progress.clamp(0.0, 1.0);
                          });
                        },
                        child: SizedBox(
                          height: 40,
                          child: Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              // Background waveform
                              AnimatedBuilder(
                                animation: _waveController,
                                builder: (context, child) {
                                  return CustomPaint(
                                    size: const Size(348, 40),
                                    painter: WaveformPainter(
                                      progress: 1.0,
                                      color: Colors.white.withOpacity(0.2),
                                      animation: _waveController.value,
                                      isBackground: true,
                                    ),
                                  );
                                },
                              ),
                              // Active waveform (filled portion)
                              ClipRect(
                                child: AnimatedBuilder(
                                  animation: _waveController,
                                  builder: (context, child) {
                                    return CustomPaint(
                                      size: Size(348 * progress, 40),
                                      painter: WaveformPainter(
                                        progress: progress,
                                        color: const Color(0xFFE8A87C), // Warm beige/gold
                                        animation: _waveController.value,
                                        isBackground: false,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              // Draggable thumb
                              Positioned(
                                left: (348 * progress) - 6,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5D0A9),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Time indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatTime(progress, totalDuration),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '03:40',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Controls row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Shuffle
                          IconButton(
                            icon: Icon(
                              Icons.shuffle,
                              color: isShuffled
                                  ? const Color(0xFFE8A87C)
                                  : Colors.white70,
                              size: 22,
                            ),
                            onPressed: () {
                              setState(() {
                                isShuffled = !isShuffled;
                              });
                            },
                          ),

                          // Previous
                          IconButton(
                            icon: const Icon(
                              Icons.skip_previous,
                              color: Colors.white,
                              size: 32,
                            ),
                            onPressed: () {},
                          ),

                          // Play/Pause
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                isPlaying = !isPlaying;
                                if (isPlaying) {
                                  _waveController.repeat();
                                } else {
                                  _waveController.stop();
                                }
                              });
                            },
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),

                          // Next
                          IconButton(
                            icon: const Icon(
                              Icons.skip_next,
                              color: Colors.white,
                              size: 32,
                            ),
                            onPressed: () {},
                          ),

                          // Verified/Liked checkmark
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.black,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom waveform painter that creates the shutter-style wave
class WaveformPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double animation;
  final bool isBackground;

  WaveformPainter({
    required this.progress,
    required this.color,
    required this.animation,
    required this.isBackground,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final width = size.width;
    final height = size.height;
    final centerY = height / 2;
    final barWidth = 3.0;
    final gap = 2.5;
    final totalBars = (width / (barWidth + gap)).floor();

    for (int i = 0; i < totalBars; i++) {
      final x = i * (barWidth + gap) + barWidth / 2;
      
      // Create wave pattern using sine waves with animation
      double amplitude;
      if (isBackground) {
        // Static gentle wave for background
        amplitude = math.sin(i * 0.15) * 0.4 + 0.5;
        amplitude += math.sin(i * 0.05 + animation * math.pi * 2) * 0.15;
      } else {
        // Animated active wave
        amplitude = math.sin(i * 0.12 + animation * math.pi * 2) * 0.35 + 0.55;
        // Add some randomness for "shutter" effect
        amplitude += math.sin(i * 0.3 + animation * math.pi * 4) * 0.15;
      }

      // Clamp amplitude
      amplitude = amplitude.clamp(0.15, 0.95);

      final barHeight = height * amplitude;
      final top = centerY - barHeight / 2;
      final bottom = centerY + barHeight / 2;

      // Draw rounded bar
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(x - barWidth / 2, top, x + barWidth / 2, bottom),
        const Radius.circular(2),
      );
      
      canvas.drawRRect(rect, paint..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.animation != animation ||
        oldDelegate.progress != progress ||
        oldDelegate.color != color;
  }
}