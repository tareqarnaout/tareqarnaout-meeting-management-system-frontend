import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class DocumentPreviewData {
  final String meetingTitle;
  final String referenceNumber;
  final String issueDate;
  final List<String> recipients;
  final String councilType;
  final String sessionNumber;
  final String academicYear;
  final String meetingDate;
  final String decisionNumber;
  final String decisionText;
  final List<String> copyToList;
  final String signatoryName;
  final String signatoryTitle;

  const DocumentPreviewData({
    this.meetingTitle = '',
    this.referenceNumber = '',
    this.issueDate = '',
    this.recipients = const [],
    this.councilType = 'مجلس القسم',
    this.sessionNumber = '',
    this.academicYear = '',
    this.meetingDate = '',
    this.decisionNumber = '',
    this.decisionText = '',
    this.copyToList = const [],
    this.signatoryName = 'أ.د. عبدالله',
    this.signatoryTitle = 'رئيس القسم',
  });
}

class DocumentPreview extends StatelessWidget {
  final DocumentPreviewData data;
  final bool showPlaceholders;

  const DocumentPreview({
    super.key,
    required this.data,
    this.showPlaceholders = true,
  });

  static const Color _inkColor = Color(0xFF1B3A5C);
  static const double _pageWidth = 520;
  static const double _pageHeight = 735; // A4 proportions
  static const double _pagePadding = 40;
  static const double _contentWidth = _pageWidth - _pagePadding * 2;
  static const double _contentHeight = _pageHeight - _pagePadding * 2;

  // Approximate height consumed by fixed content on page 1 (logo, ref, greeting, body intro, decision title)
  static const double _page1FixedHeight = 360;

  // Approximate height consumed by closing/signature/footer on the last page
  static const double _lastPageReservedHeight = 230;

  static const TextStyle _decisionTextStyle = TextStyle(
    fontSize: 11,
    height: 1.8,
    color: _inkColor,
  );

  /// Splits [text] into chunks that fit on each page using TextPainter measurement.
  List<String> _paginateText(String text) {
    if (text.isEmpty) return [''];

    final List<String> pages = [];
    String remaining = text;
    bool isFirstPage = true;

    while (remaining.isNotEmpty) {
      double available = isFirstPage
          ? _contentHeight - _page1FixedHeight
          : _contentHeight - _lastPageReservedHeight;

      // Guard: if the reserved blocks exceed content height, allow at least 1 line
      if (available < 20) available = 20;

      final int charsFit = _measureCharsFit(remaining, available);
      final int cut = charsFit.clamp(1, remaining.length);

      pages.add(remaining.substring(0, cut));
      remaining = remaining.substring(cut);
      isFirstPage = false;
    }

    return pages;
  }

  /// Returns how many characters of [text] fit within [maxHeight] using binary search.
  int _measureCharsFit(String text, double maxHeight) {
    final TextPainter painter = TextPainter(
      textDirection: ui.TextDirection.rtl,
    );

    int lo = 0;
    int hi = text.length;

    while (lo < hi) {
      final int mid = (lo + hi + 1) ~/ 2;
      painter.text = TextSpan(text: text.substring(0, mid), style: _decisionTextStyle);
      painter.layout(maxWidth: _contentWidth);
      if (painter.height <= maxHeight) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }

    return lo;
  }

  @override
  Widget build(BuildContext context) {
    final List<String> textChunks = _paginateText(data.decisionText);

    return Column(
      children: textChunks.asMap().entries.map((MapEntry<int, String> entry) {
        final int index = entry.key;
        final bool isFirst = index == 0;
        final bool isLast = index == textChunks.length - 1;
        return _buildPage(
          textChunk: entry.value,
          isFirstPage: isFirst,
          isLastPage: isLast,
          pageNumber: index + 1,
          totalPages: textChunks.length,
        );
      }).toList(),
    );
  }

