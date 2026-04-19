import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../constants/app_theme.dart';
import '../models/meeting.dart';
import '../services/meeting_service.dart';
import '../widgets/graph_node.dart';

class DecisionGraphScreen extends StatefulWidget {
  final int? meetingId;

  const DecisionGraphScreen({super.key, this.meetingId});

  @override
  State<DecisionGraphScreen> createState() => _DecisionGraphScreenState();
}

class _DecisionGraphScreenState extends State<DecisionGraphScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final MeetingService _meetingService = MeetingService();
  late AnimationController _animController;

  final Set<String> _activeFilters = {'Applies', 'Change', 'Continue'};

  List<GraphNodeData> _nodes = [];
  List<GraphEdge> _edges = [];

  bool _isLoading = true;
  Meeting? _focusedMeeting;

  Offset _panOffset = Offset.zero;
  double _zoom = 1.0;
  String? _draggingNodeId;
  Offset _lastFocalPoint = Offset.zero;

  bool _isSimulating = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(_simulateForces);

    _loadGraphData();
  }

  Future<void> _loadGraphData() async {
    if (widget.meetingId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final results = await Future.wait([
      _meetingService.getMeeting(widget.meetingId!),
      _meetingService.getMeetingRelationships(widget.meetingId!),
    ]);

    if (!mounted) return;

    final Meeting? focused = results[0] as Meeting?;
    final List<MeetingRelationship> relationships =
        results[1] as List<MeetingRelationship>;

    _buildGraph(focused, relationships);

    setState(() {
      _focusedMeeting = focused;
      _isLoading = false;
      _isSimulating = true;
    });
    _animController.repeat();
  }

  void _buildGraph(Meeting? focused, List<MeetingRelationship> relationships) {
    final Random rng = Random(42);
    final String centerId = 'center';

    final String centerTitle = focused?.title ?? 'Selected Meeting';
    final String centerDate = focused != null
        ? DateFormat('MMM d, yyyy').format(focused.meetingDate)
        : '';

    _nodes = [
      GraphNodeData(
        id: centerId,
        title: centerTitle,
        date: centerDate,
        status: focused?.status ?? 0,
        position: const Offset(300, 220),
        isHighlighted: true,
      ),
      ...relationships.map((MeetingRelationship r) {
        return GraphNodeData(
          id: 'r_${r.meetingId}',
          title: r.title,
          date: DateFormat('MMM d, yyyy').format(r.meetingDate),
          status: 2, // relationships are from finalized meetings
          position: Offset(
            100 + rng.nextDouble() * 500,
            60 + rng.nextDouble() * 350,
          ),
        );
      }),
    ];

    _edges = relationships
        .map((MeetingRelationship r) => GraphEdge(
              sourceId: centerId,
              targetId: 'r_${r.meetingId}',
              label: r.type,
            ))
        .toList();
  }

  void _simulateForces() {
    if (!_isSimulating) return;

    bool anyMoved = false;
    const double repulsion = 8000;
    const double springLength = 220;
    const double springK = 0.02;
    const double damping = 0.85;
    const double minDelta = 0.1;

    for (int i = 0; i < _nodes.length; i++) {
      if (_nodes[i].isDragging) continue;
      Offset force = Offset.zero;

      for (int j = 0; j < _nodes.length; j++) {
        if (i == j) continue;
        final Offset diff = _nodes[i].position - _nodes[j].position;
        final double dist = max(diff.distance, 1);
        force += diff / dist * (repulsion / (dist * dist));
      }

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
        node.isHighlighted = node.id == 'center' ||
            (query.isNotEmpty &&
                node.title.toLowerCase().contains(query.toLowerCase()));
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
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isMobile = constraints.maxWidth < 600;

        return Container(
          color: AppColors.pageBg,
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
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
                    const Expanded(
                      child: Text('Decision Graph',
                          style: AppTextStyles.heading1),
                    ),
                    if (!isMobile)
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
                const SizedBox(height: 4),
                Text(
                  _focusedMeeting != null
                      ? 'Relationships for: ${_focusedMeeting!.title}'
                      : 'Explore how meeting decisions connect across documents.',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),

                // Search
                TextField(
                  controller: _searchController,
                  onChanged: _onSearch,
                  decoration: AppDecorations.inputDecoration(
                    '',
                    hint: 'Search for meetings, decisions...',
                    suffixIcon: const Icon(Icons.search,
                        size: 18, color: AppColors.textMuted),
                  ).copyWith(labelText: null),
                ),
                const SizedBox(height: 12),

                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
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
                ),
                const SizedBox(height: 12),

                // Pro tip
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
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF0369A1)),
                            children: [
                              const TextSpan(
                                  text: 'Pro tip: ',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600)),
                              TextSpan(
                                  text: isMobile
                                      ? 'Drag nodes to rearrange, pinch to zoom.'
                                      : 'The highlighted center node is the selected meeting. '
                                          'Drag nodes to rearrange, scroll to zoom, and use filters to focus on specific relationship types.'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Stats strip (mobile) or side panel (desktop)
                if (isMobile) _buildMobileStatsStrip(),
                if (isMobile) const SizedBox(height: 12),

                // Graph canvas (always expanded)
                Expanded(
                  child: isMobile
                      ? _buildGraphCanvas()
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                  _statRow(
                                      'Related Meetings',
                                      '${max(0, _nodes.length - 1)}',
                                      AppColors.primaryBlue),
                                  const SizedBox(height: 12),
                                  _statRow(
                                      'Total Connections',
                                      '${_edges.length}',
                                      AppColors.statusApproved),
                                  const SizedBox(height: 12),
                                  _statRow(
                                      'Applies',
                                      '${_edges.where((GraphEdge e) => e.label == 'Applies').length}',
                                      const Color(0xFF10B981)),
                                  const SizedBox(height: 12),
                                  _statRow(
                                      'Change',
                                      '${_edges.where((GraphEdge e) => e.label == 'Change').length}',
                                      const Color(0xFFF59E0B)),
                                  const SizedBox(height: 12),
                                  _statRow(
                                      'Continue',
                                      '${_edges.where((GraphEdge e) => e.label == 'Continue').length}',
                                      const Color(0xFF3B82F6)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: _buildGraphCanvas()),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileStatsStrip() {
    final List<MapEntry<String, String>> stats = [
      MapEntry('Meetings', '${max(0, _nodes.length - 1)}'),
      MapEntry('Connections', '${_edges.length}'),
      MapEntry('Applies',
          '${_edges.where((GraphEdge e) => e.label == 'Applies').length}'),
      MapEntry('Change',
          '${_edges.where((GraphEdge e) => e.label == 'Change').length}'),
      MapEntry('Continue',
          '${_edges.where((GraphEdge e) => e.label == 'Continue').length}'),
    ];
    final List<Color> colors = [
      AppColors.primaryBlue,
      AppColors.statusApproved,
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF3B82F6),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: AppDecorations.cardWithBorder,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(stats.length, (int i) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                stats[i].value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colors[i],
                ),
              ),
              Text(
                stats[i].key,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildGraphCanvas() {
    return Container(
      decoration: AppDecorations.cardWithBorder,
      clipBehavior: Clip.hardEdge,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _nodes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.account_tree_outlined,
                          size: 48,
                          color: AppColors.textMuted.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      const Text('No relationships found',
                          style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : GestureDetector(
                  onScaleStart: (ScaleStartDetails details) {
                    _lastFocalPoint = details.focalPoint;
                  },
                  onScaleUpdate: (ScaleUpdateDetails details) {
                    if (_draggingNodeId == null) {
                      setState(() {
                        _panOffset +=
                            (details.focalPoint - _lastFocalPoint) / _zoom;
                        _lastFocalPoint = details.focalPoint;
                        if (details.scale != 1.0) {
                          _zoom =
                              (_zoom * details.scale).clamp(0.4, 2.0);
                        }
                      });
                    }
                  },
                  child: Stack(
                    children: [
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
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Column(
                          children: [
                            _zoomButton(Icons.add, () {
                              setState(() =>
                                  _zoom = (_zoom + 0.1).clamp(0.4, 2.0));
                            }),
                            const SizedBox(height: 4),
                            _zoomButton(Icons.remove, () {
                              setState(() =>
                                  _zoom = (_zoom - 0.1).clamp(0.4, 2.0));
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
    );
  }

  List<GraphEdge> get _filteredEdges {
    return _edges
        .where((GraphEdge e) => _activeFilters.contains(e.label))
        .toList();
  }

  List<Widget> _buildFilterChips() {
    const List<String> types = ['Applies', 'Change', 'Continue'];
    final Map<String, Color> colors = {
      'Applies': const Color(0xFF10B981),
      'Change': const Color(0xFFF59E0B),
      'Continue': const Color(0xFF3B82F6),
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
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.w400)),
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
              color: isActive
                  ? chipColor.withValues(alpha: 0.4)
                  : AppColors.border),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          showCheckmark: false,
          padding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
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
        Expanded(child: Text(label, style: AppTextStyles.caption)),
        Text(value,
            style: const TextStyle(
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
