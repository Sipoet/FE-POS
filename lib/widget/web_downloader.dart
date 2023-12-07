import 'package:universal_html/html.dart' as html;
import 'dart:convert';

class WebDownloader {
  const WebDownloader();
  void main() {}
  Future download(String filename, List<int> bytes) async {
    final base64 = base64Encode(bytes);
    // Create the link with the file
    final anchor =
        html.AnchorElement(href: 'data:application/octet-stream;base64,$base64')
          ..target = 'blank';
    anchor.download = filename;
    // trigger download
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
  }
}
