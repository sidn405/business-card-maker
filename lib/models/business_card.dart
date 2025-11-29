import 'package:uuid/uuid.dart';

class BusinessCard {
  final String id;
  final String name;
  final String title;
  final String company;
  final String email;
  final String phone;
  final String website;
  final String address;
  final String notes;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  BusinessCard({
    String? id,
    required this.name,
    this.title = '',
    this.company = '',
    this.email = '',
    this.phone = '',
    this.website = '',
    this.address = '',
    this.notes = '',
    this.imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // IMPROVED: Better OCR parsing logic
  factory BusinessCard.fromOCRText(String extractedText, String? imagePath) {
    final lines = extractedText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    
    String name = '';
    String title = '';
    String company = '';
    String email = '';
    String phone = '';
    String website = '';
    String address = '';
    List<String> otherLines = [];

    // Company/organization keywords
    final companyKeywords = [
      'nation of islam',
      'mosque',
      'masjid',
      'church',
      'temple',
      'inc',
      'llc',
      'ltd',
      'corporation',
      'corp',
      'company',
      'co.',
      'organization',
      'association',
      'foundation',
    ];

    // Title keywords
    final titleKeywords = [
      'ceo',
      'president',
      'director',
      'manager',
      'coordinator',
      'assistant',
      'representative',
      'specialist',
      'consultant',
      'officer',
      'sales',
      'marketing',
      'executive',
      'engineer',
      'developer',
      'designer',
      'advisor',
    ];

    for (var line in lines) {
      final lowerLine = line.toLowerCase();
      
      // Extract email
      if (line.contains('@') && email.isEmpty) {
        // Clean up common OCR artifacts from email
        final emailMatch = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b')
            .firstMatch(line);
        if (emailMatch != null) {
          email = emailMatch.group(0)!;
        }
        continue;
      }
      
      // Extract phone number
      if (RegExp(r'(?:office|phone|cell|mobile|fax|tel)[:\s]*\(?\d', caseSensitive: false)
          .hasMatch(line)) {
        // Extract just the number part
        final phoneMatch = RegExp(r'[\d\-\(\)\+\s]{10,}').firstMatch(line);
        if (phoneMatch != null && phone.isEmpty) {
          phone = phoneMatch.group(0)!.trim();
        }
        continue;
      }
      
      // Extract website
      if ((lowerLine.contains('www.') || 
           lowerLine.contains('.com') || 
           lowerLine.contains('.org') ||
           lowerLine.contains('.net') ||
           lowerLine.contains('http')) && website.isEmpty) {
        // Clean up website
        website = line
            .replaceAll(RegExp(r'https?://'), '')
            .replaceAll(RegExp(r'www\.'), '')
            .trim();
        continue;
      }
      
      // Check if line is a company name (contains company keywords)
      bool isCompany = companyKeywords.any((keyword) => 
        lowerLine.contains(keyword));
      
      if (isCompany && company.isEmpty) {
        company = line;
        continue;
      }
      
      // Check if line is a title (contains title keywords)
      bool isTitle = titleKeywords.any((keyword) => 
        lowerLine.contains(keyword));
      
      if (isTitle && title.isEmpty) {
        title = line;
        continue;
      }
      
      // If it looks like an address (has numbers and street indicators)
      if (RegExp(r'\d+.*(?:road|rd|street|st|avenue|ave|blvd|drive|dr|lane|ln|way|circle|court|ct)', 
          caseSensitive: false).hasMatch(line)) {
        if (address.isEmpty) {
          address = line;
        } else {
          address += '\n$line';
        }
        continue;
      }
      
      // If it looks like city/state/zip
      if (RegExp(r'[A-Z]{2}\s+\d{5}').hasMatch(line) ||
          RegExp(r',\s*[A-Z]{2}').hasMatch(line)) {
        if (address.isEmpty) {
          address = line;
        } else {
          address += '\n$line';
        }
        continue;
      }
      
      // Everything else goes to otherLines for processing
      otherLines.add(line);
    }

    // Smart name detection: First line that's not a company/title/contact info
    // and contains proper capitalization (likely a person's name)
    for (var line in otherLines) {
      if (name.isEmpty) {
        // Check if it looks like a person's name (2-4 words, properly capitalized)
        final words = line.split(' ');
        if (words.length >= 2 && words.length <= 4) {
          // Check if words are properly capitalized (likely a name)
          bool isProperlyCapitalized = words.every((word) => 
            word.isNotEmpty && 
            word[0] == word[0].toUpperCase() &&
            word.substring(1) == word.substring(1).toLowerCase()
          );
          
          if (isProperlyCapitalized) {
            name = line;
            continue;
          }
        }
      }
      
      // If we still don't have a title, check remaining lines
      if (title.isEmpty && line.length < 50) {
        title = line;
      }
    }

    // Fallback: if still no name, use first line that's not company
    if (name.isEmpty && otherLines.isNotEmpty) {
      name = otherLines.first;
    }

    // Clean up extracted data
    name = _cleanText(name);
    title = _cleanText(title);
    company = _cleanText(company);
    email = _cleanText(email);
    phone = _cleanText(phone);
    website = _cleanText(website);
    address = _cleanText(address);

    return BusinessCard(
      name: name.isNotEmpty ? name : 'Unknown',
      title: title,
      company: company,
      email: email,
      phone: phone,
      website: website,
      address: address,
      imagePath: imagePath,
    );
  }

  // Helper to clean OCR artifacts
  static String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')  // Multiple spaces to single
        .replaceAll(RegExp(r'[^\x00-\x7F]'), '') // Remove non-ASCII
        .trim();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'company': company,
      'email': email,
      'phone': phone,
      'website': website,
      'address': address,
      'notes': notes,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory BusinessCard.fromJson(Map<String, dynamic> json) {
    return BusinessCard(
      id: json['id'],
      name: json['name'] ?? '',
      title: json['title'] ?? '',
      company: json['company'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      website: json['website'] ?? '',
      address: json['address'] ?? '',
      notes: json['notes'] ?? '',
      imagePath: json['imagePath'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  BusinessCard copyWith({
    String? name,
    String? title,
    String? company,
    String? email,
    String? phone,
    String? website,
    String? address,
    String? notes,
    String? imagePath,
  }) {
    return BusinessCard(
      id: id,
      name: name ?? this.name,
      title: title ?? this.title,
      company: company ?? this.company,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  String toVCard() {
    return '''BEGIN:VCARD
VERSION:3.0
FN:$name
ORG:$company
TITLE:$title
EMAIL:$email
TEL:$phone
URL:$website
ADR:;;$address;;;;
NOTE:$notes
END:VCARD''';
  }
}