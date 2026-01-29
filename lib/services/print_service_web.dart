// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

// Web implementation for print window
void openPrintWindow(String htmlContent) {
  // Use JavaScript interop for better compatibility
  final printWindow = html.window.open('', '_blank');
  if (printWindow != null) {
    // Use dynamic to access window properties
    final dynamic win = printWindow;
    win.document.write(htmlContent);
    win.document.close();
    win.focus();
    win.print();
    // Close the window after printing (with a small delay)
    Future.delayed(const Duration(seconds: 1), () {
      printWindow.close();
    });
  }
}
