/// Einheitliches Widget-Design System
/// 
/// Dieses Modul definiert das Basis-Layout für alle Dashboard-Widgets.
/// Größenabhängige Designs für konsistente Darstellung.

import 'package:flutter/material.dart';
import '../../models/home_widget_model.dart';

/// Standard-Farbe für alle Widgets (neutral, einheitlich)
const Color kDefaultWidgetColor = Color(0xFF6366F1); // Indigo
const Color kDefaultWidgetBackground = Color(0xFFF8FAFC); // Sehr helles Grau

/// Widget-Layout Konfiguration basierend auf Größe
class WidgetLayoutConfig {
  final double iconSize;
  final double titleSize;
  final double valueSize;
  final double subtitleSize;
  final double padding;
  final bool showIcon;
  final bool showTitle;
  final bool showValue;
  final bool showSubtitle;
  final bool showProgress;
  final bool showDetails;
  final bool showChart;
  final bool showList;
  final int maxListItems;
  final Axis layoutAxis; // Horizontal oder Vertikal

  const WidgetLayoutConfig({
    required this.iconSize,
    required this.titleSize,
    required this.valueSize,
    required this.subtitleSize,
    required this.padding,
    required this.showIcon,
    required this.showTitle,
    required this.showValue,
    required this.showSubtitle,
    required this.showProgress,
    required this.showDetails,
    required this.showChart,
    required this.showList,
    required this.maxListItems,
    required this.layoutAxis,
  });

  /// Generiert Layout-Konfiguration basierend auf Widget-Größe
  factory WidgetLayoutConfig.forSize(HomeWidgetSize size) {
    switch (size) {
      // 1×1: Nur Icon + kurzer Name
      case HomeWidgetSize.small:
        return const WidgetLayoutConfig(
          iconSize: 28,
          titleSize: 11,
          valueSize: 16,
          subtitleSize: 9,
          padding: 10,
          showIcon: true,
          showTitle: true,
          showValue: true,
          showSubtitle: false,
          showProgress: false,
          showDetails: false,
          showChart: false,
          showList: false,
          maxListItems: 0,
          layoutAxis: Axis.vertical,
        );
      
      // 1×2: Icon + Name + Kurzinfo
      case HomeWidgetSize.tall:
        return const WidgetLayoutConfig(
          iconSize: 28,
          titleSize: 12,
          valueSize: 22,
          subtitleSize: 10,
          padding: 12,
          showIcon: true,
          showTitle: true,
          showValue: true,
          showSubtitle: true,
          showProgress: true,
          showDetails: false,
          showChart: false,
          showList: false,
          maxListItems: 0,
          layoutAxis: Axis.vertical,
        );
      
      // 1×3: Icon + Name + Statistiken
      case HomeWidgetSize.tallMedium:
        return const WidgetLayoutConfig(
          iconSize: 28,
          titleSize: 12,
          valueSize: 24,
          subtitleSize: 10,
          padding: 12,
          showIcon: true,
          showTitle: true,
          showValue: true,
          showSubtitle: true,
          showProgress: true,
          showDetails: true,
          showChart: false,
          showList: true,
          maxListItems: 3,
          layoutAxis: Axis.vertical,
        );
      
      // 2×1: Icon + Name + wichtige Info
      case HomeWidgetSize.medium:
        return const WidgetLayoutConfig(
          iconSize: 24,
          titleSize: 12,
          valueSize: 20,
          subtitleSize: 10,
          padding: 12,
          showIcon: true,
          showTitle: true,
          showValue: true,
          showSubtitle: true,
          showProgress: true,
          showDetails: false,
          showChart: false,
          showList: false,
          maxListItems: 0,
          layoutAxis: Axis.horizontal,
        );
      
      // 2×2: Statistiken + Fortschritte
      case HomeWidgetSize.large:
        return const WidgetLayoutConfig(
          iconSize: 28,
          titleSize: 14,
          valueSize: 28,
          subtitleSize: 11,
          padding: 14,
          showIcon: true,
          showTitle: true,
          showValue: true,
          showSubtitle: true,
          showProgress: true,
          showDetails: true,
          showChart: false,
          showList: true,
          maxListItems: 3,
          layoutAxis: Axis.vertical,
        );
      
      // 2×3: Detaillierte Statistiken
      case HomeWidgetSize.largeTall:
        return const WidgetLayoutConfig(
          iconSize: 28,
          titleSize: 14,
          valueSize: 28,
          subtitleSize: 11,
          padding: 14,
          showIcon: true,
          showTitle: true,
          showValue: true,
          showSubtitle: true,
          showProgress: true,
          showDetails: true,
          showChart: true,
          showList: true,
          maxListItems: 5,
          layoutAxis: Axis.vertical,
        );
      
      // 3×1: Breit mit Infos
      case HomeWidgetSize.wideHalf:
        return const WidgetLayoutConfig(
          iconSize: 24,
          titleSize: 13,
          valueSize: 22,
          subtitleSize: 11,
          padding: 14,
          showIcon: true,
          showTitle: true,
          showValue: true,
          showSubtitle: true,
          showProgress: true,
          showDetails: true,
          showChart: false,
          showList: false,
          maxListItems: 0,
          layoutAxis: Axis.horizontal,
        );
      
      // 3×2: Extra groß
      case HomeWidgetSize.extraLarge:
        return const WidgetLayoutConfig(
          iconSize: 32,
          titleSize: 16,
          valueSize: 32,
          subtitleSize: 12,
          padding: 16,
          showIcon: true,
          showTitle: true,
          showValue: true,
          showSubtitle: true,
          showProgress: true,
          showDetails: true,
          showChart: true,
          showList: true,
          maxListItems: 4,
          layoutAxis: Axis.vertical,
        );
      
      // 3×3: Großes Dashboard-Widget
      case HomeWidgetSize.full:
        return const WidgetLayoutConfig(
          iconSize: 32,
          titleSize: 18,
          valueSize: 36,
          subtitleSize: 13,
          padding: 16,
          showIcon: true,
          showTitle: true,
          showValue: true,
          showSubtitle: true,
          showProgress: true,
          showDetails: true,
          showChart: true,
          showList: true,
          maxListItems: 6,
          layoutAxis: Axis.vertical,
        );
      
      // 4×1: Volle Breite
      case HomeWidgetSize.wide:
        return const WidgetLayoutConfig(
          iconSize: 24,
          titleSize: 14,
          valueSize: 22,
          subtitleSize: 11,
          padding: 14,
          showIcon: true,
          showTitle: true,
          showValue: true,
          showSubtitle: true,
          showProgress: true,
          showDetails: true,
          showChart: false,
          showList: false,
          maxListItems: 0,
          layoutAxis: Axis.horizontal,
        );
      
      // 4×2: Volle Breite hoch
      case HomeWidgetSize.fullWide:
        return const WidgetLayoutConfig(
          iconSize: 32,
          titleSize: 16,
          valueSize: 32,
          subtitleSize: 12,
          padding: 16,
          showIcon: true,
          showTitle: true,
          showValue: true,
          showSubtitle: true,
          showProgress: true,
          showDetails: true,
          showChart: true,
          showList: true,
          maxListItems: 5,
          layoutAxis: Axis.horizontal,
        );
    }
  }
}

