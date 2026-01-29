import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

// Web implementation for file download
void downloadFile(String filename, String content) {
  final bytes = utf8.encode(content);
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'text/csv'),
  );
  final url = web.URL.createObjectURL(blob);

  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = filename;
  anchor.click();

  web.URL.revokeObjectURL(url);
}
