import 'package:flutter/material.dart';
import 'package:sage/core/configs/theme/app_color.dart';
import 'package:sage/data/sources/lecture/lecture_api_service.dart';
import 'package:sage/presentation/subject/pages/subject_detail.dart';
import 'package:sage/service_locator.dart';

class SubjectsTab extends StatefulWidget {
  const SubjectsTab({super.key});

  @override
  State<SubjectsTab> createState() => _SubjectsTabState();
}

class _SubjectsTabState extends State<SubjectsTab> {
  bool _isLoading = true;
  String? _deletingSubjectId;
  String? _error;
  List<Map<String, dynamic>> _subjects = [];

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _confirmDeleteSubject(Map<String, dynamic> subject) async {
    final subjectId = subject['id'] as String?;
    final subjectName = subject['name'] as String? ?? 'this subject';
    if (subjectId == null || subjectId.isEmpty) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete subject?'),
            content: Text(
              'This will remove the subject grouping, but keep all of its lectures and audio. '
              '$subjectName will be detached from related uploads and playlists.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete) {
      return;
    }

    setState(() {
      _deletingSubjectId = subjectId;
    });

    final result = await sl<LectureApiService>().deleteSubject(subjectId);
    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _deletingSubjectId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.toString())),
        );
      },
      (_) {
        setState(() {
          _deletingSubjectId = null;
          _subjects.removeWhere((item) => item['id'] == subjectId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$subjectName deleted.')),
        );
      },
    );
  }

  Future<void> _loadSubjects() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await sl<LectureApiService>().getSubjects();
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (_deletingSubjectId == subject['id'])
                        const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          splashRadius: 18,
                          onPressed: () => _confirmDeleteSubject(subject),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.greyTitle,
                          ),
                        ),
                    ],
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
