/// Media Screen - Filme & Serien verwalten
/// Mit TMDB-Anbindung, Merkliste, Bewertungen und Statistiken
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/tmdb_service.dart';

class MediaScreen extends ConsumerStatefulWidget {
  const MediaScreen({super.key});

  @override
  ConsumerState<MediaScreen> createState() => _MediaScreenState();
}

class _MediaScreenState extends ConsumerState<MediaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: const Text('Filme & Serien'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.bookmark_outline), text: 'Merkliste'),
            Tab(icon: Icon(Icons.play_circle_outline), text: 'Am Schauen'),
            Tab(icon: Icon(Icons.check_circle_outline), text: 'Gesehen'),
            Tab(icon: Icon(Icons.analytics_outlined), text: 'Statistik'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
            tooltip: 'Suchen',
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Bitte anmelden'))
          : TabBarView(
              controller: _tabController,
              children: [
                _MediaListTab(userId: user.id, status: MediaStatus.watchlist),
                _MediaListTab(userId: user.id, status: MediaStatus.watching),
                _MediaListTab(userId: user.id, status: MediaStatus.watched),
                _StatsTab(userId: user.id),
              ],
            ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _MediaSearchSheet(),
    );
  }
}

// ============================================================================
// MEDIA LIST TAB
// ============================================================================

class _MediaListTab extends ConsumerWidget {
  final String userId;
  final MediaStatus status;

  const _MediaListTab({required this.userId, required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(userMediaEntriesProvider(userId));
    final filtered = entries.where((e) => e.status == status).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == MediaStatus.watchlist
                  ? Icons.bookmark_outline
                  : status == MediaStatus.watching
                      ? Icons.play_circle_outline
                      : Icons.check_circle_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              status == MediaStatus.watchlist
                  ? 'Merkliste ist leer'
                  : status == MediaStatus.watching
                      ? 'Nichts am Schauen'
                      : 'Noch nichts gesehen',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _showSearch(context),
              icon: const Icon(Icons.search),
              label: const Text('Film oder Serie suchen'),
            ),
          ],
        ),
      );
    }

    // Gruppiert nach Typ
    final movies = filtered.where((e) => e.media.type == MediaType.movie).toList();
    final tvShows = filtered.where((e) => e.media.type == MediaType.tvShow).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (movies.isNotEmpty) ...[
          _SectionHeader(title: '🎬 Filme (${movies.length})'),
          ...movies.map((e) => _MediaCard(entry: e, userId: userId)),
          const SizedBox(height: 16),
        ],
        if (tvShows.isNotEmpty) ...[
          _SectionHeader(title: '📺 Serien (${tvShows.length})'),
          ...tvShows.map((e) => _MediaCard(entry: e, userId: userId)),
        ],
      ],
    );
  }

  void _showSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _MediaSearchSheet(),
    );
  }
}

// ============================================================================
// SECTION HEADER
// ============================================================================

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ============================================================================
// MEDIA CARD
// ============================================================================

class _MediaCard extends ConsumerWidget {
  final UserMediaEntry entry;
  final String userId;

