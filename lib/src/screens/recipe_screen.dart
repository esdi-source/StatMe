/// Recipe Screen - Rezepte sammeln, planen, kochen, bewerten
/// Mit Merkliste, Koch-Verlauf und Statistiken

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/recipe_parser_service.dart';

class RecipeScreen extends ConsumerStatefulWidget {
  const RecipeScreen({super.key});

  @override
  ConsumerState<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends ConsumerState<RecipeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rezepte'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.bookmark_border), text: 'Merkliste'),
            Tab(icon: Icon(Icons.restaurant), text: 'Gekocht'),
            Tab(icon: Icon(Icons.analytics), text: 'Statistik'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddRecipeSheet(context),
            tooltip: 'Rezept hinzufügen',
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Bitte anmelden'))
          : TabBarView(
              controller: _tabController,
              children: [
                _WishlistTab(userId: user.id),
                _CookedTab(userId: user.id),
                _StatsTab(userId: user.id),
              ],
            ),
    );
  }

  void _showAddRecipeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddRecipeSheet(),
    );
  }
}

// ============================================================================
// WISHLIST TAB - Merkliste
// ============================================================================

class _WishlistTab extends ConsumerWidget {
  final String userId;

  const _WishlistTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipes = ref.watch(recipesProvider(userId));
    final wishlist = recipes.where((r) => r.status == RecipeStatus.wishlist).toList();

    if (wishlist.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Noch keine Rezepte',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Tippe auf + um ein Rezept hinzuzufügen',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    // Gruppiere nach Kategorie
    final byCategory = <RecipeCategory, List<Recipe>>{};
    for (final r in wishlist) {
      byCategory.putIfAbsent(r.category, () => []).add(r);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final entry in byCategory.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              '${entry.key.emoji} ${entry.key.label} (${entry.value.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ...entry.value.map((r) => _RecipeCard(recipe: r, userId: userId)),
        ],
      ],
    );
  }
}

// ============================================================================
// COOKED TAB - Gekochte Rezepte
// ============================================================================

class _CookedTab extends ConsumerWidget {
  final String userId;

  const _CookedTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipes = ref.watch(recipesProvider(userId));
    final cooked = recipes.where((r) => r.status == RecipeStatus.cooked).toList();

    // Sortiere nach zuletzt gekocht
    cooked.sort((a, b) {
      final aDate = a.lastCookedAt ?? DateTime(2000);
      final bDate = b.lastCookedAt ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });

    if (cooked.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Noch keine Rezepte gekocht',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    // Favoriten oben
    final favorites = cooked.where((r) => r.isFavorite).toList();
    final others = cooked.where((r) => !r.isFavorite).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (favorites.isNotEmpty) ...[
          Text(
            '⭐ Favoriten',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...favorites.map((r) => _RecipeCard(recipe: r, userId: userId)),
          const SizedBox(height: 16),
        ],
        if (others.isNotEmpty) ...[
          Text(
            '🍽️ Alle Rezepte',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...others.map((r) => _RecipeCard(recipe: r, userId: userId)),
        ],
      ],
    );
  }
}

// ============================================================================
// STATS TAB - Statistiken
// ============================================================================

class _StatsTab extends ConsumerWidget {
  final String userId;

  const _StatsTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipes = ref.watch(recipesProvider(userId));
    final stats = RecipeStatistics.calculate(recipes);

