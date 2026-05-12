import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../widgets/document_preview.dart';
import 'pdf_downloader_stub.dart'
    if (dart.library.html) 'pdf_downloader_web.dart' as pdf_downloader;

class PdfService {
  static const PdfColor _inkColor = PdfColor.fromInt(0xFF1B3A5C);
  static const PdfColor _mutedColor = PdfColor.fromInt(0xFF94A3B8);

  Future<Uint8List> generateMeetingPdf(DocumentPreviewData data) async {
    final pw.Document pdf = pw.Document();

    final Uint8List logoBytes =
        (await rootBundle.load('assets/PSUT_Logo.png')).buffer.asUint8List();
    final pw.MemoryImage logoImage = pw.MemoryImage(logoBytes);

    final Uint8List regularFontBytes =
        (await rootBundle.load('assets/fonts/Amiri-Regular.ttf'))
            .buffer
            .asUint8List();
    final Uint8List boldFontBytes =
        (await rootBundle.load('assets/fonts/Amiri-Bold.ttf'))
            .buffer
            .asUint8List();
    final pw.Font arabicFont = pw.Font.ttf(regularFontBytes.buffer.asByteData());
    final pw.Font arabicBold = pw.Font.ttf(boldFontBytes.buffer.asByteData());

    final pw.TextStyle bodyStyle = pw.TextStyle(
      font: arabicFont,
      fontBold: arabicBold,
      fontSize: 11,
      lineSpacing: 6,
      color: _inkColor,
    );
    final pw.TextStyle boldStyle = bodyStyle.copyWith(
      fontWeight: pw.FontWeight.bold,
    );
    final pw.TextStyle smallStyle = bodyStyle.copyWith(fontSize: 10);
    final pw.TextStyle tinyStyle = bodyStyle.copyWith(
      fontSize: 8,
      color: _mutedColor,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(40),
        header: (pw.Context context) {
          if (context.pageNumber > 1) return pw.SizedBox();
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Center(
                child: pw.Image(logoImage, height: 100),
              ),
              pw.SizedBox(height: 16),
              _buildRefAndDate(data, bodyStyle, boldStyle),
              pw.SizedBox(height: 20),
              if (data.recipients.isNotEmpty) ...[
                ...data.recipients.map((String r) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 2),
                      child: pw.Text(r, style: boldStyle.copyWith(fontSize: 12)),
                    )),
                pw.SizedBox(height: 12),
              ],
              pw.Text('تحية طيبة وبعد،', style: boldStyle.copyWith(fontSize: 12)),
              if (data.meetingTitle.isNotEmpty) ...[
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    data.meetingTitle,
                    style: boldStyle.copyWith(fontSize: 13),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
              pw.SizedBox(height: 10),
              _buildBodyIntro(data, bodyStyle, boldStyle),
              pw.SizedBox(height: 14),
              pw.Center(
                child: pw.Text(
                  'قرار رقم (${data.decisionNumber.isEmpty ? '...' : data.decisionNumber}) - ${data.academicYear.isEmpty ? '...../.....' : data.academicYear}',
                  style: boldStyle.copyWith(
                    fontSize: 12,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
              ),
              pw.SizedBox(height: 12),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(color: _mutedColor, thickness: 0.5),
              pw.SizedBox(height: 4),
              pw.Text(
                'Excellence in Education, since 1991',
                style: tinyStyle.copyWith(
                  fontItalic: arabicFont,
                  fontSize: 8,
                  color: _inkColor,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'P.O. Box 1438, Amman 11941, Jordan  |  T: (+962) 6 535 9949  |  F: (+962) 6 534 7295  |  www.psut.edu.jo',
                style: tinyStyle.copyWith(fontSize: 7),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                '${context.pageNumber} / ${context.pagesCount}',
                style: tinyStyle.copyWith(fontSize: 8),
                textAlign: pw.TextAlign.center,
                textDirection: pw.TextDirection.ltr,
              ),
            ],
          );
        },
        build: (pw.Context context) {
          final pw.TextStyle decisionStyle = bodyStyle.copyWith(lineSpacing: 8);
          final List<String> paragraphs = data.decisionText.split('\n');
          return [
            ...paragraphs.map((String p) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Text(
                    p,
                    style: decisionStyle,
                    textDirection: pw.TextDirection.rtl,
                  ),
                )),
            pw.SizedBox(height: 24),
            pw.Text('وتفضلوا بقبول فائق الاحترام،', style: bodyStyle),
            pw.SizedBox(height: 24),
            pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(data.signatoryTitle, style: boldStyle),
                  pw.SizedBox(height: 20),
                  pw.Container(width: 120, height: 1, color: _inkColor),
                  pw.SizedBox(height: 4),
                  pw.Text(data.signatoryName, style: smallStyle),
                ],
              ),
            ),
            if (data.copyToList.isNotEmpty) ...[
              pw.SizedBox(height: 24),
              pw.Divider(color: _inkColor, thickness: 0.5),
              pw.SizedBox(height: 6),
              pw.Text('نسخة إلى:', style: boldStyle.copyWith(fontSize: 10)),
              pw.SizedBox(height: 4),
              ...data.copyToList.map((String name) => pw.Text(
                    '• $name',
                    style: smallStyle,
                  )),
            ],
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildRefAndDate(
    DocumentPreviewData data,
    pw.TextStyle bodyStyle,
    pw.TextStyle boldStyle,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Row(children: [
          pw.Text('الرقم: ', style: boldStyle.copyWith(fontSize: 12)),
          pw.Container(
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: _inkColor, width: 0.5),
              ),
            ),
            child: pw.Text(
              data.referenceNumber.isEmpty ? '___________' : data.referenceNumber,
              style: bodyStyle,
            ),
          ),
        ]),
        pw.Row(children: [
          pw.Text('التاريخ: ', style: boldStyle.copyWith(fontSize: 12)),
          pw.Container(
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: _inkColor, width: 0.5),
              ),
            ),
            child: pw.Text(
              data.issueDate.isEmpty ? '    /    /       ' : data.issueDate,
              style: bodyStyle,
            ),
          ),
        ]),
      ],
    );
  }

  pw.Widget _buildBodyIntro(
    DocumentPreviewData data,
    pw.TextStyle bodyStyle,
    pw.TextStyle boldStyle,
  ) {
    final String session = data.sessionNumber.isEmpty ? '...' : data.sessionNumber;
    final String year = data.academicYear.isEmpty ? '...../.....' : data.academicYear;
    final String meetDate = data.meetingDate.isEmpty ? '.../.../....' : data.meetingDate;

    return pw.RichText(
      textDirection: pw.TextDirection.rtl,
      text: pw.TextSpan(
        style: bodyStyle,
        children: [
          const pw.TextSpan(text: 'أثبت أدناه قرار '),
          pw.TextSpan(text: data.councilType, style: boldStyle),
          const pw.TextSpan(text: ' الذي انعقد المجلس في جلسته رقم ('),
          pw.TextSpan(text: session, style: boldStyle),
          const pw.TextSpan(text: ') للعام الدراسي '),
          pw.TextSpan(text: year, style: boldStyle),
          pw.TextSpan(text: ' المنعقدة بتاريخ $meetDate، وهو على النحو التالي :'),
        ],
      ),
    );
  }

  Future<void> downloadPdf(DocumentPreviewData data, String fileName) async {
    final Uint8List bytes = await generateMeetingPdf(data);
    if (kIsWeb) {
      await pdf_downloader.downloadPdfBytes(bytes, '$fileName.pdf');
    } else {
      await Printing.sharePdf(bytes: bytes, filename: '$fileName.pdf');
    }
  }
}