/// Basis-Widget Wrapper für einheitliches Design
class UnifiedWidgetBase extends StatelessWidget {
  final HomeWidgetSize size;
  final Color? accentColor;
  final IconData icon;
  final String title;
  final String? value;
  final String? unit;
  final String? subtitle;
  final double? progress;
  final Widget? detailsWidget;
  final Widget? chartWidget;
  final List<Widget>? listItems;
  final VoidCallback? onTap;
  final bool useGradient;

  const UnifiedWidgetBase({
    super.key,
    required this.size,
    this.accentColor,
    required this.icon,
    required this.title,
    this.value,
    this.unit,
    this.subtitle,
    this.progress,
    this.detailsWidget,
    this.chartWidget,
    this.listItems,
    this.onTap,
    this.useGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = WidgetLayoutConfig.forSize(size);
    final color = accentColor ?? kDefaultWidgetColor;
    
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: color.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: useGradient
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withOpacity(0.08),
                      color.withOpacity(0.02),
                    ],
                  )
                : null,
            color: useGradient ? null : kDefaultWidgetBackground,
          ),
          padding: EdgeInsets.all(config.padding),
          child: config.layoutAxis == Axis.horizontal
              ? _buildHorizontalLayout(config, color)
              : _buildVerticalLayout(config, color),
        ),
      ),
    );
  }

  Widget _buildVerticalLayout(WidgetLayoutConfig config, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: Icon + Titel
        Row(
          children: [
            if (config.showIcon)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: config.iconSize * 0.7, color: color),
              ),
            if (config.showIcon) const SizedBox(width: 8),
            if (config.showTitle)
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: config.titleSize,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        
        const Spacer(),
        
        // Wert + Einheit
        if (config.showValue && value != null) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value!,
                style: TextStyle(
                  fontSize: config.valueSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    unit!,
                    style: TextStyle(
                      fontSize: config.subtitleSize,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
        
        // Fortschrittsbalken
        if (config.showProgress && progress != null) ...[
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress!.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
        
        // Subtitle
        if (config.showSubtitle && subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: config.subtitleSize,
              color: Colors.grey.shade500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        
        // Details Widget
        if (config.showDetails && detailsWidget != null) ...[
          const SizedBox(height: 8),
          detailsWidget!,
        ],
        
        // Chart Widget
        if (config.showChart && chartWidget != null) ...[
          const SizedBox(height: 8),
          Expanded(flex: 2, child: chartWidget!),
        ],
        
        // Liste
        if (config.showList && listItems != null && listItems!.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...listItems!.take(config.maxListItems),
        ],
      ],
    );
  }

  Widget _buildHorizontalLayout(WidgetLayoutConfig config, Color color) {
    return Row(
      children: [
        // Icon
        if (config.showIcon)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: config.iconSize, color: color),
          ),
        
        const SizedBox(width: 12),
        
        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (config.showTitle)
                Text(
                  title,
                  style: TextStyle(
                    fontSize: config.titleSize,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (config.showValue && value != null) ...[
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value!,
                      style: TextStyle(
                        fontSize: config.valueSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    if (unit != null) ...[
                      const SizedBox(width: 2),
                      Text(
                        unit!,
                        style: TextStyle(
                          fontSize: config.subtitleSize,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              if (config.showSubtitle && subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: config.subtitleSize,
                    color: Colors.grey.shade500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        
        // Fortschritt oder Details rechts
        if (config.showProgress && progress != null) ...[
          const SizedBox(width: 12),
          SizedBox(
            width: 50,
            height: 50,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress!.clamp(0.0, 1.0),
                  strokeWidth: 4,
                  backgroundColor: color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
                Center(
                  child: Text(
                    '${(progress! * 100).round()}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
