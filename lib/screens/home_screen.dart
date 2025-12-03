import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import 'cards_list_screen.dart';
import 'subscription_screen.dart';
import 'privacy_policy_screen.dart';
import 'resume_list_screen.dart';
import 'credentials_screen.dart';
import 'portfolio_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get safe area insets to avoid navigation bar
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1976D2),
              const Color(0xFF1565C0),
              const Color(0xFF0D47A1),
            ],
          ),
        ),
        child: SafeArea(
          // This ensures content avoids navigation bar
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isLandscape ? 8.0 : 16.0,
                  vertical: isLandscape ? 8.0 : 16.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                      onPressed: () => _showMenu(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.help_outline, color: Colors.white, size: 28),
                      onPressed: () => _showHelp(context),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  // Add padding to prevent content from being cut off
                  padding: EdgeInsets.only(
                    left: isLandscape ? 16.0 : 24.0,
                    right: isLandscape ? 16.0 : 24.0,
                    bottom: 24.0,
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: isLandscape ? 10 : 20),
                      
                      // App Icon/Logo (smaller in landscape)
                      Container(
                        width: isLandscape ? 80 : 120,
                        height: isLandscape ? 80 : 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(isLandscape ? 20 : 30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              top: isLandscape ? 25 : 35,
                              child: Icon(
                                Icons.credit_card,
                                size: isLandscape ? 25 : 40,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            Positioned(
                              top: isLandscape ? 30 : 45,
                              child: Icon(
                                Icons.credit_card,
                                size: isLandscape ? 25 : 40,
                                color: Colors.blue.shade500,
                              ),
                            ),
                            Positioned(
                              top: isLandscape ? 35 : 55,
                              child: Icon(
                                Icons.credit_card,
                                size: isLandscape ? 25 : 40,
                                color: Colors.blue.shade300,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: isLandscape ? 15 : 30),

                      // App Name (smaller in landscape)
                      Text(
                        'ProStack',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isLandscape ? 32 : 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),

                      SizedBox(height: isLandscape ? 6 : 12),

                      // Tagline (smaller in landscape)
                      Text(
                        'Stack Your Professional Life',
                        style: TextStyle(
                          fontSize: isLandscape ? 13 : 16,
                          color: Colors.white.withValues(alpha: 0.9),
                          letterSpacing: 0.5,
                        ),
                      ),

                      SizedBox(height: isLandscape ? 20 : 50),

                      // Feature Buttons (compact in landscape)
                      _FeatureButton(
                        icon: Icons.contacts,
                        title: 'Business Cards',
                        subtitle: 'Scan & manage contacts',
                        gradient: [Colors.blue.shade600, Colors.blue.shade800],
                        isCompact: isLandscape,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CardsListScreen(),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: isLandscape ? 8 : 16),

                      _FeatureButton(
                        icon: Icons.description,
                        title: 'My Resumes',
                        subtitle: 'View and create resumes',
                        gradient: [Colors.purple.shade600, Colors.purple.shade800],
                        isPro: true,
                        isCompact: isLandscape,
                        onTap: () {
                          final provider = Provider.of<SubscriptionProvider>(context, listen: false);
                          final hasAccess = provider.canAccessFeature('ai_resume');

                          if (!hasAccess) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Upgrade to Business to access Resume features')),
                            );
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ResumeListScreen(),
                            ),
                          );
                        },

                      ),

                      SizedBox(height: isLandscape ? 8 : 16),

                      _FeatureButton(
                        icon: Icons.school,
                        title: 'Credentials',
                        subtitle: 'Certificates & degrees',
                        gradient: [Colors.green.shade600, Colors.green.shade800],
                        isPro: true,
                        comingSoon: true,
                        isCompact: isLandscape,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CredentialsScreen(),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: isLandscape ? 8 : 16),

                      _FeatureButton(
                        icon: Icons.folder_special,
                        title: 'Portfolio',
                        subtitle: 'Showcase your work',
                        gradient: [Colors.orange.shade600, Colors.orange.shade800],
                        isPro: true,
                        comingSoon: true,
                        isCompact: isLandscape,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PortfolioScreen(),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: isLandscape ? 20 : 40),

                      // Premium Badge (smaller in landscape)
                      Consumer<SubscriptionProvider>(
                        builder: (context, provider, child) {
                          if (provider.currentSubscription.tier.toString().contains('free')) {
                            return Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white, width: 2),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const SubscriptionScreen(),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(30),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isLandscape ? 16 : 24,
                                      vertical: isLandscape ? 8 : 12,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.workspace_premium,
                                          color: Colors.amber.shade300,
                                          size: isLandscape ? 20 : 24,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Unlock All Features',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: isLandscape ? 14 : 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                          return Container();
                        },
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.contacts),
              title: const Text('Business Cards'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CardsListScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.workspace_premium),
              title: const Text('Upgrade to Business'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacy Policy'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About ProStack'),
              onTap: () {
                Navigator.pop(context);
                _showAbout(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ProStack Features'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _HelpItem(
                icon: Icons.contacts,
                title: 'Business Cards',
                text: 'Scan and digitize business cards with AI-powered OCR',
              ),
              _HelpItem(
                icon: Icons.description,
                title: 'AI Resume Builder',
                text: 'Create professional resumes with AI assistance',
              ),
              _HelpItem(
                icon: Icons.school,
                title: 'Credentials',
                text: 'Store certificates, degrees, and achievements',
              ),
              _HelpItem(
                icon: Icons.folder_special,
                title: 'Portfolio',
                text: 'Showcase your work and accomplishments',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'ProStack',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Stack(
          alignment: Alignment.center,
          children: [
            Positioned(top: 10, child: Icon(Icons.credit_card, color: Colors.white70, size: 20)),
            Positioned(top: 15, child: Icon(Icons.credit_card, color: Colors.white, size: 20)),
            Positioned(top: 20, child: Icon(Icons.credit_card, color: Colors.white, size: 20)),
          ],
        ),
      ),
      children: [
        const Text(
          'Stack Your Professional Life\n\nBusiness cards, resumes, credentials, and more - all in one powerful app.',
        ),
      ],
    );
  }
}

class _FeatureButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;
  final bool isPro;
  final bool comingSoon;
  final bool isCompact;

  const _FeatureButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
    this.isPro = false,
    this.comingSoon = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(isCompact ? 12 : 20),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isCompact ? 8 : 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: isCompact ? 24 : 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: isCompact ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (isPro) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade300,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'PRO',
                                  style: TextStyle(
                                    fontSize: isCompact ? 9 : 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                            if (comingSoon) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'SOON',
                                  style: TextStyle(
                                    fontSize: isCompact ? 9 : 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (!isCompact) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: isCompact ? 16 : 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _HelpItem({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}