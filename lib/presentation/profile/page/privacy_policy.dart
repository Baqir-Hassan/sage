import 'package:flutter/material.dart';
import 'package:sage/common/helpers/is_dark_mode.dart';
import 'package:sage/common/widgets/appbar/app_bar.dart';
import 'package:sage/core/configs/theme/app_color.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? AppColors.white : AppColors.dark,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Privacy Policy',
          style: TextStyle(
            color: isDark ? AppColors.white : AppColors.dark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Last updated
            Text(
              'Last updated: April 2026',
              style: TextStyle(
                color: isDark ? AppColors.grey : AppColors.darkGrey,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),

            _buildIntro(isDark),
            const SizedBox(height: 24),

            _buildSection(
              isDark,
              title: '1. Information We Collect',
              content:
                  'When you create an account, we collect your full name and email address. '
                  'When you use Sage AI, we collect the PDF and PPTX files you upload to generate audio lectures. '
                  'We also collect basic usage data such as the number of lectures generated per day.',
            ),

            _buildSection(
              isDark,
              title: '2. How We Use Your Information',
              content:
                  'We use your information to provide and improve our services. '
                  'Your uploaded files are processed to generate audio lectures and are stored securely on Amazon S3. '
                  'Your email address is used to send account verification and important service notifications. '
                  'We do not sell, rent, or share your personal data with third parties, other than the service providers listed below who help us operate Sage AI.',
            ),

            _buildSection(
              isDark,
              title: '3. Data Storage and Security',
              content:
                  'Your data is stored securely on Amazon Web Services (AWS) in the EU (Stockholm, eu-north-1) region. '
                  'We use HTTPS for data in transit and AWS-managed encryption at rest for data stored in S3 buckets. '
                  'Audio files generated from your notes are stored on Amazon S3 and are accessible only via your authenticated account and time-limited links.',
            ),

            _buildSection(
              isDark,
              title: '4. Data Retention',
              content:
                  'We retain your account information for as long as your account is active. '
                  'Uploaded files and generated audio lectures are retained until you delete them in the app or close your account. '
                  'You can delete individual PDFs/PPTX files or generated audio separately if you want to keep one but not the other. '
                  'When you delete content, it is removed from our active storage. You may also request deletion of your data at any time by contacting us; we typically respond within 1–7 days.',
            ),

            _buildSection(
              isDark,
              title: '5. Third-Party Services',
              content:
                  'Sage AI uses the following third-party services to operate:\n\n'
                  '• Amazon Web Services (AWS) — cloud infrastructure and storage\n'
                  '• Groq API — AI language model for lecture script generation\n'
                  '• Microsoft Edge TTS — text-to-speech audio generation\n'
                  '• Zoho Mail — transactional email delivery\n\n'
                  'Each of these providers has its own privacy policy governing how it handles data. '
                  'Your uploaded content and generated text may be processed by Groq and Microsoft Edge TTS on servers outside your country in order to provide the AI and audio features in Sage AI.',
            ),

            _buildSection(
              isDark,
              title: '6. Your Rights',
              content:
                  'You have the right to access, correct, or delete your personal data at any time. '
                  'You may also request a copy of the data we hold about you. '
                  'You can delete your uploaded files and generated audio directly in the app, and sign out to clear your current login session. '
                  'To exercise any additional rights or request help with data access or deletion, please contact us at ak1to@sageai.live.',
            ),

            _buildSection(
              isDark,
              title: '7. Children\'s Privacy',
              content:
                  'Sage AI is not directed at children under the age of 13. '
                  'We do not knowingly collect personal information from children under 13. '
                  'If you believe we have inadvertently collected such information, please contact us immediately.',
            ),

            _buildSection(
              isDark,
              title: '8. International Data Transfers',
              content:
                  'Although we store your primary data on AWS in the EU (Stockholm, eu-north-1) region, '
                  'some processing by our third-party providers (for example, AI model inference and text-to-speech) '
                  'may occur on servers located outside your country. '
                  'By using Sage AI, you understand that your information may be transferred to and processed in these locations for the purpose of providing the service.',
            ),

            _buildSection(
              isDark,
              title: '9. Changes to This Policy',
              content:
                  'We may update this privacy policy from time to time. '
                  'We will notify you of any significant changes by email or through the app. '
                  'Your continued use of Sage AI after changes are made constitutes your acceptance of the updated policy.',
            ),

            _buildSection(
              isDark,
              title: '10. Contact Us',
              content:
                  'If you have any questions about this privacy policy or how we handle your data, '
                  'please contact us at:\n\nak1to@sageai.live\nsageai.live',
            ),

            const SizedBox(height: 40),

            // Footer
            Center(
              child: Text(
                '© 2026 Sage AI — sageai.live',
                style: TextStyle(
                  color: isDark ? AppColors.darkGrey : AppColors.grey,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildIntro(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
        ),
      ),
      child: Text(
        'Sage AI ("we", "our", or "us") is committed to protecting your privacy. '
        'This policy explains what information we collect, how we use it, and your rights regarding your data.',
        style: TextStyle(
          color: isDark ? AppColors.greyTitle : AppColors.dark,
          fontSize: 14,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildSection(bool isDark,
      {required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDark ? AppColors.white : AppColors.dark,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              color: isDark ? AppColors.greyTitle : AppColors.darkGrey,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}