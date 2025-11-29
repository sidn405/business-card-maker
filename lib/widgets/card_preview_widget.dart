import 'dart:io';
import 'package:flutter/material.dart';
import '../models/business_card_enhanced.dart';
import '../models/card_template.dart';

class CardPreviewWidget extends StatelessWidget {
  final BusinessCard card;
  final double? width;
  final double? height;

  const CardPreviewWidget({
    Key? key,
    required this.card,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final template = CardTemplate.getTemplate(card.templateType);
    final cardWidth = width ?? MediaQuery.of(context).size.width * 0.9;
    final cardHeight = height ?? cardWidth * 0.6;

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        color: template.primaryColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Accent design element
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: cardHeight * 0.25,
                decoration: BoxDecoration(
                  color: template.secondaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
              ),
            ),

            // Company logo
            if (card.logoPath != null)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(card.logoPath!),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

            // Card content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 30), // Space for accent bar
                  
                  // Name
                  Text(
                    card.name,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: template.textColor,
                    ),
                  ),
                  
                  if (card.title.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      card.title,
                      style: TextStyle(
                        fontSize: 14,
                        color: template.textColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                  
                  if (card.company.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      card.company,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: template.textColor.withOpacity(0.9),
                      ),
                    ),
                  ],
                  
                  const Spacer(),
                  
                  // Contact info
                  if (card.email.isNotEmpty)
                    _ContactRow(
                      icon: Icons.email,
                      text: card.email,
                      color: template.textColor,
                    ),
                  
                  if (card.phone.isNotEmpty)
                    _ContactRow(
                      icon: Icons.phone,
                      text: card.phone,
                      color: template.textColor,
                    ),
                  
                  if (card.website.isNotEmpty)
                    _ContactRow(
                      icon: Icons.language,
                      text: card.website,
                      color: template.textColor,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _ContactRow({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: color.withOpacity(0.7),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