    if (recipes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Keine Daten vorhanden',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Übersicht
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Übersicht', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(value: '${stats.totalRecipes}', label: 'Rezepte'),
                    _StatItem(value: '${stats.wishlistCount}', label: 'Merkliste'),
                    _StatItem(value: '${stats.cookedCount}', label: 'Gekocht'),
                    _StatItem(value: '${stats.favoritesCount}', label: 'Favoriten'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Bewertung
        if (stats.avgRating > 0)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Durchschnittsbewertung', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 32),
                      const SizedBox(width: 8),
                      Text(
                        stats.avgRating.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Text(' / 10'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('aus ${stats.totalCookCount} Koch-Sessions', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),

        // Kategorien
        if (stats.byCategory.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nach Kategorie', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: stats.byCategory.entries.map((e) {
                      return Chip(
                        avatar: Text(e.key.emoji),
                        label: Text('${e.key.label}: ${e.value}'),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),

        // Meist gekocht
        if (stats.topCooked.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🔥 Meist gekocht', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...stats.topCooked.map((r) => ListTile(
                        leading: Text(r.category.emoji, style: const TextStyle(fontSize: 24)),
                        title: Text(r.title),
                        trailing: Text('${r.cookCount}x'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      )),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),

        // Lange nicht gekocht
        if (stats.longNotCooked.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('⏰ Lange nicht gekocht', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('Über 30 Tage her', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  const SizedBox(height: 8),
                  ...stats.longNotCooked.map((r) {
                    final days = r.daysSinceLastCooked ?? 0;
                    return ListTile(
                      leading: Text(r.category.emoji, style: const TextStyle(fontSize: 24)),
                      title: Text(r.title),
                      trailing: Text('vor $days Tagen'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    );
                  }),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }
}

// ============================================================================
// RECIPE CARD
// ============================================================================

class _RecipeCard extends ConsumerWidget {
  final Recipe recipe;
  final String userId;

  const _RecipeCard({required this.recipe, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showRecipeDetail(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Bild oder Emoji
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: recipe.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          recipe.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(recipe.category.emoji, style: const TextStyle(fontSize: 28)),
                          ),
                        ),
                      )
                    : Center(child: Text(recipe.category.emoji, style: const TextStyle(fontSize: 28))),
              ),
              const SizedBox(width: 12),
              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (recipe.isFavorite)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.star, color: Colors.amber, size: 16),
                          ),
                        Expanded(
                          child: Text(
                            recipe.title,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (recipe.totalTimeMinutes > 0) ...[
                          Icon(Icons.timer_outlined, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(recipe.formattedTime, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          const SizedBox(width: 12),
                        ],
                        if (recipe.servings > 0) ...[
                          Icon(Icons.people_outline, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text('${recipe.servings}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ],
                    ),
                    if (recipe.cookCount > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('${recipe.cookCount}x gekocht', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          if (recipe.avgRating != null) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.star, size: 14, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(recipe.avgRating!.toStringAsFixed(1), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Kochen-Button
              IconButton(
                icon: const Icon(Icons.restaurant_menu),
                onPressed: () => _showCookDialog(context, ref),
                tooltip: 'Jetzt kochen',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRecipeDetail(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RecipeDetailSheet(recipe: recipe, userId: userId),
    );
  }

  void _showCookDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _CookDialog(recipe: recipe, userId: userId),
    );
  }
}

// ============================================================================
// ADD RECIPE SHEET
// ============================================================================

class _AddRecipeSheet extends ConsumerStatefulWidget {
  const _AddRecipeSheet();

  @override
  ConsumerState<_AddRecipeSheet> createState() => _AddRecipeSheetState();
}

class _AddRecipeSheetState extends ConsumerState<_AddRecipeSheet> {
  bool _isLoading = false;
  String _mode = 'link'; // 'link', 'manual'

  // Link mode
  final _urlController = TextEditingController();
  ParsedRecipeData? _parsedData;

  // Manual mode / Edit
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _notesController = TextEditingController();
  final _servingsController = TextEditingController(text: '4');
  final _prepTimeController = TextEditingController();
  final _cookTimeController = TextEditingController();
  RecipeCategory _category = RecipeCategory.other;
  Set<RecipeTag> _tags = {};
  final List<RecipeIngredient> _ingredients = [];
  final List<String> _steps = [];
  String? _imageUrl;
  String? _sourceUrl;

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _notesController.dispose();
    _servingsController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Rezept hinzufügen', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            // Mode Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'link', label: Text('Link'), icon: Icon(Icons.link)),
                  ButtonSegment(value: 'manual', label: Text('Manuell'), icon: Icon(Icons.edit)),
                ],
                selected: {_mode},
                onSelectionChanged: (v) => setState(() => _mode = v.first),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _mode == 'link' ? _buildLinkMode(scrollController) : _buildManualMode(scrollController),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkMode(ScrollController scrollController) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _urlController,
          decoration: InputDecoration(
            labelText: 'Rezept-URL',
            hintText: 'https://...',
            prefixIcon: const Icon(Icons.link),
            suffixIcon: _isLoading
                ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                : IconButton(icon: const Icon(Icons.search), onPressed: _parseUrl),
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
          onSubmitted: (_) => _parseUrl(),
        ),
        const SizedBox(height: 16),
        if (_parsedData != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      const Text('Rezept gefunden!', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(_parsedData!.title, style: Theme.of(context).textTheme.titleLarge),
                  if (_parsedData!.description != null) ...[
                    const SizedBox(height: 4),
                    Text(_parsedData!.description!, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (_parsedData!.servings > 0) Chip(label: Text('${_parsedData!.servings} Portionen')),
                      if (_parsedData!.prepTimeMinutes != null) Chip(label: Text('${_parsedData!.prepTimeMinutes} Min Vorbereitung')),
                      if (_parsedData!.cookTimeMinutes != null) Chip(label: Text('${_parsedData!.cookTimeMinutes} Min Kochen')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('${_parsedData!.ingredientsRaw.length} Zutaten, ${_parsedData!.steps.length} Schritte'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saveFromParsed,
            icon: const Icon(Icons.save),
            label: const Text('Zur Merkliste hinzufügen'),
          ),
        ] else ...[
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Füge eine Rezept-URL ein und tippe auf Suchen. Die Zutaten und Schritte werden automatisch extrahiert.',
                      style: TextStyle(color: Colors.blue.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildManualMode(ScrollController scrollController) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(labelText: 'Titel *', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descController,
          decoration: const InputDecoration(labelText: 'Beschreibung', border: OutlineInputBorder()),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        // Kategorie
        DropdownButtonFormField<RecipeCategory>(
          value: _category,
          decoration: const InputDecoration(labelText: 'Kategorie', border: OutlineInputBorder()),
          items: RecipeCategory.values.map((c) => DropdownMenuItem(value: c, child: Text('${c.emoji} ${c.label}'))).toList(),
          onChanged: (v) => setState(() => _category = v ?? RecipeCategory.other),
        ),
        const SizedBox(height: 12),
        // Portionen, Zeit
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _servingsController,
                decoration: const InputDecoration(labelText: 'Portionen', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _prepTimeController,
                decoration: const InputDecoration(labelText: 'Vorbereitung (Min)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _cookTimeController,
                decoration: const InputDecoration(labelText: 'Kochen (Min)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Tags
        Text('Tags', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: RecipeTag.values.map((t) {
            final selected = _tags.contains(t);
            return FilterChip(
              label: Text('${t.emoji} ${t.label}'),
              selected: selected,
              onSelected: (v) => setState(() => v ? _tags.add(t) : _tags.remove(t)),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        // Zutaten
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Zutaten (${_ingredients.length})', style: Theme.of(context).textTheme.titleSmall),
            IconButton(icon: const Icon(Icons.add), onPressed: _addIngredient),
          ],
        ),
        ..._ingredients.asMap().entries.map((e) => ListTile(
              title: Text(e.value.displayText),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => setState(() => _ingredients.removeAt(e.key)),
              ),
              dense: true,
              contentPadding: EdgeInsets.zero,
            )),
        const SizedBox(height: 16),
        // Schritte
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Schritte (${_steps.length})', style: Theme.of(context).textTheme.titleSmall),
            IconButton(icon: const Icon(Icons.add), onPressed: _addStep),
          ],
        ),
        ..._steps.asMap().entries.map((e) => ListTile(
              leading: CircleAvatar(radius: 12, child: Text('${e.key + 1}')),
              title: Text(e.value, maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => setState(() => _steps.removeAt(e.key)),
              ),
              dense: true,
              contentPadding: EdgeInsets.zero,
            )),
        const SizedBox(height: 16),
        TextField(
          controller: _notesController,
          decoration: const InputDecoration(labelText: 'Notizen', border: OutlineInputBorder()),
          maxLines: 3,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _titleController.text.isNotEmpty ? _saveManual : null,
          icon: const Icon(Icons.save),
          label: const Text('Speichern'),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Future<void> _parseUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final data = await RecipeParserService.parseFromUrl(url);
      setState(() {
        _parsedData = data;
        _isLoading = false;
      });

      if (data == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konnte Rezept nicht extrahieren. Versuche manuell.')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
    }
  }

  void _saveFromParsed() {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null || _parsedData == null) return;

    final now = DateTime.now();
    final recipe = Recipe(
      id: const Uuid().v4(),
      oderId: user.id,
      title: _parsedData!.title,
      description: _parsedData!.description,
      imageUrl: _parsedData!.imageUrl,
      sourceUrl: _parsedData!.sourceUrl,
      ingredients: _parsedData!.parsedIngredients,
      steps: _parsedData!.steps,
      servings: _parsedData!.servings,
      prepTimeMinutes: _parsedData!.prepTimeMinutes,
      cookTimeMinutes: _parsedData!.cookTimeMinutes,
      category: _parsedData!.category ?? RecipeCategory.other,
      caloriesPerServing: _parsedData!.caloriesPerServing,
      proteinGrams: _parsedData!.proteinGrams,
      carbsGrams: _parsedData!.carbsGrams,
      fatGrams: _parsedData!.fatGrams,
      status: RecipeStatus.wishlist,
      createdAt: now,
      updatedAt: now,
    );

    ref.read(recipesProvider(user.id).notifier).addRecipe(recipe);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rezept gespeichert!')),
    );
  }

  void _saveManual() {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final now = DateTime.now();
    final recipe = Recipe(
      id: const Uuid().v4(),
      oderId: user.id,
      title: title,
      description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
      imageUrl: _imageUrl,
      sourceUrl: _sourceUrl,
      ingredients: _ingredients,
      steps: _steps,
      servings: int.tryParse(_servingsController.text) ?? 4,
      prepTimeMinutes: int.tryParse(_prepTimeController.text),
      cookTimeMinutes: int.tryParse(_cookTimeController.text),
      category: _category,
      tags: _tags,
      status: RecipeStatus.wishlist,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      createdAt: now,
      updatedAt: now,
    );

    ref.read(recipesProvider(user.id).notifier).addRecipe(recipe);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rezept gespeichert!')),
    );
  }

  void _addIngredient() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final unitController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Zutat hinzufügen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name *')),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Menge'), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: unitController, decoration: const InputDecoration(labelText: 'Einheit'))),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen')),
          TextButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                setState(() {
                  _ingredients.add(RecipeIngredient(
                    name: nameController.text.trim(),
                    amount: double.tryParse(amountController.text),
                    unit: unitController.text.trim().isNotEmpty ? unitController.text.trim() : null,
                  ));
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    );
  }

  void _addStep() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Schritt hinzufügen'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Anleitung'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen')),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() => _steps.add(controller.text.trim()));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// RECIPE DETAIL SHEET
// ============================================================================

class _RecipeDetailSheet extends ConsumerStatefulWidget {
  final Recipe recipe;
  final String userId;

  const _RecipeDetailSheet({required this.recipe, required this.userId});

  @override
  ConsumerState<_RecipeDetailSheet> createState() => _RecipeDetailSheetState();
}

class _RecipeDetailSheetState extends ConsumerState<_RecipeDetailSheet> {
  late int _servings;

  @override
  void initState() {
    super.initState();
    _servings = widget.recipe.servings;
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final ingredients = recipe.ingredientsForServings(_servings);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(recipe.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), maxLines: 2),
                  ),
                  IconButton(
                    icon: Icon(recipe.isFavorite ? Icons.star : Icons.star_border, color: recipe.isFavorite ? Colors.amber : null),
                    onPressed: () => _toggleFavorite(),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Bild
                  if (recipe.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(recipe.imageUrl!, height: 200, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
                    ),
                  const SizedBox(height: 12),

                  // Infos
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(avatar: Text(recipe.category.emoji), label: Text(recipe.category.label)),
                      if (recipe.totalTimeMinutes > 0) Chip(avatar: const Icon(Icons.timer, size: 18), label: Text(recipe.formattedTime)),
                      if (recipe.cookCount > 0) Chip(label: Text('${recipe.cookCount}x gekocht')),
                      if (recipe.avgRating != null) Chip(avatar: const Icon(Icons.star, color: Colors.amber, size: 18), label: Text(recipe.avgRating!.toStringAsFixed(1))),
                    ],
                  ),
                  if (recipe.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: recipe.tags.map((t) => Chip(label: Text('${t.emoji} ${t.label}'), visualDensity: VisualDensity.compact)).toList(),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Portionen-Anpassung
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: _servings > 1 ? () => setState(() => _servings--) : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('$_servings Portionen', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => _servings++)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Zutaten
                  Text('Zutaten', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...ingredients.map((i) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 6),
                            const SizedBox(width: 8),
                            Expanded(child: Text(i.displayText)),
                          ],
                        ),
                      )),
                  const SizedBox(height: 16),

                  // Schritte
                  if (recipe.steps.isNotEmpty) ...[
                    Text('Zubereitung', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...recipe.steps.asMap().entries.map((e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(radius: 12, child: Text('${e.key + 1}')),
                              const SizedBox(width: 12),
                              Expanded(child: Text(e.value)),
                            ],
                          ),
                        )),
                  ],

                  // Nährwerte
                  if (recipe.caloriesPerServing != null) ...[
                    const SizedBox(height: 16),
                    Text('Nährwerte pro Portion', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (recipe.caloriesPerServing != null) Chip(label: Text('${recipe.caloriesPerServing} kcal')),
                        if (recipe.proteinGrams != null) Chip(label: Text('${recipe.proteinGrams}g Protein')),
                        if (recipe.carbsGrams != null) Chip(label: Text('${recipe.carbsGrams}g Kohlenhydrate')),
                        if (recipe.fatGrams != null) Chip(label: Text('${recipe.fatGrams}g Fett')),
                      ],
                    ),
                  ],

                  // Koch-Verlauf
                  if (recipe.cookLogs.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('Koch-Verlauf', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...recipe.cookLogs.reversed.take(5).map((log) => Card(
                          child: ListTile(
                            leading: log.rating != null
                                ? CircleAvatar(child: Text('${log.rating!.overall}'))
                                : const CircleAvatar(child: Icon(Icons.restaurant)),
                            title: Text(DateFormat.yMd('de').format(log.cookedAt)),
                            subtitle: log.rating?.notes != null ? Text(log.rating!.notes!, maxLines: 1) : null,
                            trailing: Text('${log.servingsCooked} Portionen'),
                          ),
                        )),
                  ],

                  const SizedBox(height: 24),
                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            showDialog(
                              context: context,
                              builder: (ctx) => _CookDialog(recipe: recipe, userId: widget.userId),
                            );
                          },
                          icon: const Icon(Icons.restaurant_menu),
                          label: const Text('Jetzt kochen'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _deleteRecipe(),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Löschen'),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleFavorite() {
    ref.read(recipesProvider(widget.userId).notifier).updateRecipe(
          widget.recipe.copyWith(isFavorite: !widget.recipe.isFavorite, updatedAt: DateTime.now()),
        );
    Navigator.pop(context);
  }

  void _deleteRecipe() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rezept löschen?'),
        content: Text('„${widget.recipe.title}" wirklich löschen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen')),
          TextButton(
            onPressed: () {
              ref.read(recipesProvider(widget.userId).notifier).removeRecipe(widget.recipe.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Löschen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// COOK DIALOG - Kochen abschließen mit Bewertung
// ============================================================================

class _CookDialog extends ConsumerStatefulWidget {
  final Recipe recipe;
  final String userId;

  const _CookDialog({required this.recipe, required this.userId});

  @override
  ConsumerState<_CookDialog> createState() => _CookDialogState();
}

class _CookDialogState extends ConsumerState<_CookDialog> {
  int _servingsCooked = 4;
  int _rating = 7;
  int? _mood;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _servingsCooked = widget.recipe.servings;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.recipe.category.emoji} ${widget.recipe.title}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Portionen gekocht:'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: _servingsCooked > 1 ? () => setState(() => _servingsCooked--) : null,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('$_servingsCooked', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => _servingsCooked++)),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Bewertung (1-10):'),
            Slider(
              value: _rating.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '$_rating',
              onChanged: (v) => setState(() => _rating = v.round()),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('1', style: TextStyle(fontSize: 12)),
                Text('$_rating', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Text('10', style: TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Stimmung danach (optional):'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [1, 3, 5, 7, 9].map((v) {
                final emojis = ['😞', '😕', '😐', '🙂', '😊'];
                final idx = (v - 1) ~/ 2;
                return GestureDetector(
                  onTap: () => setState(() => _mood = _mood == v ? null : v),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _mood == v ? Colors.blue.shade100 : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(emojis[idx], style: const TextStyle(fontSize: 24)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notizen (optional)', border: OutlineInputBorder()),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
        FilledButton(
          onPressed: _save,
          child: const Text('Speichern'),
        ),
      ],
    );
  }

  void _save() {
    final now = DateTime.now();
    final log = CookLog(
      id: const Uuid().v4(),
      cookedAt: now,
      servingsCooked: _servingsCooked,
      rating: RecipeRating(
        overall: _rating,
        mood: _mood,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        ratedAt: now,
      ),
    );

    final updated = widget.recipe.copyWith(
      status: RecipeStatus.cooked,
      cookLogs: [...widget.recipe.cookLogs, log],
      updatedAt: now,
    );

    ref.read(recipesProvider(widget.userId).notifier).updateRecipe(updated);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Koch-Session gespeichert!')),
    );
  }
}
