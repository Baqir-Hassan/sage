import 'package:flutter/material.dart';
import 'package:sage/common/widgets/appbar/app_bar.dart';
import 'package:sage/core/configs/theme/app_color.dart';
import 'package:sage/data/sources/lecture/lecture_api_service.dart';
import 'package:sage/domain/entities/lectures/lecture.dart';
import 'package:sage/presentation/lecture/pages/lecture_detail.dart';
import 'package:sage/service_locator.dart';

class SubjectDetailPage extends StatefulWidget {
  final String subjectId;
  final String subjectName;
  final String? subjectDescription;

  const SubjectDetailPage({
    super.key,
    required this.subjectId,
    required this.subjectName,
    this.subjectDescription,
  });

  @override
  State<SubjectDetailPage> createState() => _SubjectDetailPageState();
}

class _SubjectDetailPageState extends State<SubjectDetailPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<LectureEntity> _lectures = const [];

  @override
  void initState() {
    super.initState();
    _loadLectures();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BasicAppBar(
        title: Text(widget.subjectName),
      ),
      body: RefreshIndicator(
        onRefresh: _loadLectures,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            _heroCard(),
            const SizedBox(height: 22),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage != null)
              _messageCard(
                title: 'Unable to load lectures',
                subtitle: _errorMessage!,
              )
            else if (_lectures.isEmpty)
              _messageCard(
                title: 'No lectures yet',
                subtitle:
                    'This subject does not have any generated lectures yet. Upload notes to populate it.',
              )
            else
              ..._lectures.map(_lectureTile),
          ],
        ),
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2F2B2B),
            Color(0xFF181818),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Subject Library',
            style: TextStyle(
              color: AppColors.greyTitle,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.subjectName,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            (widget.subjectDescription != null &&
                    widget.subjectDescription!.trim().isNotEmpty)
                ? widget.subjectDescription!
                : 'All lectures currently grouped under this subject.',
            maxLines: 3,
            overflow: TextOverflow.fade,
            style: const TextStyle(
              color: AppColors.greyTitle,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageCard({
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: AppColors.metalDark,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.greyTitle,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _lectureTile(LectureEntity lecture) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.metalDark,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        leading: Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
          ),
          child: const Icon(
            Icons.headphones_rounded,
            color: AppColors.white,
          ),
        ),
        title: Text(
          lecture.title,
          maxLines: 2,
          overflow: TextOverflow.fade,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            lecture.summary,
            maxLines: 2,
            overflow: TextOverflow.fade,
            style: const TextStyle(
              color: AppColors.greyTitle,
            ),
          ),
        ),
        trailing: Text(
          _formatDuration(lecture.duration),
          style: const TextStyle(
            color: AppColors.greyTitle,
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LectureDetailPage(lecture: lecture),
            ),
          );
        },
      ),
    );
  }

  Future<void> _loadLectures() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await sl<LectureApiService>().getSubjectLectures(widget.subjectId);

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _errorMessage = failure.toString();
        });
      },
      (data) {
        setState(() {
          _isLoading = false;
          _lectures = (data as List<dynamic>).cast<LectureEntity>();
        });
      },
    );
  }

  String _formatDuration(num durationInSeconds) {
    final duration = Duration(seconds: durationInSeconds.round());
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
