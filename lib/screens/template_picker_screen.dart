import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/card_template.dart';
import '../providers/subscription_provider.dart';
import 'subscription_screen.dart';

class TemplatePickerScreen extends StatelessWidget {
  final CardTemplateType? currentTemplate;
  final Function(CardTemplateType) onTemplateSelected;

  const TemplatePickerScreen({
    Key? key,
    this.currentTemplate,
    required this.onTemplateSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Card Design'),
      ),
      body: Consumer<SubscriptionProvider>(
        builder: (context, subscriptionProvider, child) {
          final templates = CardTemplate.getAllTemplates();

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              final isLocked = template.isPremium &&
                  !subscriptionProvider.canAccessFeature('custom_templates');
              final isSelected = currentTemplate == template.type;

              return GestureDetector(
                onTap: () {
                  if (isLocked) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SubscriptionScreen(),
                      ),
                    );
                  } else {
                    onTemplateSelected(template.type);
                    Navigator.pop(context);
                  }
                },
                child: _TemplateCard(
                  template: template,
                  isLocked: isLocked,
                  isSelected: isSelected,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final CardTemplate template;
  final bool isLocked;
  final bool isSelected;

  const _TemplateCard({
    required this.template,
    required this.isLocked,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.shade300,
              width: isSelected ? 3 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Template preview
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: template.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      // Accent bar
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 30,
                          decoration: BoxDecoration(
                            color: template.secondaryColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      // Mock content
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 35),
                            Container(
                              height: 12,
                              width: 80,
                              decoration: BoxDecoration(
                                color: template.textColor.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 8,
                              width: 100,
                              decoration: BoxDecoration(
                                color: template.textColor.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              height: 6,
                              width: 90,
                              decoration: BoxDecoration(
                                color: template.textColor.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 6,
                              width: 70,
                              decoration: BoxDecoration(
                                color: template.textColor.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Template info
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              template.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: Colors.blue,
                              size: 20,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        template.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Lock overlay
        if (isLocked)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock,
                    color: Colors.amber.shade300,
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'PREMIUM',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
