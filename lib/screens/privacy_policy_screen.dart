import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy for ProStack',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: November 28, 2025',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              'Introduction',
              'ProStack ("we", "our", or "us") operates the ProStack mobile application (the "Service").\n\n'
              'This page informs you of our policies regarding the collection, use, and disclosure of personal data when you use our Service.',
            ),

            _buildSection(
              'Information We Collect',
              '',
            ),

            _buildSubSection(
              'Camera Permission',
              '• Scan and digitize business cards using OCR technology\n'
              '• All images are processed locally on your device\n'
              '• We DO NOT store, transmit, or share your camera images to any server',
            ),

            _buildSubSection(
              'Data Storage',
              '• Business card data is stored locally on your device only\n'
              '• We do not collect or store any personal information on our servers\n'
              '• All data remains on your device and under your control',
            ),

            _buildSubSection(
              'In-App Purchases',
              '• We use Google Play Billing for subscription management\n'
              '• Payment information is handled by Google Play and is never accessible to us\n'
              '• We receive only transaction confirmation from Google Play',
            ),

            _buildSection(
              'Data We DO NOT Collect',
              'We do NOT collect, store, or transmit:\n\n'
              '• Personal identification information\n'
              '• Camera images or photos\n'
              '• Contact information from scanned cards\n'
              '• Location data\n'
              '• Usage statistics\n'
              '• Analytics data',
            ),

            _buildSection(
              'Third-Party Services',
              'Our app uses the following third-party services:\n\n'
              '• Google Play Services: For in-app purchases and app functionality\n'
              '• Google ML Kit: For on-device text recognition (OCR) - processed locally, no data sent to Google',
            ),

            _buildSection(
              'Data Security',
              '• All data is stored locally on your device\n'
              '• We do not have access to your data\n'
              '• No data is transmitted to external servers\n'
              '• You can delete all data by uninstalling the app',
            ),

            _buildSection(
              'Children\'s Privacy',
              'Our Service does not address anyone under the age of 13. We do not knowingly collect personal information from children under 13.',
            ),

            _buildSection(
              'Changes to This Privacy Policy',
              'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy within the app.',
            ),

            _buildSection(
              'Contact Us',
              'If you have any questions about this Privacy Policy, please contact us at:\n\n'
              'Email: support@prostack.app',
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.privacy_tip,
                    color: Colors.blue.shade700,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'ProStack processes all data locally on your device. We do not collect, store, or share any personal information.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}