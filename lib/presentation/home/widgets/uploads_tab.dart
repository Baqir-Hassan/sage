import 'package:flutter/material.dart';
import 'package:spotify_with_flutter/core/configs/theme/app_color.dart';
import 'package:spotify_with_flutter/data/sources/song/song_api_service.dart';
import 'package:spotify_with_flutter/data/sources/upload/upload_api_service.dart';
import 'package:spotify_with_flutter/service_locator.dart';

class UploadsTab extends StatefulWidget {
  const UploadsTab({super.key});

  @override
  State<UploadsTab> createState() => _UploadsTabState();
}

class _UploadsTabState extends State<UploadsTab> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _uploads = [];

  @override
  void initState() {
    super.initState();
    _loadUploads();
  }

  Future<void> _loadUploads() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await sl<UploadApiService>().listUploads();
    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _error = failure.toString();
        });
      },
      (data) {
        setState(() {
          _isLoading = false;
          _uploads = (data as List<dynamic>).cast<Map<String, dynamic>>();
        });
      },
    );
  }

  Future<void> _deleteUpload(String documentId) async {
    final result = await sl<UploadApiService>().deleteUpload(documentId);
    if (!mounted) return;
    result.fold(
      (failure) => _showSnack(failure.toString()),
      (_) {
        _showSnack('Upload deleted');
        _loadUploads();
      },
    );
  }

  Future<void> _deleteLecture(String lectureId) async {
    final result = await sl<SongApiService>().deleteLecture(lectureId);
    if (!mounted) return;
    result.fold(
      (failure) => _showSnack(failure.toString()),
      (_) {
        _showSnack('Lecture deleted');
        _loadUploads();
      },
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_uploads.isEmpty) {
      return const Center(child: Text('No uploads yet.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _uploads.length,
      itemBuilder: (context, index) {
        final upload = _uploads[index];
        final filename = upload['original_filename'] as String? ?? 'Unknown file';
        final status = upload['document_status'] as String? ?? 'unknown';
        final lectureId = upload['lecture_id'] as String?;
        final voice = upload['selected_voice'] as String? ?? 'female';
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: AppColors.metalDark,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                filename,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Status: $status',
                style: const TextStyle(
                  color: AppColors.greyTitle,
                ),
              ),
              Text(
                'Voice: $voice',
                style: const TextStyle(
                  color: AppColors.greyTitle,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (lectureId != null)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.white,
                        side: const BorderSide(color: AppColors.grey),
                      ),
                      onPressed: () => _deleteLecture(lectureId),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Delete Lecture'),
                    ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.greyTitle,
                    ),
                    onPressed: () => _deleteUpload(upload['document_id'] as String),
                    icon: const Icon(Icons.folder_delete_outlined),
                    label: const Text('Delete File'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
    );
  }
}
