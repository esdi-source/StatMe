/// Books Screen - Simplified Library Management
/// Features: Reading list with checkoff, finished books with ratings, reading timer

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../models/book_model.dart';
import 'book_search_screen.dart';
import 'book_detail_screen.dart';

class BooksScreen extends ConsumerStatefulWidget {
  const BooksScreen({super.key});

  @override
  ConsumerState<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends ConsumerState<BooksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _gridSize = 3;
  
  // Timer state
  Timer? _readingTimer;
  int _timerSeconds = 0;
  bool _isTimerRunning = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _readingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user != null) {
      await ref.read(bookNotifierProvider.notifier).load(user.id);
      await ref.read(readingGoalNotifierProvider.notifier).load(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final books = ref.watch(bookNotifierProvider);
    final readingGoal = ref.watch(readingGoalNotifierProvider);
    final tokens = ref.watch(designTokensProvider);
    
    // Leseliste = wantToRead + reading (vereinfacht)
    final readingList = books.where((b) => 
      b.status == BookStatus.wantToRead || b.status == BookStatus.reading
    ).toList();
    final finished = books.where((b) => b.status == BookStatus.finished).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meine Bücher'),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.grid_view),
            tooltip: 'Anzeigegröße',
            onSelected: (size) => setState(() => _gridSize = size),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 2, child: Text('Groß (2 pro Reihe)')),
              const PopupMenuItem(value: 3, child: Text('Mittel (3 pro Reihe)')),
              const PopupMenuItem(value: 4, child: Text('Klein (4 pro Reihe)')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Buch hinzufügen',
            onPressed: () => _navigateToSearch(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.bookmark_border),
              text: 'Leseliste (${readingList.length})',
            ),
            Tab(
              icon: const Icon(Icons.check_circle_outline),
              text: 'Gelesen (${finished.length})',
            ),
            const Tab(
              icon: Icon(Icons.timer_outlined),
              text: 'Timer',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReadingListTab(readingList, tokens),
          _buildFinishedBooksTab(finished, tokens),
          _buildTimerTab(readingGoal, tokens),
        ],
      ),
    );
  }

  // ============================================
  // TAB 1: LESELISTE (mit Abhaken)
  // ============================================
  
  Widget _buildReadingListTab(List<BookModel> books, DesignTokens tokens) {
    if (books.isEmpty) {
      return _buildEmptyState(
        icon: Icons.bookmark_add,
        message: 'Deine Leseliste ist leer',
        buttonText: 'Buch hinzufügen',
        onPressed: _navigateToSearch,
        tokens: tokens,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _gridSize,
        childAspectRatio: 0.58,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) => _buildReadingListCard(books[index], tokens),
    );
  }

  Widget _buildReadingListCard(BookModel book, DesignTokens tokens) {
    return GestureDetector(
      onTap: () => _navigateToDetail(book),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cover
                Expanded(
                  child: _buildBookCover(book),
                ),
                // Title
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                  child: Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                if (book.author != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: Text(
                      book.author!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, color: tokens.textSecondary),
                    ),
                  ),
              ],
            ),
            // Checkmark Button (oben rechts)
            Positioned(
              top: 4,
              right: 4,
              child: Material(
                color: tokens.success,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _markAsFinished(book),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAsFinished(BookModel book) async {
    final updatedBook = book.copyWith(
      status: BookStatus.finished,
      finishedAt: DateTime.now(),
    );
    await ref.read(bookNotifierProvider.notifier).updateBook(updatedBook);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('„${book.title}" als gelesen markiert'),
          action: SnackBarAction(
            label: 'Bewerten',
            onPressed: () {
              _tabController.animateTo(1); // Wechsel zum Gelesen-Tab
              Future.delayed(const Duration(milliseconds: 300), () {
                _navigateToDetail(updatedBook);
              });
            },
          ),
        ),
      );
    }
  }

  // ============================================
  // TAB 2: GELESEN (mit Bewertung)
  // ============================================

  Widget _buildFinishedBooksTab(List<BookModel> books, DesignTokens tokens) {
    if (books.isEmpty) {
      return _buildEmptyState(
        icon: Icons.menu_book,
        message: 'Du hast noch keine Bücher beendet',
        buttonText: 'Leseliste ansehen',
        onPressed: () => _tabController.animateTo(0),
        tokens: tokens,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _gridSize,
        childAspectRatio: 0.52,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) => _buildFinishedBookCard(books[index], tokens),
    );
  }

  Widget _buildFinishedBookCard(BookModel book, DesignTokens tokens) {
    return GestureDetector(
      onTap: () => _navigateToDetail(book),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover
            Expanded(
              child: _buildBookCover(book),
            ),
            // Title & Rating
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  // 5-Sterne Rating (kompakt)
                  if (book.rating != null)
                    _buildCompactRating(book.rating!.overall, tokens)
                  else
                    Text(
                      'Tippen zum Bewerten',
                      style: TextStyle(
                        fontSize: 9,
                        color: tokens.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactRating(int rating, DesignTokens tokens) {
    // Konvertiere 1-10 zu 1-5 Sternen
    final stars = (rating / 2).round().clamp(1, 5);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (i) {
          return Icon(
            i < stars ? Icons.star : Icons.star_border,
            size: 14,
            color: Colors.amber,
          );
        }),
      ],
    );
  }

  // ============================================
  // TAB 3: TIMER
  // ============================================

  Widget _buildTimerTab(ReadingGoalModel? goal, DesignTokens tokens) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Wochenziel Card
          _buildWeeklyGoalCard(goal, tokens),
          const SizedBox(height: 24),
          // Timer Card
          _buildTimerCard(tokens),
          const SizedBox(height: 24),
          // Letzte Sessions (wenn vorhanden)
          if (goal?.sessions.isNotEmpty == true)
            _buildRecentSessionsCard(goal!, tokens),
        ],
      ),
    );
  }

  Widget _buildWeeklyGoalCard(ReadingGoalModel? goal, DesignTokens tokens) {
    final progress = goal?.progressPercent ?? 0;
    final goalText = goal?.formattedGoal ?? '4h';
    final readText = goal?.formattedRead ?? '0 min';
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.flag, color: tokens.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Wochenziel',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Text(
                        '$readText von $goalText',
                        style: TextStyle(color: tokens.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditGoalDialog(goal),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(tokens.radiusSmall),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: tokens.divider,
                color: progress >= 1.0 ? tokens.success : tokens.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).toStringAsFixed(0)}% erreicht',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: progress >= 1.0 ? tokens.success : tokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerCard(DesignTokens tokens) {
    final hours = _timerSeconds ~/ 3600;
    final minutes = (_timerSeconds % 3600) ~/ 60;
    final seconds = _timerSeconds % 60;
    final timeString = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Timer Display
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
              decoration: BoxDecoration(
                color: _isTimerRunning 
                    ? tokens.primary.withOpacity(0.1) 
                    : tokens.background,
                borderRadius: BorderRadius.circular(tokens.radiusMedium),
              ),
              child: Text(
                timeString,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: _isTimerRunning ? tokens.primary : tokens.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Start/Stop Button
                ElevatedButton.icon(
                  onPressed: _toggleTimer,
                  icon: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow),
                  label: Text(_isTimerRunning ? 'Pause' : 'Start'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    backgroundColor: _isTimerRunning ? tokens.warning : tokens.primary,
                  ),
                ),
                if (_timerSeconds > 0) ...[
                  const SizedBox(width: 12),
                  // Save Button
                  ElevatedButton.icon(
                    onPressed: _isTimerRunning ? null : _saveReadingTime,
                    icon: const Icon(Icons.save),
                    label: const Text('Speichern'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      backgroundColor: tokens.success,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Reset Button
                  IconButton(
                    onPressed: _isTimerRunning ? null : () => setState(() => _timerSeconds = 0),
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Zurücksetzen',
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSessionsCard(ReadingGoalModel goal, DesignTokens tokens) {
    final recentSessions = goal.sessions.take(5).toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Letzte Sitzungen',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...recentSessions.map((session) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: tokens.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    '${session.date.day}.${session.date.month}.${session.date.year}',
                    style: TextStyle(color: tokens.textSecondary),
                  ),
                  const Spacer(),
                  Text(
                    '${session.durationMinutes} min',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  // ============================================
  // HELPER WIDGETS
  // ============================================

  Widget _buildBookCover(BookModel book) {
    if (book.coverUrl != null && book.coverUrl!.isNotEmpty) {
      // Verbesserte Cover URL für höhere Auflösung
      String coverUrl = book.coverUrl!;
      // HTTP zu HTTPS konvertieren
      coverUrl = coverUrl.replaceFirst('http://', 'https://');
      // Höhere Auflösung anfordern wenn möglich
      if (coverUrl.contains('zoom=')) {
        coverUrl = coverUrl.replaceFirst(RegExp(r'zoom=\d'), 'zoom=2');
      }
      
      return Image.network(
        coverUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
            ),
          );
        },
        errorBuilder: (_, __, ___) => _buildPlaceholderCover(book),
      );
    }
    return _buildPlaceholderCover(book);
  }

  Widget _buildPlaceholderCover(BookModel book) {
    final tokens = ref.read(designTokensProvider);
    return Container(
      color: tokens.primary.withOpacity(0.1),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 28, color: tokens.primary.withOpacity(0.5)),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                book.title,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 9, color: tokens.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String buttonText,
    required VoidCallback onPressed,
    required DesignTokens tokens,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: tokens.textDisabled),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(color: tokens.textSecondary, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.add),
              label: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // TIMER LOGIC
  // ============================================

  void _toggleTimer() {
    setState(() {
      if (_isTimerRunning) {
        _readingTimer?.cancel();
        _isTimerRunning = false;
      } else {
        _isTimerRunning = true;
        _readingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() => _timerSeconds++);
        });
      }
    });
  }

  Future<void> _saveReadingTime() async {
    if (_timerSeconds < 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mindestens 1 Minute muss gelesen werden')),
      );
      return;
    }

    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    final minutes = _timerSeconds ~/ 60;
    
    await ref.read(readingGoalNotifierProvider.notifier).addReadingSession(
      user.id,
      ReadingSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        durationMinutes: minutes,
      ),
    );

    setState(() => _timerSeconds = 0);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$minutes Minuten Lesezeit gespeichert! 📚')),
      );
    }
  }

  // ============================================
  // NAVIGATION
  // ============================================

  void _navigateToSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BookSearchScreen()),
    ).then((_) => _loadData());
  }

  void _navigateToDetail(BookModel book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
    ).then((_) => _loadData());
  }

  void _showEditGoalDialog(ReadingGoalModel? currentGoal) {
    int hours = (currentGoal?.weeklyGoalMinutes ?? 240) ~/ 60;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wochenziel festlegen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Wie viele Stunden möchtest du pro Woche lesen?'),
            const SizedBox(height: 20),
            StatefulBuilder(
              builder: (context, setDialogState) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filled(
                    icon: const Icon(Icons.remove),
                    onPressed: hours > 1 
                        ? () => setDialogState(() => hours--) 
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      '$hours h',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton.filled(
                    icon: const Icon(Icons.add),
                    onPressed: () => setDialogState(() => hours++),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              final user = ref.read(authNotifierProvider).valueOrNull;
              if (user != null) {
                final now = DateTime.now();
                final weekStart = now.subtract(Duration(days: now.weekday - 1));
                
                final goal = ReadingGoalModel(
                  id: currentGoal?.id ?? user.id,
                  oderId: user.id,
                  weeklyGoalMinutes: hours * 60,
                  readMinutesThisWeek: currentGoal?.readMinutesThisWeek ?? 0,
                  weekStartDate: DateTime(weekStart.year, weekStart.month, weekStart.day),
                  sessions: currentGoal?.sessions ?? [],
                );
                
                await ref.read(readingGoalNotifierProvider.notifier).updateGoal(goal);
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }
}
