import 'dart:js_interop';
import 'package:web/web.dart' as web;

// Web implementation for print window
void openPrintWindow(String htmlContent) {
  final printWindow = web.window.open('', '_blank');
  if (printWindow != null) {
    printWindow.document.write(htmlContent.toJS);
    printWindow.document.close();
    printWindow.focus();
    printWindow.print();
    // Close the window after printing (with a small delay)
    Future.delayed(const Duration(seconds: 1), () {
      printWindow.close();
    });
  }
}
