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

  static const Map<String, Color> _edgeColors = {
    'Applies': Color(0xFF10B981),
    'Change': Color(0xFFF59E0B),
    'Continue': Color(0xFF3B82F6),
  };

  static const double _nodeWidth = 170;
  static const double _nodeHalfW = _nodeWidth / 2;
  static const double _nodeHeight = 80;
  static const double _nodeHalfH = _nodeHeight / 2;
  static const double _arrowSize = 10;

  GraphEdgePainter({
    required this.nodes,
    required this.edges,
    required this.panOffset,
    required this.zoom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final GraphEdge edge in edges) {
      final GraphNodeData? source = _findNode(edge.sourceId);
      final GraphNodeData? target = _findNode(edge.targetId);
      if (source == null || target == null) continue;

      final Color edgeColor = _edgeColors[edge.label] ?? const Color(0xFFCBD5E1);

      final Offset sCenter = (source.position + panOffset) * zoom +
          const Offset(_nodeHalfW, _nodeHalfH);
      final Offset tCenter = (target.position + panOffset) * zoom +
          const Offset(_nodeHalfW, _nodeHalfH);

      final Offset sEdge = _nodeEdgePoint(sCenter, tCenter);
      final Offset tEdge = _nodeEdgePoint(tCenter, sCenter);

      final Offset rawMid = (sEdge + tEdge) / 2;
      final Offset perpDir = Offset(-(tEdge.dy - sEdge.dy), tEdge.dx - sEdge.dx);
      final double perpLen = perpDir.distance;
      final Offset curveOffset = perpLen > 0
          ? perpDir / perpLen * 25 * zoom
          : Offset.zero;
      final Offset controlPt = rawMid + curveOffset;

      final Paint linePaint = Paint()
        ..color = edgeColor.withValues(alpha: 0.7)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      final Path path = Path()
        ..moveTo(sEdge.dx, sEdge.dy)
        ..quadraticBezierTo(controlPt.dx, controlPt.dy, tEdge.dx, tEdge.dy);
      canvas.drawPath(path, linePaint);

      // Arrowhead aligned to curve tangent at endpoint
      final Offset tangent = tEdge - controlPt;
      final double tangentLen = tangent.distance;
      if (tangentLen > 0) {
        final Offset unitTangent = tangent / tangentLen;
        final Offset perp = Offset(-unitTangent.dy, unitTangent.dx);
        final double arrowLen = _arrowSize * zoom.clamp(0.6, 1.4);
        final double arrowHalfW = arrowLen * 0.45;
        final Offset arrowBase = tEdge - unitTangent * arrowLen;

        final Path arrow = Path()
          ..moveTo(tEdge.dx, tEdge.dy)
          ..lineTo(arrowBase.dx + perp.dx * arrowHalfW,
              arrowBase.dy + perp.dy * arrowHalfW)
          ..lineTo(arrowBase.dx - perp.dx * arrowHalfW,
              arrowBase.dy - perp.dy * arrowHalfW)
          ..close();
        canvas.drawPath(
          arrow,
          Paint()
            ..color = edgeColor
            ..style = PaintingStyle.fill,
        );
      }

      // Edge label with background pill
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: edge.label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: edgeColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final Offset labelPos = _quadraticBezierPoint(sEdge, controlPt, tEdge, 0.5);
      final Offset labelOffset = Offset(
        labelPos.dx - tp.width / 2,
        labelPos.dy - tp.height / 2,
      );

      final RRect pillRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          labelOffset.dx - 5,
          labelOffset.dy - 2,
          tp.width + 10,
          tp.height + 4,
        ),
        const Radius.circular(6),
      );
      canvas.drawRRect(
        pillRect,
        Paint()..color = Colors.white.withValues(alpha: 0.92),
      );
      canvas.drawRRect(
        pillRect,
        Paint()
          ..color = edgeColor.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      tp.paint(canvas, labelOffset);
    }
  }

  Offset _nodeEdgePoint(Offset nodeCenter, Offset other) {
    final Offset dir = other - nodeCenter;
    if (dir.distance == 0) return nodeCenter;

    final double hw = _nodeHalfW * zoom;
    final double hh = _nodeHalfH * zoom;

    final double scaleX = dir.dx != 0 ? (hw / dir.dx.abs()) : double.infinity;
    final double scaleY = dir.dy != 0 ? (hh / dir.dy.abs()) : double.infinity;
    final double scale = scaleX < scaleY ? scaleX : scaleY;

    return nodeCenter + dir * scale;
  }

  Offset _quadraticBezierPoint(Offset p0, Offset p1, Offset p2, double t) {
    final double mt = 1 - t;
    return p0 * (mt * mt) + p1 * (2 * mt * t) + p2 * (t * t);
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
