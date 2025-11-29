import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/business_card.dart';
import '../providers/business_card_provider.dart';
import 'card_edit_screen.dart';

class CardDetailScreen extends StatelessWidget {
  final BusinessCard card;

  const CardDetailScreen({Key? key, required this.card}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CardEditScreen(card: card),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              Share.share(card.toVCard());
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card image
            if (card.imagePath != null)
              Image.file(
                File(card.imagePath!),
                height: 250,
                fit: BoxFit.cover,
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    card.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  if (card.title.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      card.title,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Contact information
                  if (card.email.isNotEmpty)
                    _ContactItem(
                      icon: Icons.email,
                      label: 'Email',
                      value: card.email,
                      onTap: () => _launchUrl('mailto:${card.email}'),
                    ),

                  if (card.phone.isNotEmpty)
                    _ContactItem(
                      icon: Icons.phone,
                      label: 'Phone',
                      value: card.phone,
                      onTap: () => _launchUrl('tel:${card.phone}'),
                    ),

                  if (card.website.isNotEmpty)
                    _ContactItem(
                      icon: Icons.language,
                      label: 'Website',
                      value: card.website,
                      onTap: () => _launchUrl(
                        card.website.startsWith('http')
                            ? card.website
                            : 'https://${card.website}',
                      ),
                    ),

                  if (card.address.isNotEmpty)
                    _ContactItem(
                      icon: Icons.location_on,
                      label: 'Address',
                      value: card.address,
                      onTap: () {},
                    ),

                  if (card.notes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      card.notes,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // QR Code button
                  ElevatedButton.icon(
                    onPressed: () => _showQRCode(context),
                    icon: const Icon(Icons.qr_code),
                    label: const Text('Show QR Code'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Delete button
                  OutlinedButton.icon(
                    onPressed: () => _deleteCard(context),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text(
                      'Delete Card',
                      style: TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQRCode(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan QR Code'),
        content: SizedBox(
          width: 250,
          height: 250,
          child: QrImageView(
            data: card.toVCard(),
            version: QrVersions.auto,
            size: 250,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _deleteCard(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Card'),
        content: Text('Are you sure you want to delete ${card.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<BusinessCardProvider>(context, listen: false)
                  .deleteCard(card.id);
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to list
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Card deleted')),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _ContactItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
