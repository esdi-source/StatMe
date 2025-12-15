/// Books Screen - Library management with reading goals
/// Features: Want-to-read list, finished books with ratings, reading timer

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../models/book_model.dart';
import '../services/google_books_service.dart';
import 'book_search_screen.dart';
import 'book_detail_screen.dart';

class BooksScreen extends ConsumerStatefulWidget {
  const BooksScreen({super.key});

  @override
  ConsumerState<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends ConsumerState<BooksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _gridSize = 3; // Default: 3 Bücher nebeneinander
  
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
    
    final wantToRead = books.where((b) => b.status == BookStatus.wantToRead).toList();
    final reading = books.where((b) => b.status == BookStatus.reading).toList();
    final finished = books.where((b) => b.status == BookStatus.finished).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meine Bücher'),
        actions: [
          // Grid Size Toggle
          PopupMenuButton<int>(
            icon: const Icon(Icons.grid_view),
            tooltip: 'Anzeigegröße',
            onSelected: (size) => setState(() => _gridSize = size),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 2, child: Text('Groß (2 pro Reihe)')),
              const PopupMenuItem(value: 3, child: Text('Mittel (3 pro Reihe)')),
              const PopupMenuItem(value: 4, child: Text('Klein (4 pro Reihe)')),
              const PopupMenuItem(value: 5, child: Text('Sehr klein (5 pro Reihe)')),
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
              text: 'Leseliste (${wantToRead.length})',
            ),
            Tab(
              icon: const Icon(Icons.auto_stories),
              text: 'Lese ich (${reading.length})',
            ),
            Tab(
              icon: const Icon(Icons.check_circle_outline),
              text: 'Gelesen (${finished.length})',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Reading Goal & Timer Card
          _buildReadingGoalCard(readingGoal),
          
          // Book Lists
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBookGrid(wantToRead, 'Keine Bücher auf der Leseliste'),
                _buildBookGrid(reading, 'Du liest gerade keine Bücher'),
                _buildFinishedBooksGrid(finished),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingGoalCard(ReadingGoalModel? goal) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wochenziel: ${goal?.formattedGoal ?? '4h'}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gelesen: ${goal?.formattedRead ?? '0min'} (${((goal?.progressPercent ?? 0) * 100).toStringAsFixed(0)}%)',
                        style: TextStyle(color: Colors.grey.shade600),
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
            const SizedBox(height: 12),
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: goal?.progressPercent ?? 0,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
              ),
            ),
            const SizedBox(height: 16),
            // Timer Section
            _buildTimerSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerSection() {
    final hours = _timerSeconds ~/ 3600;
    final minutes = (_timerSeconds % 3600) ~/ 60;
    final seconds = _timerSeconds % 60;
    final timeString = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isTimerRunning 
            ? Theme.of(context).colorScheme.primaryContainer 
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Timer Display
          Text(
            timeString,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: _isTimerRunning 
                  ? Theme.of(context).colorScheme.primary 
                  : Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 20),
          // Start/Stop Button
          ElevatedButton.icon(
            onPressed: _toggleTimer,
            icon: Icon(_isTimerRunning ? Icons.stop : Icons.play_arrow),
            label: Text(_isTimerRunning ? 'Stoppen' : 'Lesen starten'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isTimerRunning ? Colors.red : null,
              foregroundColor: _isTimerRunning ? Colors.white : null,
            ),
          ),
          if (_timerSeconds > 0 && !_isTimerRunning) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Zeit speichern',
              onPressed: _saveReadingTime,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Zurücksetzen',
              onPressed: () => setState(() => _timerSeconds = 0),
            ),
          ],
        ],
      ),
    );
  }

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
        SnackBar(content: Text('$minutes Minuten Lesezeit gespeichert!')),
      );
    }
  }

  Widget _buildBookGrid(List<BookModel> books, String emptyMessage) {
    if (books.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(emptyMessage, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _navigateToSearch,
              icon: const Icon(Icons.add),
              label: const Text('Buch hinzufügen'),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _gridSize,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) => _buildBookCard(books[index]),
    );
  }

  Widget _buildFinishedBooksGrid(List<BookModel> books) {
    if (books.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Noch keine Bücher gelesen', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _gridSize,
        childAspectRatio: 0.55, // Etwas mehr Platz für Bewertung
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) => _buildFinishedBookCard(books[index]),
    );
  }

  Widget _buildBookCard(BookModel book) {
    return GestureDetector(
      onTap: () => _navigateToDetail(book),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover
            Expanded(
              child: book.coverUrl != null
                  ? Image.network(
                      book.coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderCover(book),
                    )
                  : _buildPlaceholderCover(book),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  if (book.author != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      book.author!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinishedBookCard(BookModel book) {
    return GestureDetector(
      onTap: () => _navigateToDetail(book),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover
            Expanded(
              child: book.coverUrl != null
                  ? Image.network(
                      book.coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderCover(book),
                    )
                  : _buildPlaceholderCover(book),
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
                  // Rating Stars
                  if (book.rating != null)
                    Row(
                      children: [
                        ...List.generate(5, (i) {
                          final starValue = (i + 1) * 2;
                          final rating = book.rating!.overall;
                          if (rating >= starValue) {
                            return const Icon(Icons.star, size: 14, color: Colors.amber);
                          } else if (rating >= starValue - 1) {
                            return const Icon(Icons.star_half, size: 14, color: Colors.amber);
                          } else {
                            return Icon(Icons.star_border, size: 14, color: Colors.grey.shade400);
                          }
                        }),
                        const SizedBox(width: 4),
                        Text(
                          '${book.rating!.overall}/10',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderCover(BookModel book) {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 32, color: Colors.grey.shade400),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                book.title,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setDialogState) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: hours > 1 
                        ? () => setDialogState(() => hours--) 
                        : null,
                  ),
                  Text(
                    '$hours Stunden',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
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
                // Berechne Wochenstart (Montag)
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
