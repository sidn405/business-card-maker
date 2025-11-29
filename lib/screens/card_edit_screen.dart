import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/business_card.dart';
import '../providers/business_card_provider.dart';

class CardEditScreen extends StatefulWidget {
  final BusinessCard card;
  final bool isNewCard;

  const CardEditScreen({
    Key? key,
    required this.card,
    this.isNewCard = false,
  }) : super(key: key);

  @override
  State<CardEditScreen> createState() => _CardEditScreenState();
}

class _CardEditScreenState extends State<CardEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _titleController;
  late TextEditingController _companyController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _websiteController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.card.name);
    _titleController = TextEditingController(text: widget.card.title);
    _companyController = TextEditingController(text: widget.card.company);
    _emailController = TextEditingController(text: widget.card.email);
    _phoneController = TextEditingController(text: widget.card.phone);
    _websiteController = TextEditingController(text: widget.card.website);
    _addressController = TextEditingController(text: widget.card.address);
    _notesController = TextEditingController(text: widget.card.notes);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _companyController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveCard() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name')),
      );
      return;
    }

    final updatedCard = widget.card.copyWith(
      name: _nameController.text.trim(),
      title: _titleController.text.trim(),
      company: _companyController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      website: _websiteController.text.trim(),
      address: _addressController.text.trim(),
      notes: _notesController.text.trim(),
    );

    try {
      final provider = Provider.of<BusinessCardProvider>(context, listen: false);
      
      if (widget.isNewCard) {
        await provider.addCard(updatedCard);
      } else {
        await provider.updateCard(updatedCard);
      }

      if (mounted) {
        // Simply pop back - camera screen will handle closing itself
        Navigator.of(context).pop(true); // Return true to indicate save
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isNewCard ? 'Card saved!' : 'Card updated!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving card: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNewCard ? 'New Business Card' : 'Edit Card'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveCard,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Show scanned image if available
            if (widget.card.imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(widget.card.imagePath!),
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            
            const SizedBox(height: 20),
            
            // Name field
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            
            const SizedBox(height: 16),
            
            // Title field
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                prefixIcon: Icon(Icons.work),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            
            const SizedBox(height: 16),
            
            // Company field
            TextField(
              controller: _companyController,
              decoration: const InputDecoration(
                labelText: 'Company',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            
            const SizedBox(height: 16),
            
            // Email field
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            
            const SizedBox(height: 16),
            
            // Phone field
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            
            const SizedBox(height: 16),
            
            // Website field
            TextField(
              controller: _websiteController,
              decoration: const InputDecoration(
                labelText: 'Website',
                prefixIcon: Icon(Icons.language),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            
            const SizedBox(height: 16),
            
            // Address field
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.words,
            ),
            
            const SizedBox(height: 16),
            
            // Notes field
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            
            const SizedBox(height: 24),
            
            // Save button
            ElevatedButton(
              onPressed: _saveCard,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                widget.isNewCard ? 'Save Card' : 'Update Card',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
