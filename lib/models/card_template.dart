import 'package:flutter/material.dart';

enum CardTemplateType {
  classic,
  modern,
  minimal,
  corporate,
  creative,
  elegant,
}

class CardTemplate {
  final CardTemplateType type;
  final String name;
  final String description;
  final Color primaryColor;
  final Color secondaryColor;
  final Color textColor;
  final bool isPremium;

  CardTemplate({
    required this.type,
    required this.name,
    required this.description,
    required this.primaryColor,
    required this.secondaryColor,
    required this.textColor,
    this.isPremium = false,
  });

  static List<CardTemplate> getAllTemplates() {
    return [
      // Free template
      CardTemplate(
        type: CardTemplateType.classic,
        name: 'Classic',
        description: 'Traditional business card design',
        primaryColor: Colors.white,
        secondaryColor: Colors.blue,
        textColor: Colors.black87,
        isPremium: false,
      ),
      
      // Premium templates
      CardTemplate(
        type: CardTemplateType.modern,
        name: 'Modern',
        description: 'Clean and contemporary',
        primaryColor: const Color(0xFF1E1E1E),
        secondaryColor: const Color(0xFF4CAF50),
        textColor: Colors.white,
        isPremium: true,
      ),
      CardTemplate(
        type: CardTemplateType.minimal,
        name: 'Minimal',
        description: 'Less is more',
        primaryColor: const Color(0xFFF5F5F5),
        secondaryColor: const Color(0xFF757575),
        textColor: const Color(0xFF212121),
        isPremium: true,
      ),
      CardTemplate(
        type: CardTemplateType.corporate,
        name: 'Corporate',
        description: 'Professional and formal',
        primaryColor: const Color(0xFF0D47A1),
        secondaryColor: const Color(0xFF1976D2),
        textColor: Colors.white,
        isPremium: true,
      ),
      CardTemplate(
        type: CardTemplateType.creative,
        name: 'Creative',
        description: 'Bold and artistic',
        primaryColor: const Color(0xFFE91E63),
        secondaryColor: const Color(0xFFFFC107),
        textColor: Colors.white,
        isPremium: true,
      ),
      CardTemplate(
        type: CardTemplateType.elegant,
        name: 'Elegant',
        description: 'Sophisticated and refined',
        primaryColor: const Color(0xFF37474F),
        secondaryColor: const Color(0xFFD4AF37),
        textColor: Colors.white,
        isPremium: true,
      ),
    ];
  }

  static CardTemplate getTemplate(CardTemplateType type) {
    return getAllTemplates().firstWhere(
      (template) => template.type == type,
      orElse: () => getAllTemplates().first,
    );
  }

  static List<CardTemplate> getFreeTemplates() {
    return getAllTemplates().where((t) => !t.isPremium).toList();
  }

  static List<CardTemplate> getPremiumTemplates() {
    return getAllTemplates().where((t) => t.isPremium).toList();
  }
}
