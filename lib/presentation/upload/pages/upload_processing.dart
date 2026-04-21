import 'dart:async';

import 'package:flutter/material.dart';
import 'package:spotify_with_flutter/common/widgets/appbar/app_bar.dart';
import 'package:spotify_with_flutter/common/widgets/button/basic_app_button.dart';
import 'package:spotify_with_flutter/core/configs/theme/app_color.dart';
import 'package:spotify_with_flutter/data/sources/song/song_api_service.dart';
import 'package:spotify_with_flutter/data/sources/upload/upload_api_service.dart';
import 'package:spotify_with_flutter/domain/entities/songs/songs.dart';
import 'package:spotify_with_flutter/presentation/lecture/pages/lecture_detail.dart';
import 'package:spotify_with_flutter/service_locator.dart';

class UploadProcessingPage extends StatefulWidget {
  final String documentId;

  const UploadProcessingPage({
    super.key,
    required this.documentId,
  });

  @override
  State<UploadProcessingPage> createState() => _UploadProcessingPageState();
}

class _UploadProcessingPageState extends State<UploadProcessingPage> {
  Timer? _pollTimer;
  bool _isLoading = true;
  bool _isOpeningLecture = false;
  String? _errorMessage;
  Map<String, dynamic>? _statusData;

  @override
  void initState() {
    super.initState();
    _loadStatus(startPolling: true);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final processingStatus =
        (_statusData?['processing_status'] as String?) ?? 'queued';
    final documentStatus =
        (_statusData?['document_status'] as String?) ?? 'uploaded';
    final lectureId = _statusData?['lecture_id'] as String?;
    final isReady =
        processingStatus == 'completed' && documentStatus == 'completed' && lectureId != null;

    return Scaffold(
      appBar: const BasicAppBar(
        title: Text('Processing Lecture'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your notes are being turned into a lecture.',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'We are extracting the content, building the script, and preparing audio sections for playback.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.grey,
              ),
            ),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                color: AppColors.greyWhite,
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _statusRow('Document', documentStatus),
                        const SizedBox(height: 12),
                        _statusRow('Processing', processingStatus),
                        const SizedBox(height: 12),
                        _statusRow(
                          'Voice',
                          (_statusData?['selected_voice'] as String?) ?? 'Unknown',
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: 24),
            if (isReady)
              BasicAppButton(
                onPressed: _isOpeningLecture ? () {} : _openLecture,
                title: _isOpeningLecture ? 'Opening...' : 'Open Lecture',
                textSize: 20,
                weight: FontWeight.w600,
              )
            else
              BasicAppButton(
                onPressed: _loadStatus,
                title: 'Refresh Status',
                textSize: 20,
                weight: FontWeight.w600,
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGrey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _loadStatus({bool startPolling = false}) async {
    final result =
        await sl<UploadApiService>().getUploadStatus(widget.documentId);

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _errorMessage = failure.toString();
        });
      },
      (data) {
        final status = data as Map<String, dynamic>;
        final isComplete = status['processing_status'] == 'completed' &&
            status['document_status'] == 'completed' &&
            status['lecture_id'] != null;

        setState(() {
          _isLoading = false;
          _errorMessage = null;
          _statusData = status;
        });

        if (isComplete) {
          _pollTimer?.cancel();
        } else if (startPolling || _pollTimer == null) {
          _pollTimer?.cancel();
          _pollTimer = Timer.periodic(
            const Duration(seconds: 4),
            (_) => _loadStatus(),
          );
        }
      },
    );
  }

  Future<void> _openLecture() async {
    final lectureId = _statusData?['lecture_id'] as String?;
    if (lectureId == null) {
      return;
    }

    setState(() {
      _isOpeningLecture = true;
    });

    final lecturesResult = await sl<SongApiService>().getPlayList();

    if (!mounted) return;

    lecturesResult.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.toString())),
        );
      },
      (items) {
        final lectures = (items as List<SongEntity>);
        final match = lectures.where((lecture) => lecture.songId == lectureId);
        if (match.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lecture is ready but could not be opened yet.')),
          );
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LectureDetailPage(lecture: match.first),
          ),
        );
      },
    );

    if (!mounted) return;
    setState(() {
      _isOpeningLecture = false;
    });
  }
}
