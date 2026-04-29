import 'package:sage/common/helpers/is_dark_mode.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:sage/common/widgets/appbar/app_bar.dart';
import 'package:sage/common/widgets/button/basic_app_button.dart';
import 'package:sage/core/configs/theme/app_color.dart';
import 'package:sage/data/sources/lecture/lecture_api_service.dart';
import 'package:sage/data/sources/upload/upload_api_service.dart';
import 'package:sage/presentation/upload/pages/upload_processing.dart';
import 'package:sage/service_locator.dart';

class UploadNotesPage extends StatefulWidget {
  const UploadNotesPage({super.key});

  @override
  State<UploadNotesPage> createState() => _UploadNotesPageState();
}

class _UploadNotesPageState extends State<UploadNotesPage> {
  PlatformFile? _selectedFile;
  String _voiceOption = 'female';
  final TextEditingController _newSubjectController = TextEditingController();
  List<Map<String, dynamic>> _subjects = const [];
  String? _selectedSubjectId;
  bool _isLoadingSubjects = true;
  bool _isLoadingLimits = true;
  bool _isUploading = false;
  String? _uploadMessage;
  Map<String, dynamic>? _usageLimits;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
    _loadUsageLimits();
  }

  @override
  void dispose() {
    _newSubjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BasicAppBar(
        title: Text('Upload Notes'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create a new audio lecture',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Choose a PDF or presentation, pick the lecture voice, and let Sage AI turn it into a narrated lesson.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.grey,
              ),
            ),
            const SizedBox(height: 20),
            _usageLimitCard(),
            const SizedBox(height: 32),
            _filePickerCard(),
            const SizedBox(height: 24),
            const Text(
              'Voice',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.white;
                  }
                  return AppColors.greyTitle;
                }),
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.metalDark;
                  }
                  return Colors.transparent;
                }),
                side: const WidgetStatePropertyAll(
                  BorderSide(color: AppColors.darkGrey),
                ),
              ),
              segments: const [
                ButtonSegment<String>(
                  value: 'female',
                  label: Text('Female'),
                  icon: Icon(Icons.record_voice_over_outlined),
                ),
                ButtonSegment<String>(
                  value: 'male',
                  label: Text('Male'),
                  icon: Icon(Icons.mic_none_rounded),
                ),
              ],
              selected: {_voiceOption},
              onSelectionChanged: (selection) {
                setState(() {
                  _voiceOption = selection.first;
                });
              },
            ),
            const SizedBox(height: 24),
            _subjectSelectorCard(),
            const SizedBox(height: 28),
            BasicAppButton(
              onPressed: _canSubmitUpload ? _uploadNotes : null,
              title: _isUploading
                  ? 'Uploading...'
                  : _hasUploadQuota
                      ? 'Generate Lecture'
                      : 'Daily Limit Reached',
              textSize: 20,
              weight: FontWeight.w600,
            ),
            if (_uploadMessage != null) ...[
              const SizedBox(height: 18),
              Text(
                _uploadMessage!,
                style: TextStyle(
                  color: _uploadMessage!.startsWith('Success')
                      ? Colors.green
                      : Colors.redAccent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool get _hasUploadQuota {
    final remaining = (_usageLimits?['new_lectures_remaining_today'] as num?)?.toInt();
    if (remaining == null) {
      return true;
    }
    return remaining > 0;
  }

  bool get _canSubmitUpload => !_isUploading && _hasUploadQuota;

  Widget _usageLimitCard() {
    if (_isLoadingLimits) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: AppColors.metalDark,
        ),
        child: const Text(
          'Loading daily limits...',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.grey,
          ),
        ),
      );
    }

    final newLectureRemaining =
        (_usageLimits?['new_lectures_remaining_today'] as num?)?.toInt() ?? 0;
    final newLectureLimit =
        (_usageLimits?['daily_new_lecture_limit'] as num?)?.toInt() ?? 5;
    final regenerationRemaining =
        (_usageLimits?['regenerations_remaining_today'] as num?)?.toInt() ?? 0;
    final regenerationLimit =
        (_usageLimits?['daily_regeneration_limit'] as num?)?.toInt() ?? 5;
    final isUploadBlocked = newLectureRemaining <= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: isUploadBlocked ? AppColors.darkGrey : AppColors.metalDark,
        border: Border.all(
          color: isUploadBlocked ? Colors.redAccent.withOpacity(0.45) : AppColors.darkGrey,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s limits',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$newLectureRemaining of $newLectureLimit new lectures remaining',
            style: TextStyle(
              fontSize: 14,
              color: isUploadBlocked ? Colors.redAccent : AppColors.greyWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$regenerationRemaining of $regenerationLimit regenerations remaining',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Daily limits reset on the backend\'s UTC day.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filePickerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: AppColors.greyWhite,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lecture source file',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGrey,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _selectedFile?.name ?? 'No file selected yet.',
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.darkGrey,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _pickFile,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.darkGrey),
            ),
            icon: const Icon(
              Icons.upload_file_rounded,
              color: AppColors.primary,
            ),
            label: const Text(
              'Choose PDF or PPTX',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _subjectSelectorCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Subject',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedSubjectId,
          dropdownColor: AppColors.metalDark,
          decoration: const InputDecoration(
            hintText: 'Choose an existing subject',
            labelText: 'Existing subject',
            hintStyle: TextStyle(color: AppColors.grey),
            labelStyle: TextStyle(color: AppColors.greyTitle),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.darkGrey),
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary, width: 1.4),
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
          ),
          items: _subjects
              .map(
                (subject) => DropdownMenuItem<String>(
                  value: subject['id'] as String,
                  child: Text(subject['name'] as String),
                ),
              )
              .toList(),
          onChanged: _isLoadingSubjects
              ? null
              : (value) {
                  setState(() {
                    _selectedSubjectId = value;
                  });
                },
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _newSubjectController,
          style: TextStyle(
            color: context.isDarkMode ? AppColors.white : AppColors.dark,
          ),
          decoration: const InputDecoration(
            hintText: 'Type a new subject name if needed',
            labelText: 'New subject',
            hintStyle: TextStyle(color: AppColors.grey),
            labelStyle: TextStyle(color: AppColors.greyTitle),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.darkGrey),
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary, width: 1.4),
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'If you enter a new subject name, it will be used instead of the dropdown selection.',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.grey,
          ),
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'pptx'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFile = result.files.first;
        _uploadMessage = null;
      });
    }
  }

  Future<void> _uploadNotes() async {
    if (!_hasUploadQuota) {
      setState(() {
        _uploadMessage = 'You have reached today\'s new lecture limit. Please try again tomorrow.';
      });
      return;
    }

    final file = _selectedFile;
    if (file == null) {
      setState(() {
        _uploadMessage = 'Please choose a PDF or PPTX file first.';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadMessage = null;
    });

    final result = await sl<UploadApiService>().uploadDocument(
      file: file,
      voiceOption: _voiceOption,
      subjectId: _selectedSubjectId,
      subjectName: _newSubjectController.text,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isUploading = false;
          _uploadMessage = failure.toString();
        });
        _loadUsageLimits();
      },
      (data) {
        final documentId = (data as Map<String, dynamic>)['document_id'];
        setState(() {
          _isUploading = false;
          _uploadMessage = 'Upload accepted. Opening processing status...';
        });
        _loadUsageLimits();

        if (documentId is String && documentId.isNotEmpty) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => UploadProcessingPage(documentId: documentId),
            ),
          );
        }
      },
    );
  }

  Future<void> _loadUsageLimits() async {
    final result = await sl<UploadApiService>().getUploadLimits();

    if (!mounted) return;

    result.fold(
      (_) {
        setState(() {
          _isLoadingLimits = false;
        });
      },
      (data) {
        setState(() {
          _usageLimits = (data as Map<String, dynamic>);
          _isLoadingLimits = false;
        });
      },
    );
  }

  Future<void> _loadSubjects() async {
    final result = await sl<LectureApiService>().getSubjects();

    if (!mounted) return;

    result.fold(
      (_) {
        setState(() {
          _isLoadingSubjects = false;
        });
      },
      (data) {
        final subjects = (data as List<dynamic>).cast<Map<String, dynamic>>();
        setState(() {
          _subjects = subjects;
          _isLoadingSubjects = false;
        });
      },
    );
  }
}
