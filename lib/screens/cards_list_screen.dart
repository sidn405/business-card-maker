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
            const Text('Card Limit Reached'),
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
                  const Text('✓ QR code generation'),
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
                final tier = subProvider.currentSubscription.tier;
                final maxCards = subProvider.currentSubscription.maxCards;
                final currentCount = cardProvider.cards.length;
                
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('My Business Cards'),
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
                    // Premium badge
                    if (tier != SubscriptionTier.free)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: tier == SubscriptionTier.business
                                ? [Colors.purple.shade700, Colors.purple.shade900]
                                : [Colors.amber.shade600, Colors.amber.shade800],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.workspace_premium,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              tier == SubscriptionTier.business ? 'BUSINESS' : 'PREMIUM',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
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
      margin: const EdgeInsets.only(bottom: 12),
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
          child: Row(
            children: [
              // Card image or placeholder
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: card.imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(card.imagePath!),
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.grey[400],
                      ),
              ),
              
              const SizedBox(width: 16),
              
              // Card details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (card.title.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        card.title,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    if (card.company.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        card.company,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Quick actions
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'share') {
                    Share.share(card.toVCard());
                  } else if (value == 'edit') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CardEditScreen(card: card),
                      ),
                    );
                  } else if (value == 'delete') {
                    _showDeleteDialog(context, card);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share),
                        SizedBox(width: 8),
                        Text('Share'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
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
