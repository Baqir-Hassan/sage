import 'package:flutter/material.dart';
import 'package:sage/data/sources/admin/admin_api_service.dart';
import 'package:sage/service_locator.dart';

class UserLimitsAdminPage extends StatefulWidget {
  const UserLimitsAdminPage({super.key});

  @override
  State<UserLimitsAdminPage> createState() => _UserLimitsAdminPageState();
}

class _UserLimitsAdminPageState extends State<UserLimitsAdminPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newLectureLimitController = TextEditingController();
  final TextEditingController _regenerationLimitController = TextEditingController();
  final AdminApiService _adminApiService = sl<AdminApiService>();

  bool _loading = false;
  String? _statusMessage;
  Map<String, dynamic>? _currentLimits;

  @override
  void dispose() {
    _emailController.dispose();
    _newLectureLimitController.dispose();
    _regenerationLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Limits')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'User Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loading ? null : _loadCurrentLimits,
                    child: const Text('Load Current Limits'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _newLectureLimitController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Daily New Lecture Limit (blank = default)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _regenerationLimitController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Daily Regeneration Limit (blank = default)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _saveLimits,
                    child: const Text('Save Limits'),
                  ),
                ),
              ],
            ),
            if (_statusMessage != null) ...[
              const SizedBox(height: 12),
              Text(_statusMessage!),
            ],
            if (_currentLimits != null) ...[
              const SizedBox(height: 20),
              Text('Effective new lecture limit: ${_currentLimits!['daily_new_lecture_limit']}'),
              Text('Effective regeneration limit: ${_currentLimits!['daily_regeneration_limit']}'),
              Text(
                'Override new lecture limit: ${_currentLimits!['override_daily_new_lecture_limit'] ?? 'default'}',
              ),
              Text(
                'Override regeneration limit: ${_currentLimits!['override_daily_regeneration_limit'] ?? 'default'}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _loadCurrentLimits() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _setStatus('Please provide a user email.');
      return;
    }

    setState(() => _loading = true);
    final response = await _adminApiService.getUserLimitsByEmail(email);
    response.fold(
      (error) => _setStatus(error),
      (data) {
        if (data is! Map<String, dynamic>) {
          _setStatus('Unexpected response from server.');
          return;
        }
        _currentLimits = data;
        _newLectureLimitController.text = _nullableIntToText(data['override_daily_new_lecture_limit']);
        _regenerationLimitController.text = _nullableIntToText(data['override_daily_regeneration_limit']);
        _setStatus('Loaded limits for user.');
      },
    );
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveLimits() async {
    final userId = _currentLimits?['user_id'] as String?;
    if (userId == null || userId.isEmpty) {
      _setStatus('Load a user by email first.');
      return;
    }

    final newLectureLimit = _parseOptionalInt(_newLectureLimitController.text);
    final regenerationLimit = _parseOptionalInt(_regenerationLimitController.text);
    if (newLectureLimit == null && _newLectureLimitController.text.trim().isNotEmpty) {
      _setStatus('New lecture limit must be a non-negative integer.');
      return;
    }
    if (regenerationLimit == null && _regenerationLimitController.text.trim().isNotEmpty) {
      _setStatus('Regeneration limit must be a non-negative integer.');
      return;
    }

    setState(() => _loading = true);
    final response = await _adminApiService.updateUserLimits(
      userId: userId,
      dailyNewLectureLimit: newLectureLimit,
      dailyRegenerationLimit: regenerationLimit,
    );
    response.fold(
      (error) => _setStatus(error),
      (data) {
        if (data is! Map<String, dynamic>) {
          _setStatus('Unexpected response from server.');
          return;
        }
        _currentLimits = data;
        _setStatus('Limits updated successfully.');
      },
    );
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _setStatus(String message) {
    if (!mounted) return;
    setState(() {
      _statusMessage = message;
    });
  }

  int? _parseOptionalInt(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    final parsed = int.tryParse(text);
    if (parsed == null || parsed < 0) return null;
    return parsed;
  }

  String _nullableIntToText(dynamic value) {
    if (value is int) return value.toString();
    return '';
  }
}
