/// Einheitliches Statistik-Widget für alle Datentypen
/// 
/// Verwendet konsistentes Design für alle Widget-Größen

import 'package:flutter/material.dart';
import '../../models/home_widget_model.dart';

/// Einheitliches Widget für Statistik-Daten (Kalorien, Wasser, Schritte, etc.)
class UnifiedStatWidget extends StatelessWidget {
  final HomeWidgetSize size;
  final String title;
  final String value;
  final String? unit;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final double? progress;
  final String? goal;
  final VoidCallback? onTap;
  final List<Widget>? additionalContent;

  const UnifiedStatWidget({
    super.key,
    required this.size,
    required this.title,
    required this.value,
    this.unit,
    this.subtitle,
    required this.icon,
    required this.color,
    this.progress,
    this.goal,
    this.onTap,
    this.additionalContent,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.08),
                color.withOpacity(0.03),
              ],
            ),
          ),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    // Layout basierend auf Größe
    if (size.isSmall) {
      return _build1x1();
    } else if (size == HomeWidgetSize.medium || size == HomeWidgetSize.wideHalf || size == HomeWidgetSize.wide) {
      return _buildHorizontal();
    } else if (size == HomeWidgetSize.tall) {
      return _build1x2();
    } else if (size == HomeWidgetSize.large) {
      return _build2x2();
    } else if (size.isLarge) {
      return _buildLarge();
    }
    return _build1x1();
  }

  /// 1×1: Nur Icon + Titel + Wert (kompakt)
  Widget _build1x1() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon im Kreis
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 6),
          // Titel
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          // Wert
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatValue(value),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
              if (unit != null && unit!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 1, bottom: 1),
                  child: Text(
                    _formatUnit(unit!),
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// 1×2: Vertikal mit Progress
  Widget _build1x2() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Wert
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
              if (unit != null && unit!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 4),
                  child: Text(
                    unit!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
          const Spacer(),
          // Progress
          if (progress != null) ...[
            const SizedBox(height: 8),
            _buildProgressBar(),
          ],
        ],
      ),
    );
  }

  /// Horizontal (2×1, 3×1, 4×1)
  Widget _buildHorizontal() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    if (unit != null && unit!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 2, bottom: 3),
                        child: Text(
                          unit!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Progress (circular für horizontal)
          if (progress != null)
            _buildCircularProgress(),
        ],
      ),
    );
  }

  /// 2×2: Statistiken + Details
  Widget _build2x2() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              if (progress != null)
                Text(
                  '${(progress! * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
            ],
          ),
          const Spacer(),
          // Großer Wert
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
              if (unit != null && unit!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 6),
                  child: Text(
                    unit!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
          const Spacer(),
          // Progress
          if (progress != null) _buildProgressBar(),
          // Additional Content
          if (additionalContent != null) ...[
            const SizedBox(height: 8),
            ...additionalContent!,
          ],
        ],
      ),
    );
  }

  /// Große Widgets (2×3, 3×2, 3×3, 4×2)
  Widget _buildLarge() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),
              if (progress != null)
                _buildCircularProgress(size: 50),
            ],
          ),
          const SizedBox(height: 16),
          // Großer Wert
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
              if (unit != null && unit!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    unit!,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress
          if (progress != null) _buildProgressBar(height: 8),
          // Additional Content
          if (additionalContent != null) ...[
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: additionalContent!,
                ),
              ),
            ),
          ] else
            const Spacer(),
        ],
      ),
    );
  }

  Widget _buildProgressBar({double height = 6}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: height,
        backgroundColor: color.withOpacity(0.15),
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }

  Widget _buildCircularProgress({double size = 40}) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 4,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation(color),
          ),
          Text(
            '${(progress! * 100).toInt()}%',
            style: TextStyle(
              fontSize: size / 4,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(String val) {
    // Kürze große Zahlen
    final num = int.tryParse(val);
    if (num != null && num >= 10000) {
      return '${(num / 1000).toStringAsFixed(1)}k';
    }
    return val;
  }

  String _formatUnit(String u) {
    // Kürze Einheiten für kleine Widgets
    if (u == 'kcal') return 'k';
    if (u.length > 3) return u.substring(0, 2);
    return u;
  }
}
