/// Books Screen - Meine Bücher mit Leseliste, Gelesen, Leseziele
/// Features: ISBN Scanner, Google Books Suche, Bewertungen, Leseziele

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../models/book_model.dart';
import '../models/micro_widget_model.dart';
import '../models/timer_widget_model.dart';
import '../services/google_books_service.dart';
import 'book_search_screen.dart';
import 'book_detail_screen.dart';
import 'barcode_scanner_screen.dart';
import 'timer_widget_screen.dart';
import 'package:uuid/uuid.dart';

class BooksScreen extends ConsumerStatefulWidget {
  const BooksScreen({super.key});

  @override
  ConsumerState<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends ConsumerState<BooksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _gridSize = 3;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user != null) {
      await ref.read(bookNotifierProvider.notifier).load(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final books = ref.watch(bookNotifierProvider);
    final tokens = ref.watch(designTokensProvider);
    
    // Leseliste = wantToRead + reading
    final readingList = books.where((b) => 
      b.status == BookStatus.wantToRead || b.status == BookStatus.reading
    ).toList();
    final finished = books.where((b) => b.status == BookStatus.finished).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meine Bücher'),
        actions: [
          // Barcode Scanner
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Barcode scannen',
            onPressed: _scanBarcode,
          ),
          // Grid-Größe
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
          // Buch hinzufügen
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Buch hinzufügen',
            onPressed: _navigateToSearch,
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
              icon: Icon(Icons.flag_outlined),
              text: 'Leseziele',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReadingListTab(readingList, tokens),
          _buildFinishedBooksTab(finished, tokens),
          _buildGoalsTab(tokens),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TimerWidgetScreen()),
        ),
        icon: const Icon(Icons.timer),
        label: const Text('Timer'),
        backgroundColor: tokens.primary,
      ),
    );
  }

  // ============================================
  // BARCODE SCANNER
  // ============================================

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const BarcodeScannerScreen(),
      ),
    );

    if (barcode != null && mounted) {
      _searchByIsbn(barcode);
    }
  }

  Future<void> _searchByIsbn(String isbn) async {
    final tokens = ref.read(designTokensProvider);
    
    // Zeige Ladeindikator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text('Suche Buch mit ISBN: $isbn'),
          ],
        ),
      ),
    );

    try {
      final googleBooksService = ref.read(googleBooksServiceProvider);
      final result = await googleBooksService.searchByIsbn(isbn);

      if (mounted) Navigator.pop(context); // Close loading dialog

      if (result != null && mounted) {
        // Zeige gefundenes Buch
        _showFoundBookDialog(result, tokens);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kein Buch mit ISBN $isbn gefunden'),
            action: SnackBarAction(
              label: 'Manuell suchen',
              onPressed: _navigateToSearch,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler bei der Suche: $e')),
        );
      }
    }
  }

  void _showFoundBookDialog(GoogleBookResult book, DesignTokens tokens) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buch gefunden'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (book.highResCoverUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  book.highResCoverUrl!,
                  height: 150,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    height: 150,
                    width: 100,
                    color: tokens.surface,
                    child: Icon(Icons.menu_book, size: 50, color: tokens.textSecondary),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              book.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text(
              book.authorsString,
              style: TextStyle(color: tokens.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _addBookFromGoogleResult(book);
            },
            icon: const Icon(Icons.add),
            label: const Text('Zur Leseliste'),
          ),
        ],
      ),
    );
  }

  Future<void> _addBookFromGoogleResult(GoogleBookResult googleBook) async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    final book = BookModel(
      id: const Uuid().v4(),
      oderId: user.id,
      title: googleBook.title,
      author: googleBook.authorsString,
      coverUrl: googleBook.highResCoverUrl ?? googleBook.bestCoverUrl,
      googleBooksId: googleBook.id,
      isbn: googleBook.isbn13 ?? googleBook.isbn10,
      status: BookStatus.wantToRead,
      addedAt: DateTime.now(),
      pageCount: googleBook.pageCount,
    );

    await ref.read(bookNotifierProvider.notifier).addBook(book);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('„${book.title}" zur Leseliste hinzugefügt')),
      );
    }
  }

  // ============================================
  // TAB 1: LESELISTE
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
                Expanded(child: _buildBookCover(book, tokens)),
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
            // Checkmark Button
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
                    child: const Icon(Icons.check, color: Colors.white, size: 18),
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
              _tabController.animateTo(1);
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
  // TAB 2: GELESEN
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
            Expanded(child: _buildBookCover(book, tokens)),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Text(
                book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
            if (book.rating != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Row(
                  children: List.generate(5, (index) {
                    final starValue = (index + 1) * 2;
                    final rating = book.rating!.overall;
                    if (rating >= starValue) {
                      return Icon(Icons.star, size: 12, color: Colors.amber);
                    } else if (rating >= starValue - 1) {
                      return Icon(Icons.star_half, size: 12, color: Colors.amber);
                    } else {
                      return Icon(Icons.star_border, size: 12, color: Colors.amber);
                    }
                  }),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Text(
                  'Noch nicht bewertet',
                  style: TextStyle(fontSize: 10, color: tokens.textSecondary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // TAB 3: LESEZIELE (MicroWidgets + Zeitziele)
  // ============================================

  Widget _buildGoalsTab(DesignTokens tokens) {
    final microWidgets = ref.watch(microWidgetsProvider);
    final readingWidgets = microWidgets.where((w) => w.type == MicroWidgetType.reading).toList();
    final timerSessions = ref.watch(timerSessionsProvider);
    
    // Berechne Statistiken
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDay = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final monthStart = DateTime(now.year, now.month, 1);
    
    final weekSessions = timerSessions.where((s) =>
        s.activityType == TimerActivityType.reading &&
        s.startTime.isAfter(weekStartDay));
    final monthSessions = timerSessions.where((s) =>
        s.activityType == TimerActivityType.reading &&
        s.startTime.isAfter(monthStart));
    
    final weekMinutes = weekSessions.fold(0, (sum, s) => sum + s.durationSeconds) ~/ 60;
    final monthMinutes = monthSessions.fold(0, (sum, s) => sum + s.durationSeconds) ~/ 60;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lesezeit-Statistiken
          _buildTimeStatsCard(weekMinutes, monthMinutes, tokens),
          
          const SizedBox(height: 24),
          
          // MikroWidgets Überschrift
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lese-Gewohnheiten',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: tokens.textPrimary,
                ),
              ),
              IconButton(
                icon: Icon(Icons.add_circle, color: tokens.primary),
                onPressed: () => _showAddMicroWidgetDialog(tokens),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // MikroWidgets Liste
          if (readingWidgets.isEmpty)
            _buildEmptyMicroWidgetsCard(tokens)
          else
            ...readingWidgets.map((widget) => _buildMicroWidgetCard(widget, tokens)),
          
          const SizedBox(height: 24),
          
          // Schnellzugang zum Timer
          _buildTimerQuickAccess(tokens),
        ],
      ),
    );
  }

  Widget _buildTimeStatsCard(int weekMinutes, int monthMinutes, DesignTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tokens.primary.withOpacity(0.1),
            tokens.primary.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book, color: tokens.primary, size: 28),
              const SizedBox(width: 12),
              Text(
                'Lesezeit',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: tokens.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Diese Woche',
                  _formatMinutes(weekMinutes),
                  Icons.calendar_today,
                  tokens,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: tokens.divider,
              ),
              Expanded(
                child: _buildStatItem(
                  'Dieser Monat',
                  _formatMinutes(monthMinutes),
                  Icons.calendar_month,
                  tokens,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, DesignTokens tokens) {
    return Column(
      children: [
        Icon(icon, color: tokens.textSecondary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: tokens.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: tokens.textSecondary,
          ),
        ),
      ],
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    }
    return '${minutes}m';
  }

  Widget _buildEmptyMicroWidgetsCard(DesignTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.divider),
      ),
      child: Column(
        children: [
          Icon(Icons.flag_outlined, size: 48, color: tokens.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(
            'Keine Lese-Gewohnheiten',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Erstelle z.B. "4x pro Woche lesen"',
            style: TextStyle(color: tokens.textSecondary),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _showAddMicroWidgetDialog(tokens),
            icon: const Icon(Icons.add),
            label: const Text('Gewohnheit erstellen'),
          ),
        ],
      ),
    );
  }

  Widget _buildMicroWidgetCard(MicroWidgetModel widget, DesignTokens tokens) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.divider),
      ),
      child: Row(
        children: [
          // Abhak-Button
          GestureDetector(
            onTap: widget.isCompletedToday || widget.isPeriodGoalReached
                ? null
                : () => ref.read(microWidgetsProvider.notifier).checkOff(widget.id),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isCompletedToday
                    ? tokens.success.withOpacity(0.2)
                    : tokens.primary.withOpacity(0.1),
                border: Border.all(
                  color: widget.isCompletedToday ? tokens.success : tokens.primary,
                  width: 2,
                ),
              ),
              child: widget.isCompletedToday
                  ? Icon(Icons.check, color: tokens.success)
                  : Icon(Icons.add, color: tokens.primary),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      widget.progressText,
                      style: TextStyle(color: tokens.textSecondary),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: widget.progressPercent,
                          backgroundColor: tokens.divider,
                          valueColor: AlwaysStoppedAnimation(
                            widget.isPeriodGoalReached ? tokens.success : tokens.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Löschen
          IconButton(
            icon: Icon(Icons.delete_outline, color: tokens.textSecondary),
            onPressed: () => _deleteMicroWidget(widget.id),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerQuickAccess(DesignTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tokens.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.timer, color: tokens.primary, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lese-Timer',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: tokens.textPrimary,
                  ),
                ),
                Text(
                  'Starte eine Lesesession',
                  style: TextStyle(color: tokens.textSecondary),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TimerWidgetScreen()),
            ),
            child: const Text('Starten'),
          ),
        ],
      ),
    );
  }

  void _showAddMicroWidgetDialog(DesignTokens tokens) {
    int targetCount = 4;
    GoalFrequency frequency = GoalFrequency.weekly;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Neue Lese-Gewohnheit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Wie oft möchtest du lesen?', style: TextStyle(color: tokens.textSecondary)),
              const SizedBox(height: 16),
              
              // Anzahl
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: targetCount > 1 ? () => setDialogState(() => targetCount--) : null,
                  ),
                  Text(
                    '$targetCount',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: targetCount < 14 ? () => setDialogState(() => targetCount++) : null,
                  ),
                  const Text(' mal'),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Häufigkeit
              SegmentedButton<GoalFrequency>(
                segments: const [
                  ButtonSegment(value: GoalFrequency.daily, label: Text('Täglich')),
                  ButtonSegment(value: GoalFrequency.weekly, label: Text('Wöchentlich')),
                ],
                selected: {frequency},
                onSelectionChanged: (selected) {
                  setDialogState(() => frequency = selected.first);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () {
                _createMicroWidget(targetCount, frequency);
                Navigator.pop(context);
              },
              child: const Text('Erstellen'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createMicroWidget(int targetCount, GoalFrequency frequency) async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    final frequencyText = frequency == GoalFrequency.daily ? 'täglich' : 'pro Woche';
    
    final widget = MicroWidgetModel(
      id: const Uuid().v4(),
      userId: user.id,
      type: MicroWidgetType.reading,
      title: '$targetCount× Lesen $frequencyText',
      targetCount: targetCount,
      frequency: frequency,
      periodStart: DateTime.now(),
      createdAt: DateTime.now(),
    );

    await ref.read(microWidgetsProvider.notifier).addWidget(widget);
  }

  Future<void> _deleteMicroWidget(String widgetId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gewohnheit löschen?'),
        content: const Text('Diese Aktion kann nicht rückgängig gemacht werden.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(microWidgetsProvider.notifier).deleteWidget(widgetId);
    }
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  Widget _buildBookCover(BookModel book, DesignTokens tokens) {
    if (book.coverUrl != null && book.coverUrl!.isNotEmpty) {
      return Image.network(
        book.coverUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: tokens.surface,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _buildDefaultCover(book, tokens),
      );
    }
    return _buildDefaultCover(book, tokens);
  }

  Widget _buildDefaultCover(BookModel book, DesignTokens tokens) {
    return Container(
      color: tokens.primary.withOpacity(0.1),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 32, color: tokens.primary),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                book.title,
                maxLines: 2,
                textAlign: TextAlign.center,
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
            Icon(icon, size: 80, color: tokens.textSecondary.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 18, color: tokens.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.add),
              label: Text(buttonText),
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
    );
  }

  void _navigateToDetail(BookModel book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
    );
  }
}
