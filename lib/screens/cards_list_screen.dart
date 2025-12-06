import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/business_card.dart';
import '../providers/business_card_provider.dart';
import '../providers/subscription_provider.dart';
import 'camera_scan_screen.dart';
import 'card_edit_screen.dart';
import 'card_detail_screen.dart';
import 'subscription_screen.dart';
import 'premium_features_screen.dart';
import '../models/subscription.dart';
import '../widgets/business_card_preview.dart';
import '../services/card_pdf_generator.dart';  // ✅ ADD THIS
import 'package:cross_file/cross_file.dart';  // ✅ ADD THIS for XFile

class CardsListScreen extends StatefulWidget {
  const CardsListScreen({Key? key}) : super(key: key);

  @override
  State<CardsListScreen> createState() => _CardsListScreenState();
}

class _CardsListScreenState extends State<CardsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // FIXED: Check subscription limit before camera scan
  void _navigateToCamera() {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(
      context,
      listen: false,
    );
    final cardProvider = Provider.of<BusinessCardProvider>(
      context,
      listen: false,
    );

    // Check if user can add more cards
    if (!subscriptionProvider.canAddCard(cardProvider.cards.length)) {
      _showUpgradeDialog(cardProvider.cards.length);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CameraScanScreen(),
      ),
    );
  }

  // FIXED: Check subscription limit before manual creation
  void _createNewCard() {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(
      context,
      listen: false,
    );
    final cardProvider = Provider.of<BusinessCardProvider>(
      context,
      listen: false,
    );

    // Check if user can add more cards
    if (!subscriptionProvider.canAddCard(cardProvider.cards.length)) {
      _showUpgradeDialog(cardProvider.cards.length);
      return;
    }

    final newCard = BusinessCard(name: '');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CardEditScreen(
          card: newCard,
          isNewCard: true,
        ),
      ),
    );
  }

  // NEW: Show upgrade dialog when limit reached
  void _showUpgradeDialog(int currentCount) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(
      context,
      listen: false,
    );
    final maxCards = subscriptionProvider.currentSubscription.maxCards;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock, color: Colors.amber.shade700),
            const SizedBox(width: 8),
            Expanded(  // ✅ Add this
              child: const Text(
                'Card Limit Reached',
                overflow: TextOverflow.ellipsis,  // ✅ Add this
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You\'ve reached the limit of $maxCards cards on the free plan.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.workspace_premium, 
                        color: Colors.blue.shade700, 
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Premium Benefits:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('✓ Unlimited business cards'),
                  const Text('✓ Custom card templates'),
                  const Text('✓ Company logo upload'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubscriptionScreen(),
                ),
              );
            },
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Upgrade Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<SubscriptionProvider>(
          builder: (context, subProvider, child) {
            return Consumer<BusinessCardProvider>(
              builder: (context, cardProvider, child) {
                final maxCards = subProvider.currentSubscription.maxCards;
                final currentCount = cardProvider.cards.length;

                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: const Text(
                              'My Business Cards',
                              maxLines: 1, // keep it on one line, but fully visible
                            ),
                          ),
                          if (maxCards != -1)
                            Text(
                              '$currentCount of $maxCards cards',
                              style: TextStyle(
                                fontSize: 12,
                                color: currentCount >= maxCards
                                    ? Colors.red
                                    : Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),

        actions: [
          // Add menu button for premium features
          Consumer<SubscriptionProvider>(
            builder: (context, subProvider, child) {
              if (subProvider.currentSubscription.tier != SubscriptionTier.free) {
                return IconButton(
                  icon: const Icon(Icons.auto_awesome),
                  tooltip: 'Premium Features',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PremiumFeaturesScreen(),
                      ),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: CardSearchDelegate(),
              );
            },
          ),
        ],
      ),
      body: Consumer<BusinessCardProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final cards = _searchQuery.isEmpty
              ? provider.cards
              : provider.searchCards(_searchQuery);

          if (cards.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.credit_card,
                    size: 100,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No business cards yet',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scan or create your first card',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              return _BusinessCardTile(card: card);
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'scan',
            onPressed: _navigateToCamera,
            child: const Icon(Icons.camera_alt),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'create',
            onPressed: _createNewCard,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _BusinessCardTile extends StatelessWidget {
  final BusinessCard card;

  const _BusinessCardTile({required this.card});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CardDetailScreen(card: card),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Show the actual business card preview
              Center(
                child: BusinessCardPreview(
                  key: ValueKey(card.id),
                  card: card,
                  width: MediaQuery.of(context).size.width - 64,
                  height: (MediaQuery.of(context).size.width - 64) * 0.57, // Business card ratio
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Action buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Share button
                  TextButton.icon(
                    onPressed: () {
                      Share.share(card.toVCard());
                    },
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Share'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  ),
                  
                  // Print/PDF button
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'single') {
                        await _exportSingleCardPdf(context, card);
                      } else if (value == 'sheet') {
                        await _exportCardSheetPdf(context, card);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'single',
                        child: Row(
                          children: [
                            Icon(Icons.picture_as_pdf, size: 18),
                            SizedBox(width: 8),
                            Text('Single Card PDF'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'sheet',
                        child: Row(
                          children: [
                            Icon(Icons.grid_on, size: 18),
                            SizedBox(width: 8),
                            Text('Sheet (10 cards)'),
                          ],
                        ),
                      ),
                    ],
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.print, size: 18, color: Colors.purple),
                        SizedBox(width: 4),
                        Text('Print', style: TextStyle(color: Colors.purple)),
                        Icon(Icons.arrow_drop_down, size: 18, color: Colors.purple),
                      ],
                    ),
                  ),
                  
                  // Edit button
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CardEditScreen(card: card),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green,
                    ),
                  ),
                  
                  // Delete button
                  TextButton.icon(
                    onPressed: () => _showDeleteDialog(context, card),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, BusinessCard card) {
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
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Card deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportSingleCardPdf(BuildContext context, BusinessCard card) async {
    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Generating PDF...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // Generate PDF
      final pdfFile = await CardPdfGenerator.generateSingleCardPdf(card);

      // Share PDF
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        subject: '${card.name} - Business Card',
        text: 'Business card for ${card.name}',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF created: ${pdfFile.path.split('/').last}'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () {
                Share.shareXFiles([XFile(pdfFile.path)]);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating PDF: $e')),
        );
      }
    }
  }

  Future<void> _exportCardSheetPdf(BuildContext context, BusinessCard card) async {
    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Generating sheet with 10 cards...'),
            ],
          ),
          duration: Duration(seconds: 3),
        ),
      );

      // Generate PDF sheet
      final pdfFile = await CardPdfGenerator.generateMultiCardPdf(card, cardsPerPage: 10);

      // Share PDF
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        subject: '${card.name} - Business Card Sheet',
        text: 'Printable sheet with 10 business cards for ${card.name}',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF sheet created: ${pdfFile.path.split('/').last}'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () {
                Share.shareXFiles([XFile(pdfFile.path)]);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating PDF: $e')),
        );
      }
    }
  }
}

class CardSearchDelegate extends SearchDelegate<BusinessCard?> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final provider = Provider.of<BusinessCardProvider>(context);
    final results = provider.searchCards(query);

    if (results.isEmpty) {
      return const Center(
        child: Text('No cards found'),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final card = results[index];
        return ListTile(
          leading: card.imagePath != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(card.imagePath!),
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                )
              : const Icon(Icons.person),
          title: Text(card.name),
          subtitle: Text(card.company),
          onTap: () {
            close(context, card);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CardDetailScreen(card: card),
              ),
            );
          },
        );
      },
    );
  }
}