  Widget _buildPage({
    required String textChunk,
    required bool isFirstPage,
    required bool isLastPage,
    required int pageNumber,
    required int totalPages,
  }) {
    return Container(
      width: _pageWidth,
      height: _pageHeight,
      margin: pageNumber > 1 ? const EdgeInsets.only(top: 24) : EdgeInsets.zero,
      padding: const EdgeInsets.all(_pagePadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Page 1 header content ───────────────────────────────────
            if (isFirstPage) ...[
              _buildHeader(),
              const SizedBox(height: 16),
              _buildRefAndDate(),
              const SizedBox(height: 24),
              _buildRecipients(),
              if (data.recipients.isNotEmpty) const SizedBox(height: 16),
              _buildGreeting(),
              if (data.meetingTitle.isNotEmpty) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    data.meetingTitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _inkColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _buildBody(),
              const SizedBox(height: 16),
              _buildDecisionTitle(),
              const SizedBox(height: 12),
            ],

            // ── Decision text chunk ─────────────────────────────────────
            Expanded(
              child: Text(
                textChunk.isEmpty && showPlaceholders
                    ? '.............................................................................................................................'
                    : textChunk,
                style: _decisionTextStyle.copyWith(
                  color: textChunk.isEmpty && showPlaceholders
                      ? AppColors.textMuted
                      : _inkColor,
                ),
                textDirection: ui.TextDirection.rtl,
                overflow: TextOverflow.clip,
              ),
            ),

            // ── Last page closing content ───────────────────────────────
            if (isLastPage) ...[
              const SizedBox(height: 24),
              _buildClosing(),
              const SizedBox(height: 24),
              _buildSignatureBlock(),
              const SizedBox(height: 30),
              if (data.copyToList.isNotEmpty) ...[
                const Divider(color: _inkColor, thickness: 0.5),
                const SizedBox(height: 8),
                const Text(
                  'نسخة إلى:',
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.bold, color: _inkColor),
                ),
                const SizedBox(height: 4),
                ...data.copyToList.map((String name) => Text(
                      '• $name',
                      style: const TextStyle(fontSize: 10, color: _inkColor),
                    )),
                const SizedBox(height: 16),
              ],
            ],

            // ── Footer on every page ────────────────────────────────────
            if (totalPages > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '$pageNumber / $totalPages',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 8, color: _inkColor),
                  textDirection: ui.TextDirection.ltr,
                ),
              ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Image.asset(
        'assets/PSUT_Logo.png',
        height: 120,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildRefAndDate() {
    final String ref = data.referenceNumber;
    final String date = data.issueDate;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text('الرقم: ',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _inkColor)),
            Container(
              padding: const EdgeInsets.only(bottom: 2),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: _inkColor, width: 0.5)),
              ),
              child: Text(
                ref.isEmpty && showPlaceholders ? '___________' : ref,
                style: TextStyle(
                  fontSize: 11,
                  color: ref.isEmpty ? AppColors.textMuted : _inkColor,
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            const Text('التاريخ: ',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _inkColor)),
            Container(
              padding: const EdgeInsets.only(bottom: 2),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: _inkColor, width: 0.5)),
              ),
              child: Text(
                date.isEmpty && showPlaceholders
                    ? '    /    /       '
                    : date,
                style: TextStyle(
                  fontSize: 11,
                  color: date.isEmpty ? AppColors.textMuted : _inkColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecipients() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.recipients
          .map((String r) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(r,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _inkColor)),
              ))
          .toList(),
    );
  }

  Widget _buildGreeting() {
    return const Text(
      'تحية طيبة وبعد،',
      style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.bold, color: _inkColor),
    );
  }

  Widget _buildBody() {
    final String session =
        data.sessionNumber.isEmpty && showPlaceholders ? '...' : data.sessionNumber;
    final String year = data.academicYear.isEmpty && showPlaceholders
        ? '...../.....'
        : data.academicYear;
    final String meetDate =
        data.meetingDate.isEmpty && showPlaceholders ? '.../.../....' : data.meetingDate;

    return RichText(
      textDirection: ui.TextDirection.rtl,
      text: TextSpan(
        style: const TextStyle(
            fontSize: 11, height: 1.8, color: _inkColor),
        children: [
          const TextSpan(text: 'أثبت أدناه قرار '),
          TextSpan(
              text: data.councilType,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const TextSpan(text: ' الذي انعقد المجلس في جلسته رقم ('),
          TextSpan(
              text: session,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const TextSpan(text: ') للعام الدراسي '),
          TextSpan(
              text: year,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: ' المنعقدة بتاريخ $meetDate، وهو على النحو التالي :'),
        ],
      ),
    );
  }

  Widget _buildDecisionTitle() {
    final String num =
        data.decisionNumber.isEmpty && showPlaceholders ? '...' : data.decisionNumber;
    final String year = data.academicYear.isEmpty && showPlaceholders
        ? '...../.....'
        : data.academicYear;

    return Center(
      child: Text(
        'قرار رقم ($num) - $year',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: _inkColor,
          decoration: TextDecoration.underline,
        ),
        textDirection: ui.TextDirection.rtl,
      ),
    );
  }

  Widget _buildClosing() {
    return const Text(
      'وتفضلوا بقبول فائق الاحترام،',
      style: TextStyle(fontSize: 12, color: _inkColor),
      textDirection: ui.TextDirection.rtl,
    );
  }

  Widget _buildSignatureBlock() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(data.signatoryTitle,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _inkColor)),
          const SizedBox(height: 20),
          Container(width: 120, height: 1, color: _inkColor),
          const SizedBox(height: 4),
          Text(data.signatoryName,
              style: const TextStyle(fontSize: 11, color: _inkColor)),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Divider(color: AppColors.textMuted, thickness: 0.5),
        const SizedBox(height: 6),
        const Text(
          'Excellence in Education, since 1991',
          style: TextStyle(
              fontSize: 8, color: _inkColor, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'P.O. Box 1438, Amman 11941, Jordan  |  T: (+962) 6 535 9949  |  F: (+962) 6 534 7295  |  www.psut.edu.jo',
          style: TextStyle(fontSize: 7, color: Colors.grey.shade500),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
