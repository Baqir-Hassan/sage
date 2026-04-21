import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:spotify_with_flutter/common/widgets/appbar/app_bar.dart';
import 'package:spotify_with_flutter/common/widgets/button/basic_app_button.dart';
import 'package:spotify_with_flutter/core/configs/theme/app_color.dart';
import 'package:spotify_with_flutter/data/sources/upload/upload_api_service.dart';
import 'package:spotify_with_flutter/presentation/upload/pages/upload_processing.dart';
import 'package:spotify_with_flutter/service_locator.dart';

class UploadNotesPage extends StatefulWidget {
  const UploadNotesPage({super.key});

  @override
  State<UploadNotesPage> createState() => _UploadNotesPageState();
}

class _UploadNotesPageState extends State<UploadNotesPage> {
  PlatformFile? _selectedFile;
  String _voiceOption = 'female';
  final TextEditingController _subjectController = TextEditingController();
  bool _isUploading = false;
  String? _uploadMessage;

  @override
  void dispose() {
    _subjectController.dispose();
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
            TextField(
              controller: _subjectController,
              style: const TextStyle(
                color: AppColors.white,
              ),
              decoration: const InputDecoration(
                hintText: 'Optional subject id',
                labelText: 'Subject',
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
            const SizedBox(height: 28),
            BasicAppButton(
              onPressed: _isUploading ? () {} : _uploadNotes,
              title: _isUploading ? 'Uploading...' : 'Generate Lecture',
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

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'ppt', 'pptx'],
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
      subjectId: _subjectController.text,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isUploading = false;
          _uploadMessage = failure.toString();
        });
      },
      (data) {
        final documentId = (data as Map<String, dynamic>)['document_id'];
        setState(() {
          _isUploading = false;
          _uploadMessage = 'Upload accepted. Opening processing status...';
        });

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
}
