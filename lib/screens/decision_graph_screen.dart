import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_theme.dart';
import '../widgets/graph_node.dart';

class DecisionGraphScreen extends StatefulWidget {
  final String? focusMeeting;

  const DecisionGraphScreen({super.key, this.focusMeeting});

  @override
  State<DecisionGraphScreen> createState() => _DecisionGraphScreenState();
}

class _DecisionGraphScreenState extends State<DecisionGraphScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animController;

  final Set<String> _activeFilters = {'Implements', 'References', 'Supersedes', 'Supplements', 'Amends'};

  // Graph data
  late List<GraphNodeData> _nodes;
  late List<GraphEdge> _edges;

  Offset _panOffset = Offset.zero;
  double _zoom = 1.0;
  String? _draggingNodeId;
  Offset _lastFocalPoint = Offset.zero;

  // Force simulation
  bool _isSimulating = true;

  @override
  void initState() {
    super.initState();
    _initGraphData();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(_simulateForces);
    _animController.repeat();

    // Auto-focus on the meeting passed via parameter
    if (widget.focusMeeting != null && widget.focusMeeting!.isNotEmpty) {
      _searchController.text = widget.focusMeeting!;
      _onSearch(widget.focusMeeting!);
    }
  }

  void _initGraphData() {
    final Random rng = Random(42);
    _nodes = [
      GraphNodeData(id: 'n1', title: 'Department Safety Review', date: 'Oct 15, 2025', type: 'Department', status: 0, position: Offset(100 + rng.nextDouble() * 200, 80 + rng.nextDouble() * 100)),
      GraphNodeData(id: 'n2', title: 'Curriculum Review Committee', date: 'Oct 20, 2025', type: 'Committee', status: 1, position: Offset(400 + rng.nextDouble() * 100, 60 + rng.nextDouble() * 100)),
      GraphNodeData(id: 'n3', title: 'Budget Planning Session', date: 'Nov 8, 2025', type: 'Administrative', status: 2, position: Offset(250 + rng.nextDouble() * 100, 250 + rng.nextDouble() * 80)),
      GraphNodeData(id: 'n4', title: 'Faculty Hiring Committee', date: 'Sep 28, 2025', type: 'Committee', status: 1, position: Offset(500 + rng.nextDouble() * 150, 220 + rng.nextDouble() * 80)),
      GraphNodeData(id: 'n5', title: 'Research Collaboration Proposal', date: 'Nov 3, 2025', type: 'Faculty', status: 0, position: Offset(100 + rng.nextDouble() * 100, 350 + rng.nextDouble() * 60)),
      GraphNodeData(id: 'n6', title: 'Student Affairs Meeting', date: 'Sep 10, 2025', type: 'Department', status: 2, position: Offset(380 + rng.nextDouble() * 100, 380 + rng.nextDouble() * 60)),
      GraphNodeData(id: 'n7', title: 'Lab Equipment Procurement', date: 'Aug 22, 2025', type: 'Administrative', status: 2, position: Offset(600 + rng.nextDouble() * 100, 100 + rng.nextDouble() * 80)),
    ];

    _edges = const [
      GraphEdge(sourceId: 'n1', targetId: 'n2', label: 'References'),
      GraphEdge(sourceId: 'n2', targetId: 'n3', label: 'Implements'),
      GraphEdge(sourceId: 'n3', targetId: 'n4', label: 'Supplements'),
      GraphEdge(sourceId: 'n1', targetId: 'n5', label: 'Amends'),
      GraphEdge(sourceId: 'n5', targetId: 'n6', label: 'References'),
      GraphEdge(sourceId: 'n4', targetId: 'n7', label: 'Supersedes'),
      GraphEdge(sourceId: 'n6', targetId: 'n3', label: 'Implements'),
    ];
  }

  void _simulateForces() {
    if (!_isSimulating) return;

    bool anyMoved = false;
    const double repulsion = 8000;
    const double springLength = 220;
    const double springK = 0.02;
    const double damping = 0.85;
    const double minDelta = 0.1;

    // Repulsive forces between all node pairs
    for (int i = 0; i < _nodes.length; i++) {
      if (_nodes[i].isDragging) continue;
      Offset force = Offset.zero;

      for (int j = 0; j < _nodes.length; j++) {
        if (i == j) continue;
        final Offset diff = _nodes[i].position - _nodes[j].position;
        final double dist = max(diff.distance, 1);
        force += diff / dist * (repulsion / (dist * dist));
      }

      // Spring forces for connected edges
      for (final GraphEdge edge in _edges) {
        GraphNodeData? other;
        if (edge.sourceId == _nodes[i].id) {
          other = _findNode(edge.targetId);
        } else if (edge.targetId == _nodes[i].id) {
          other = _findNode(edge.sourceId);
        }
        if (other != null) {
          final Offset diff = _nodes[i].position - other.position;
          final double dist = diff.distance;
          final double displacement = dist - springLength;
          if (dist > 0) {
            force -= diff / dist * displacement * springK;
          }
        }
      }

      // Center gravity
      const Offset center = Offset(400, 250);
      final Offset toCenter = center - _nodes[i].position;
      force += toCenter * 0.001;

      _nodes[i].velocity = (_nodes[i].velocity + force) * damping;

      if (_nodes[i].velocity.distance > minDelta) {
        _nodes[i].position += _nodes[i].velocity;
        anyMoved = true;
      }
    }

    if (!anyMoved) {
      _isSimulating = false;
    }

    setState(() {});
  }

  GraphNodeData? _findNode(String id) {
    for (final GraphNodeData n in _nodes) {
      if (n.id == id) return n;
    }
    return null;
  }

  void _onSearch(String query) {
    setState(() {
      for (final GraphNodeData node in _nodes) {
        node.isHighlighted = query.isNotEmpty &&
            node.title.toLowerCase().contains(query.toLowerCase());
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.pageBg,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          InkWell(
                            onTap: () => context.go('/archive'),
                            borderRadius: BorderRadius.circular(6),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.arrow_back_ios,
                                  size: 16, color: AppColors.textSecondary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Decision Graph', style: AppTextStyles.heading1),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Explore how meeting decisions, rules, and items connect across documents.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go('/archive'),
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Back to Archive'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search bar
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearch,
                    decoration: AppDecorations.inputDecoration(
                      '',
                      hint: 'Search for meetings, decisions, rules, and action items...',
                      suffixIcon: const Icon(Icons.search,
                          size: 18, color: AppColors.textMuted),
                    ).copyWith(labelText: null),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: 'All Meeting Types',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                      icon: const Icon(Icons.keyboard_arrow_down,
                          size: 16, color: AppColors.textMuted),
                      items: const [
                        DropdownMenuItem(
                            value: 'All Meeting Types',
                            child: Text('All Meeting Types')),
                      ],
                      onChanged: (_) {},
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Relationship type filter chips
            Row(
              children: [
                const Text('Relationship Type:',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary)),
                const SizedBox(width: 10),
                ..._buildFilterChips(),
              ],
            ),
            const SizedBox(height: 12),

            // AI tip
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline,
                      size: 16, color: Color(0xFF0284C7)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 12, color: Color(0xFF0369A1)),
                        children: [
                          TextSpan(
                              text: 'Pro tip: ',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          TextSpan(
                              text:
                                  'Enter a meeting name to see linked sub-sections. When looking at a meeting, you can find it\'s previous decisions or track that sub-sections/decisions that flow. Try '),
                          TextSpan(
                              text: '"Department Budget"',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Graph area
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statistics panel
                  Container(
                    width: 180,
                    padding: const EdgeInsets.all(16),
                    decoration: AppDecorations.cardWithBorder,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Graph Statistics',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 16),
                        _statRow('Total Meetings', '${_nodes.length}',
                            AppColors.primaryBlue),
                        const SizedBox(height: 12),
                        _statRow('Total Connections', '${_edges.length}',
                            AppColors.statusApproved),
                        const SizedBox(height: 12),
                        _statRow(
                            'Pending',
                            '${_nodes.where((GraphNodeData n) => n.status == 1).length}',
                            AppColors.statusPending),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Graph canvas
                  Expanded(
                    child: Container(
                      decoration: AppDecorations.cardWithBorder,
                      clipBehavior: Clip.hardEdge,
                      child: GestureDetector(
                        onScaleStart: (ScaleStartDetails details) {
                          _lastFocalPoint = details.focalPoint;
                        },
                        onScaleUpdate: (ScaleUpdateDetails details) {
                          if (_draggingNodeId == null) {
                            setState(() {
                              _panOffset += (details.focalPoint - _lastFocalPoint) / _zoom;
                              _lastFocalPoint = details.focalPoint;
                              if (details.scale != 1.0) {
                                _zoom = (_zoom * details.scale).clamp(0.4, 2.0);
                              }
                            });
                          }
                        },
                        child: Stack(
                          children: [
                            // Edge painter
                            Positioned.fill(
                              child: CustomPaint(
                                painter: GraphEdgePainter(
                                  nodes: _nodes,
                                  edges: _filteredEdges,
                                  panOffset: _panOffset,
                                  zoom: _zoom,
                                ),
                              ),
                            ),
                            // Nodes
                            ..._nodes.map((GraphNodeData node) {
                              final Offset pos =
                                  (node.position + _panOffset) * _zoom;
                              return Positioned(
                                left: pos.dx,
                                top: pos.dy,
                                child: GestureDetector(
                                  onPanStart: (_) {
                                    setState(() {
                                      _draggingNodeId = node.id;
                                      node.isDragging = true;
                                      _isSimulating = false;
                                    });
                                  },
                                  onPanUpdate: (DragUpdateDetails details) {
                                    setState(() {
                                      node.position +=
                                          details.delta / _zoom;
                                    });
                                  },
                                  onPanEnd: (_) {
                                    setState(() {
                                      _draggingNodeId = null;
                                      node.isDragging = false;
                                      node.velocity = Offset.zero;
                                      _isSimulating = true;
                                      _animController.repeat();
                                    });
                                  },
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.grab,
                                    child: GraphNodeWidget(node: node),
                                  ),
                                ),
                              );
                            }),
                            // Zoom controls
                            Positioned(
                              bottom: 12,
                              right: 12,
                              child: Column(
                                children: [
                                  _zoomButton(Icons.add, () {
                                    setState(
                                        () => _zoom = (_zoom + 0.1).clamp(0.4, 2.0));
                                  }),
                                  const SizedBox(height: 4),
                                  _zoomButton(Icons.remove, () {
                                    setState(
                                        () => _zoom = (_zoom - 0.1).clamp(0.4, 2.0));
                                  }),
                                  const SizedBox(height: 4),
                                  _zoomButton(Icons.center_focus_strong, () {
                                    setState(() {
                                      _panOffset = Offset.zero;
                                      _zoom = 1.0;
                                    });
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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

  List<GraphEdge> get _filteredEdges {
    return _edges
        .where((GraphEdge e) => _activeFilters.contains(e.label))
        .toList();
  }

  List<Widget> _buildFilterChips() {
    const List<String> types = [
      'Implements',
      'References',
      'Supersedes',
      'Supplements',
      'Amends'
    ];
    final Map<String, Color> colors = {
      'Implements': const Color(0xFF10B981),
      'References': const Color(0xFF3B82F6),
      'Supersedes': const Color(0xFFF59E0B),
      'Supplements': const Color(0xFF8B5CF6),
      'Amends': const Color(0xFFEF4444),
    };

    return types.map((String type) {
      final bool isActive = _activeFilters.contains(type);
      final Color chipColor = colors[type] ?? AppColors.textMuted;
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: FilterChip(
          label: Text(type,
              style: TextStyle(
                  fontSize: 11,
                  color: isActive ? chipColor : AppColors.textMuted,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400)),
          selected: isActive,
          onSelected: (bool selected) {
            setState(() {
              if (selected) {
                _activeFilters.add(type);
              } else {
                _activeFilters.remove(type);
              }
            });
          },
          selectedColor: chipColor.withValues(alpha: 0.1),
          backgroundColor: Colors.white,
          side: BorderSide(
              color: isActive ? chipColor.withValues(alpha: 0.4) : AppColors.border),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          showCheckmark: false,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      );
    }).toList();
  }

  Widget _statRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: AppTextStyles.caption),
        ),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _zoomButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
            ),
          ],
        ),
        child: Icon(icon, size: 16, color: AppColors.textSecondary),
      ),
    );
  }
}
