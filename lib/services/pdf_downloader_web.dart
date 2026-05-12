import 'dart:convert';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<void> downloadPdfBytes(Uint8List bytes, String fileName) async {
  final String base64 = base64Encode(bytes);
  final String dataUrl = 'data:application/pdf;base64,$base64';
  final html.AnchorElement anchor = html.AnchorElement(href: dataUrl)
    ..setAttribute('download', fileName)
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}
