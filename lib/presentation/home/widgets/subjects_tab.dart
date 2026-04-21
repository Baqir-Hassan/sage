import 'package:flutter/material.dart';
import 'package:spotify_with_flutter/core/configs/theme/app_color.dart';
import 'package:spotify_with_flutter/data/sources/song/song_api_service.dart';
import 'package:spotify_with_flutter/presentation/subject/pages/subject_detail.dart';
import 'package:spotify_with_flutter/service_locator.dart';

class SubjectsTab extends StatefulWidget {
  const SubjectsTab({super.key});

  @override
  State<SubjectsTab> createState() => _SubjectsTabState();
}

class _SubjectsTabState extends State<SubjectsTab> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _subjects = [];

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await sl<SongApiService>().getSubjects();
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
          _subjects = (data as List<dynamic>).cast<Map<String, dynamic>>();
        });
      },
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

    if (_subjects.isEmpty) {
      return const Center(child: Text('No subjects yet.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _subjects.length,
      itemBuilder: (context, index) {
        final subject = _subjects[index];
        final name = subject['name'] as String? ?? 'Untitled Subject';
        final description = subject['description'] as String?;
        final lectureCount = (subject['lecture_count'] as num?)?.toInt() ?? 0;
        final lectureCountLabel =
            lectureCount == 1 ? '1 lecture' : '$lectureCount lectures';
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () {
              final subjectId = subject['id'] as String?;
              if (subjectId == null || subjectId.isEmpty) {
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SubjectDetailPage(
                    subjectId: subjectId,
                    subjectName: name,
                    subjectDescription: description,
                  ),
                ),
              );
            },
            child: Ink(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: AppColors.metalDark,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    (description != null && description.isNotEmpty)
                        ? description
                        : 'Subject generated from your uploaded lectures.',
                    style: const TextStyle(
                      color: AppColors.greyTitle,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    lectureCountLabel,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
    );
  }
}