  const _MediaCard({required this.entry, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = entry.media;
    final color = Color(entry.status.colorValue);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () => _showDetails(context, ref),
        child: Row(
          children: [
            // Poster
            SizedBox(
              width: 80,
              height: 120,
              child: media.fullPosterUrl != null
                  ? Image.network(
                      media.fullPosterUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(media.type.emoji, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            media.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${media.year}${media.genres.isNotEmpty ? ' • ${media.genres.first.label}' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Progress für Serien
                    if (media.type == MediaType.tvShow) ...[
                      LinearProgressIndicator(
                        value: entry.progress,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${entry.watchedEpisodeCount}/${media.numberOfEpisodes ?? '?'} Folgen',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                    // Bewertung
                    if (entry.rating != null)
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            entry.rating!.overall.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            // Status-Buttons
            PopupMenuButton<MediaStatus>(
              icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
              onSelected: (status) => _changeStatus(ref, status),
              itemBuilder: (context) => MediaStatus.values.map((s) {
                return PopupMenuItem(
                  value: s,
                  child: Row(
                    children: [
                      Text(s.emoji),
                      const SizedBox(width: 8),
                      Text(s.label),
                      if (s == entry.status) ...[
                        const Spacer(),
                        const Icon(Icons.check, size: 16, color: Colors.green),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade300,
      child: const Center(
        child: Icon(Icons.movie_outlined, color: Colors.grey),
      ),
    );
  }

  void _showDetails(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MediaDetailSheet(entry: entry, userId: userId),
    );
  }

  void _changeStatus(WidgetRef ref, MediaStatus status) {
    ref.read(userMediaEntriesProvider(userId).notifier).update(
      entry.copyWith(
        status: status,
        updatedAt: DateTime.now(),
        watchedDate: status == MediaStatus.watched ? DateTime.now() : entry.watchedDate,
      ),
    );
  }
}

// ============================================================================
// STATS TAB
// ============================================================================

class _StatsTab extends ConsumerWidget {
  final String userId;

  const _StatsTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(userMediaEntriesProvider(userId));
    final stats = MediaStatistics.calculate(entries);

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Keine Statistiken',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Füge Filme und Serien hinzu',
              style: TextStyle(color: Colors.grey.shade500),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Übersicht',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      label: 'Filme',
                      value: '${stats.totalMovies}',
                      icon: Icons.movie,
                      color: Colors.blue,
                    ),
                    _StatItem(
                      label: 'Serien',
                      value: '${stats.totalTvShows}',
                      icon: Icons.tv,
                      color: Colors.purple,
                    ),
                    _StatItem(
                      label: 'Merkliste',
                      value: '${stats.watchlistCount}',
                      icon: Icons.bookmark,
                      color: Colors.orange,
                    ),
                    _StatItem(
                      label: 'Ø Bewertung',
                      value: stats.avgRating > 0 ? stats.avgRating.toStringAsFixed(1) : '--',
                      icon: Icons.star,
                      color: Colors.amber,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Lieblingsgenre
        if (stats.favoriteGenre != null)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(stats.favoriteGenre!.emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
              title: const Text('Lieblingsgenre'),
              subtitle: Text(stats.favoriteGenre!.label),
              trailing: Text(
                '${stats.genreDistribution[stats.favoriteGenre] ?? 0} Titel',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Genre-Verteilung
        if (stats.genreDistribution.isNotEmpty) ...[
          const Text(
            'Genres',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (stats.genreDistribution.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value)))
                .take(8)
                .map((e) => Chip(
                      avatar: Text(e.key.emoji),
                      label: Text('${e.key.label}: ${e.value}'),
                    ))
                .toList(),
          ),
        ],

        const SizedBox(height: 16),

        // Top Schauspieler
        if (stats.topActors.isNotEmpty) ...[
          const Text(
            'Häufigste Schauspieler',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...stats.topActors.entries.take(5).map((e) {
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey.shade200,
                child: Text(e.key[0], style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              title: Text(e.key),
              trailing: Text(
                '${e.value} Titel',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

// ============================================================================
// MEDIA SEARCH SHEET
// ============================================================================

class _MediaSearchSheet extends ConsumerStatefulWidget {
  const _MediaSearchSheet();

  @override
  ConsumerState<_MediaSearchSheet> createState() => _MediaSearchSheetState();
}

class _MediaSearchSheetState extends ConsumerState<_MediaSearchSheet> {
  final _searchController = TextEditingController();
  List<MediaItem> _results = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final results = await TmdbService.searchMulti(query);
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Film oder Serie suchen...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _results = []);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          const SizedBox(height: 16),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty
                              ? 'Suche nach Filmen und Serien'
                              : 'Keine Ergebnisse',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final media = _results[index];
                          return _SearchResultCard(
                            media: media,
                            onTap: () => _addMedia(media),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _addMedia(MediaItem media) {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    final entry = UserMediaEntry(
      id: const Uuid().v4(),
      oderId: user.id,
      media: media,
      status: MediaStatus.watchlist,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    ref.read(userMediaEntriesProvider(user.id).notifier).add(entry);
    
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${media.title} zur Merkliste hinzugefügt'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ============================================================================
// SEARCH RESULT CARD
// ============================================================================

class _SearchResultCard extends StatelessWidget {
  final MediaItem media;
  final VoidCallback onTap;

  const _SearchResultCard({required this.media, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 48,
            height: 72,
            child: media.fullPosterUrl != null
                ? Image.network(
                    media.fullPosterUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.movie_outlined),
                    ),
                  )
                : Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.movie_outlined),
                  ),
          ),
        ),
        title: Row(
          children: [
            Text(media.type.emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                media.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Text(
          '${media.year}${media.genres.isNotEmpty ? ' • ${media.genres.first.label}' : ''}',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: onTap,
          tooltip: 'Zur Merkliste',
        ),
        onTap: onTap,
      ),
    );
  }
}

// ============================================================================
// MEDIA DETAIL SHEET
// ============================================================================

class _MediaDetailSheet extends ConsumerStatefulWidget {
  final UserMediaEntry entry;
  final String userId;

  const _MediaDetailSheet({required this.entry, required this.userId});

  @override
  ConsumerState<_MediaDetailSheet> createState() => _MediaDetailSheetState();
}

class _MediaDetailSheetState extends ConsumerState<_MediaDetailSheet> {
  late UserMediaEntry _entry;
  double _ratingValue = 5.0;
  final bool _showRating = false;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
    if (_entry.rating != null) {
      _ratingValue = _entry.rating!.overall;
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = _entry.media;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header mit Poster
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Poster
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 120,
                        height: 180,
                        child: media.fullPosterUrl != null
                            ? Image.network(
                                media.fullPosterUrl!,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.movie_outlined, size: 48),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            media.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${media.type.emoji} ${media.type.label} • ${media.year}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          if (media.runtime != null && media.type == MediaType.movie)
                            Text(
                              '${media.runtime} Min',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          if (media.type == MediaType.tvShow && media.numberOfSeasons != null)
                            Text(
                              '${media.numberOfSeasons} Staffeln • ${media.numberOfEpisodes ?? '?'} Folgen',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          const SizedBox(height: 8),
                          // Genres
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: media.genres.take(3).map((g) {
                              return Chip(
                                label: Text(g.label, style: const TextStyle(fontSize: 10)),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          // TMDB Rating
                          if (media.voteAverage != null)
                            Row(
                              children: [
                                const Icon(Icons.star, size: 16, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  '${media.voteAverage!.toStringAsFixed(1)}/10',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  ' (TMDB)',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Status-Buttons
                Row(
                  children: MediaStatus.values.map((s) {
                    final isSelected = _entry.status == s;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ElevatedButton(
                          onPressed: () => _updateStatus(s),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected
                                ? Color(s.colorValue)
                                : Colors.grey.shade200,
                            foregroundColor: isSelected
                                ? Colors.white
                                : Colors.grey.shade700,
                          ),
                          child: Text(s.emoji, style: const TextStyle(fontSize: 16)),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Beschreibung
                if (media.overview != null && media.overview!.isNotEmpty) ...[
                  const Text(
                    'Beschreibung',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    media.overview!,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 16),
                ],

                // Bewertung
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Meine Bewertung',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            if (_entry.rating != null)
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(
                                    _entry.rating!.overall.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.star_border, color: Colors.amber),
                            Expanded(
                              child: Slider(
                                value: _ratingValue,
                                min: 1,
                                max: 10,
                                divisions: 18,
                                label: _ratingValue.toStringAsFixed(1),
                                onChanged: (v) => setState(() => _ratingValue = v),
                              ),
                            ),
                            const Icon(Icons.star, color: Colors.amber),
                          ],
                        ),
                        Center(
                          child: ElevatedButton(
                            onPressed: _saveRating,
                            child: Text(_entry.rating != null ? 'Bewertung aktualisieren' : 'Bewerten'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Cast
                if (media.mainCast.isNotEmpty) ...[
                  const Text(
                    'Besetzung',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: media.mainCast.length,
                      itemBuilder: (context, index) {
                        final person = media.mainCast[index];
                        return Container(
                          width: 70,
                          margin: const EdgeInsets.only(right: 8),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundImage: person.fullProfileUrl != null
                                    ? NetworkImage(person.fullProfileUrl!)
                                    : null,
                                child: person.fullProfileUrl == null
                                    ? Text(person.name[0])
                                    : null,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                person.name,
                                style: const TextStyle(fontSize: 10),
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Löschen
                Center(
                  child: TextButton.icon(
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text('Entfernen', style: TextStyle(color: Colors.red)),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateStatus(MediaStatus status) {
    setState(() {
      _entry = _entry.copyWith(
        status: status,
        updatedAt: DateTime.now(),
        watchedDate: status == MediaStatus.watched ? DateTime.now() : _entry.watchedDate,
      );
    });
    ref.read(userMediaEntriesProvider(widget.userId).notifier).update(_entry);
  }

  void _saveRating() {
    final rating = MediaRating(overall: _ratingValue);
    setState(() {
      _entry = _entry.copyWith(
        rating: rating,
        updatedAt: DateTime.now(),
      );
    });
    ref.read(userMediaEntriesProvider(widget.userId).notifier).update(_entry);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bewertung gespeichert'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _delete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Entfernen?'),
        content: Text('${_entry.media.title} aus deiner Liste entfernen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Dialog
              Navigator.pop(context); // Sheet
              ref.read(userMediaEntriesProvider(widget.userId).notifier)
                  .delete(_entry.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Entfernen'),
          ),
        ],
      ),
    );
  }
}
