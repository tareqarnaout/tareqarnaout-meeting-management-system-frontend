import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class GraphNodeData {
  final String id;
  final String title;
  final String? date;
  final String? type;
  final int status;
  Offset position;
  Offset velocity;
  bool isDragging;
  bool isHighlighted;

  GraphNodeData({
    required this.id,
    required this.title,
    this.date,
    this.type,
    this.status = 0,
    required this.position,
    Offset? velocity,
    this.isDragging = false,
    this.isHighlighted = false,
  }) : velocity = velocity ?? Offset.zero;
}

class GraphEdge {
  final String sourceId;
  final String targetId;
  final String label;

  const GraphEdge({
    required this.sourceId,
    required this.targetId,
    required this.label,
  });
}

class GraphNodeWidget extends StatelessWidget {
  final GraphNodeData node;
  final VoidCallback? onTap;

  const GraphNodeWidget({super.key, required this.node, this.onTap});

  Color get _borderColor {
    if (node.isHighlighted) return AppColors.primaryBlue;
    switch (node.status) {
      case 0:
        return AppColors.statusDraft;
      case 1:
        return AppColors.statusPending;
      case 2:
        return AppColors.statusApproved;
      default:
        return AppColors.border;
    }
  }

  Color get _bgColor {
    if (node.isHighlighted) return const Color(0xFFEFF6FF);
    switch (node.status) {
      case 0:
        return const Color(0xFFFEF2F2);
      case 1:
        return const Color(0xFFFFFBEB);
      case 2:
        return const Color(0xFFF0FDF4);
      default:
        return Colors.white;
    }
  }

  String get _statusLabel {
    switch (node.status) {
      case 0:
        return 'Draft';
      case 1:
        return 'Pending';
      case 2:
        return 'Finalized';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _borderColor, width: node.isHighlighted ? 2 : 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (node.type != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: _borderColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  node.type!,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: _borderColor,
                  ),
                ),
              ),
            Text(
              node.title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (node.date != null) ...[
              const SizedBox(height: 4),
              Text(
                node.date!,
                style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
              ),
            ],
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: _borderColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                _statusLabel,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: _borderColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GraphEdgePainter extends CustomPainter {
  final List<GraphNodeData> nodes;
  final List<GraphEdge> edges;
  final Offset panOffset;
  final double zoom;

  GraphEdgePainter({
    required this.nodes,
    required this.edges,
    required this.panOffset,
    required this.zoom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final GraphEdge edge in edges) {
      final GraphNodeData? source =
          _findNode(edge.sourceId);
      final GraphNodeData? target =
          _findNode(edge.targetId);
      if (source == null || target == null) continue;

      final Offset s = (source.position + panOffset) * zoom + Offset(85, 40);
      final Offset t = (target.position + panOffset) * zoom + Offset(85, 40);

      // Draw curved line
      final Path path = Path();
      path.moveTo(s.dx, s.dy);
      final Offset mid = Offset((s.dx + t.dx) / 2, (s.dy + t.dy) / 2 - 20);
      path.quadraticBezierTo(mid.dx, mid.dy, t.dx, t.dy);
      canvas.drawPath(path, linePaint);

      // Draw arrow
      final Offset dir = (t - s);
      final double len = dir.distance;
      if (len > 0) {
        final Offset unitDir = dir / len;
        final Offset arrowTip = t - unitDir * 10;
        final Offset perp = Offset(-unitDir.dy, unitDir.dx);
        final Path arrow = Path()
          ..moveTo(t.dx, t.dy)
          ..lineTo(arrowTip.dx + perp.dx * 5, arrowTip.dy + perp.dy * 5)
          ..lineTo(arrowTip.dx - perp.dx * 5, arrowTip.dy - perp.dy * 5)
          ..close();
        canvas.drawPath(
            arrow,
            Paint()
              ..color = const Color(0xFFCBD5E1)
              ..style = PaintingStyle.fill);
      }

      // Draw label
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: edge.label,
          style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(mid.dx - tp.width / 2, mid.dy - tp.height - 4));
    }
  }

  GraphNodeData? _findNode(String id) {
    for (final GraphNodeData n in nodes) {
      if (n.id == id) return n;
    }
    return null;
  }

  @override
  bool shouldRepaint(covariant GraphEdgePainter oldDelegate) => true;
}
