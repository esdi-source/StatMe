/// Skin Photos Screen - Hautfotos verwalten (nur zur persönlichen Dokumentation)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

class SkinPhotosScreen extends ConsumerWidget {
  const SkinPhotosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ref.watch(designTokensProvider);
    final photos = ref.watch(skinPhotosNotifierProvider);
    
    final sorted = [...photos]..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fotos'),
      ),
      body: photos.isEmpty
          ? _buildEmptyState(tokens)
          : _buildPhotoGrid(context, ref, tokens, sorted),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPhotoDialog(context, ref),
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }

  Widget _buildEmptyState(DesignTokens tokens) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_camera,
              size: 64,
              color: tokens.textDisabled.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Keine Fotos',
              style: TextStyle(
                color: tokens.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dokumentiere deine Haut mit Fotos.\nNur für dich, keine Analyse.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tokens.textDisabled,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGrid(
    BuildContext context,
    WidgetRef ref,
    DesignTokens tokens,
    List<SkinPhoto> photos,
  ) {
    // Group by month
    final Map<String, List<SkinPhoto>> grouped = {};
    for (final photo in photos) {
      final key = DateFormat('MMMM yyyy', 'de_DE').format(photo.date);
      grouped.putIfAbsent(key, () => []).add(photo);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                entry.key,
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: entry.value.length,
              itemBuilder: (context, index) {
                final photo = entry.value[index];
                return _buildPhotoCard(context, ref, tokens, photo);
              },
            ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildPhotoCard(
    BuildContext context,
    WidgetRef ref,
    DesignTokens tokens,
    SkinPhoto photo,
  ) {
    return GestureDetector(
      onTap: () => _showPhotoDetail(context, ref, tokens, photo),
      onLongPress: () => _showDeleteDialog(context, ref, photo),
      child: Container(
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
          border: Border.all(color: tokens.divider),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Placeholder for image
            ClipRRect(
              borderRadius: BorderRadius.circular(tokens.radiusMedium - 1),
              child: Container(
                color: tokens.primary.withOpacity(0.1),
                child: Center(
                  child: Icon(
                    Icons.photo,
                    color: tokens.primary.withOpacity(0.5),
                    size: 32,
                  ),
                ),
              ),
            ),
            // Date overlay
            Positioned(
              bottom: 4,
              left: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  DateFormat('dd.MM').format(photo.date),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotoDetail(
    BuildContext context,
    WidgetRef ref,
    DesignTokens tokens,
    SkinPhoto photo,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo placeholder
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: tokens.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    Icons.photo,
                    color: tokens.primary.withOpacity(0.5),
                    size: 64,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                DateFormat('EEEE, dd. MMMM yyyy', 'de_DE').format(photo.date),
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              
              if (photo.note != null && photo.note!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  photo.note!,
                  style: TextStyle(
                    color: tokens.textSecondary,
                  ),
                ),
              ],
              
              const SizedBox(height: 20),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showDeleteDialog(context, ref, photo);
                    },
                    child: Text(
                      'Löschen',
                      style: TextStyle(color: tokens.error),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Schließen'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, SkinPhoto photo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Foto löschen?'),
        content: const Text('Diese Aktion kann nicht rückgängig gemacht werden.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              ref.read(skinPhotosNotifierProvider.notifier).delete(photo.id);
              Navigator.pop(context);
            },
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  void _showAddPhotoDialog(BuildContext context, WidgetRef ref) {
    final notesController = TextEditingController();
    DateTime date = DateTime.now();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final tokens = ref.watch(designTokensProvider);
        
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: BoxDecoration(
                color: tokens.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: tokens.textDisabled.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Neues Foto',
                    style: TextStyle(
                      color: tokens.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fotos werden nur lokal gespeichert und nicht analysiert.',
                    style: TextStyle(
                      color: tokens.textDisabled,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Photo selection placeholder
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: tokens.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: tokens.primary,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo,
                          color: tokens.primary,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Foto aufnehmen/auswählen',
                          style: TextStyle(
                            color: tokens.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '(Demo: Kamerazugriff deaktiviert)',
                          style: TextStyle(
                            color: tokens.textDisabled,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.calendar_today, color: tokens.primary),
                    title: Text(DateFormat('dd.MM.yyyy').format(date)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => date = picked);
                      }
                    },
                  ),
                  
                  TextFormField(
                    controller: notesController,
                    decoration: InputDecoration(
                      labelText: 'Notizen (optional)',
                      hintText: 'z.B. Nach dem Aufwachen, nach Behandlung...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await _addPhoto(ref, date, notesController.text);
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text('Speichern (Demo)'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _addPhoto(WidgetRef ref, DateTime date, String notes) async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;
    
    final photo = SkinPhoto(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: user.id,
      date: date,
      localPath: 'demo_placeholder', // In real app: actual path
      note: notes.isEmpty ? null : notes,
      createdAt: DateTime.now(),
    );
    
    await ref.read(skinPhotosNotifierProvider.notifier).add(photo);
  }
}
