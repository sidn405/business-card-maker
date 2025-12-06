import 'package:flutter/material.dart';

enum CardTemplateType {
  classic,
  modern,
  minimal,
  corporate,
  creative,
  elegant,
  // Professional career-specific templates
  medical,
  legal,
  tech,
  finance,
  realEstate,
  consulting,
  academic,
  executive,
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
      
      // Professional career-specific templates
      CardTemplate(
        type: CardTemplateType.medical,
        name: 'Medical',
        description: 'Healthcare professionals',
        primaryColor: Colors.white,
        secondaryColor: const Color(0xFF0277BD), // Medical blue
        textColor: const Color(0xFF263238),
        isPremium: true,
      ),
      CardTemplate(
        type: CardTemplateType.legal,
        name: 'Legal',
        description: 'Law and legal services',
        primaryColor: const Color(0xFF1A1A1A), // Deep black
        secondaryColor: const Color(0xFFB8860B), // Dark gold
        textColor: Colors.white,
        isPremium: true,
      ),
      CardTemplate(
        type: CardTemplateType.tech,
        name: 'Tech',
        description: 'Technology & engineering',
        primaryColor: const Color(0xFF263238), // Charcoal
        secondaryColor: const Color(0xFF00BCD4), // Cyan
        textColor: Colors.white,
        isPremium: true,
      ),
      CardTemplate(
        type: CardTemplateType.finance,
        name: 'Finance',
        description: 'Banking & financial services',
        primaryColor: const Color(0xFF0D47A1), // Navy blue
        secondaryColor: const Color(0xFF1B5E20), // Forest green
        textColor: Colors.white,
        isPremium: true,
      ),
      CardTemplate(
        type: CardTemplateType.realEstate,
        name: 'Real Estate',
        description: 'Property & real estate',
        primaryColor: const Color(0xFFFAFAFA), // Off-white
        secondaryColor: const Color(0xFFC62828), // Real estate red
        textColor: const Color(0xFF212121),
        isPremium: true,
      ),
      CardTemplate(
        type: CardTemplateType.consulting,
        name: 'Consulting',
        description: 'Business consulting',
        primaryColor: const Color(0xFF424242), // Dark gray
        secondaryColor: const Color(0xFF5E35B1), // Deep purple
        textColor: Colors.white,
        isPremium: true,
      ),
      CardTemplate(
        type: CardTemplateType.academic,
        name: 'Academic',
        description: 'Education & research',
        primaryColor: const Color(0xFF4E342E), // Brown
        secondaryColor: const Color(0xFFD4AF37), // Gold
        textColor: Colors.white,
        isPremium: true,
      ),
      CardTemplate(
        type: CardTemplateType.executive,
        name: 'Executive',
        description: 'C-level executives',
        primaryColor: const Color(0xFF212121), // True black
        secondaryColor: const Color(0xFF9E9E9E), // Silver
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