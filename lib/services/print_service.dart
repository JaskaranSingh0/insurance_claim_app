import 'package:intl/intl.dart';
import '../models/claim.dart';

// Conditional import for web vs non-web
import 'print_service_stub.dart'
    if (dart.library.html) 'print_service_web.dart'
    as platform;

/// Service for generating printable HTML documents
class PrintService {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
  );
  static final _dateFormat = DateFormat('dd MMM yyyy');

  /// Opens a print dialog with a formatted claim document
  static void printClaim(Claim claim) {
    final htmlContent = _generateClaimHtml(claim);
    platform.openPrintWindow(htmlContent);
  }

  static String _generateClaimHtml(Claim claim) {
    final billRows = claim.bills
        .map(
          (b) =>
              '''
      <tr>
        <td>${_dateFormat.format(b.date)}</td>
        <td>${b.description}</td>
        <td>${b.category}</td>
        <td style="text-align: right;">${_currencyFormat.format(b.amount)}</td>
      </tr>
    ''',
        )
        .join('');

    final advanceRows = claim.advances
        .map(
          (a) =>
              '''
      <tr>
        <td>${_dateFormat.format(a.date)}</td>
        <td>${a.notes ?? 'N/A'}</td>
        <td style="text-align: right;">${_currencyFormat.format(a.amount)}</td>
      </tr>
    ''',
        )
        .join('');

    final settlementRows = claim.settlements
        .map(
          (s) =>
              '''
      <tr>
        <td>${_dateFormat.format(s.date)}</td>
        <td>${s.reference}</td>
        <td style="text-align: right;">${_currencyFormat.format(s.amount)}</td>
      </tr>
    ''',
        )
        .join('');

    return '''
<!DOCTYPE html>
<html>
<head>
  <title>Claim - ${claim.patientName}</title>
  <style>
    * {
      font-family: 'Segoe UI', Arial, sans-serif;
      box-sizing: border-box;
    }
    body {
      padding: 40px;
      max-width: 800px;
      margin: 0 auto;
      color: #333;
    }
    h1 {
      color: #1976d2;
      border-bottom: 2px solid #1976d2;
      padding-bottom: 10px;
      margin-bottom: 30px;
    }
    h2 {
      color: #444;
      font-size: 1.2em;
      margin-top: 30px;
      padding-bottom: 5px;
      border-bottom: 1px solid #ddd;
    }
    .header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
    }
    .status {
      padding: 6px 12px;
      border-radius: 4px;
      background: ${_getStatusColor(claim.status)};
      color: white;
      font-weight: bold;
    }
    .info-grid {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 15px;
      margin: 20px 0;
    }
    .info-item label {
      font-size: 12px;
      color: #666;
      display: block;
    }
    .info-item value {
      font-weight: 500;
      display: block;
      margin-top: 2px;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      margin: 15px 0;
    }
    th, td {
      padding: 10px;
      text-align: left;
      border-bottom: 1px solid #eee;
    }
    th {
      background: #f5f5f5;
      font-weight: 600;
    }
    .summary {
      background: #f9f9f9;
      padding: 20px;
      border-radius: 8px;
      margin-top: 30px;
    }
    .summary-row {
      display: flex;
      justify-content: space-between;
      padding: 8px 0;
      border-bottom: 1px solid #eee;
    }
    .summary-row:last-child {
      border-bottom: none;
      font-weight: bold;
      font-size: 1.1em;
      color: #1976d2;
    }
    .footer {
      margin-top: 40px;
      padding-top: 20px;
      border-top: 1px solid #ddd;
      font-size: 12px;
      color: #666;
      text-align: center;
    }
    @media print {
      body { padding: 20px; }
      .no-print { display: none; }
    }
  </style>
</head>
<body>
  <div class="header">
    <h1>Insurance Claim Report</h1>
    <span class="status">${claim.status.displayName}</span>
  </div>
  
  <h2>Patient Information</h2>
  <div class="info-grid">
    <div class="info-item">
      <label>Patient Name</label>
      <value>${claim.patientName}</value>
    </div>
    <div class="info-item">
      <label>Patient ID</label>
      <value>${claim.patientId}</value>
    </div>
    <div class="info-item">
      <label>Diagnosis</label>
      <value>${claim.diagnosis}</value>
    </div>
    <div class="info-item">
      <label>Admission Date</label>
      <value>${_dateFormat.format(claim.admissionDate)}</value>
    </div>
  </div>

  <h2>Insurance Details</h2>
  <div class="info-grid">
    <div class="info-item">
      <label>Insurance Provider</label>
      <value>${claim.insuranceProvider}</value>
    </div>
    <div class="info-item">
      <label>Policy Number</label>
      <value>${claim.policyNumber}</value>
    </div>
  </div>

  ${claim.bills.isNotEmpty ? '''
  <h2>Bills (${claim.bills.length})</h2>
  <table>
    <thead>
      <tr>
        <th>Date</th>
        <th>Description</th>
        <th>Category</th>
        <th style="text-align: right;">Amount</th>
      </tr>
    </thead>
    <tbody>
      $billRows
    </tbody>
  </table>
  ''' : ''}

  ${claim.advances.isNotEmpty ? '''
  <h2>Advances (${claim.advances.length})</h2>
  <table>
    <thead>
      <tr>
        <th>Date</th>
        <th>Notes</th>
        <th style="text-align: right;">Amount</th>
      </tr>
    </thead>
    <tbody>
      $advanceRows
    </tbody>
  </table>
  ''' : ''}

  ${claim.settlements.isNotEmpty ? '''
  <h2>Settlements (${claim.settlements.length})</h2>
  <table>
    <thead>
      <tr>
        <th>Date</th>
        <th>Reference</th>
        <th style="text-align: right;">Amount</th>
      </tr>
    </thead>
    <tbody>
      $settlementRows
    </tbody>
  </table>
  ''' : ''}

  <div class="summary">
    <h2 style="margin-top: 0;">Financial Summary</h2>
    <div class="summary-row">
      <span>Total Bills</span>
      <span>${_currencyFormat.format(claim.totalBills)}</span>
    </div>
    <div class="summary-row">
      <span>Total Advances</span>
      <span>${_currencyFormat.format(claim.totalAdvances)}</span>
    </div>
    <div class="summary-row">
      <span>Total Settlements</span>
      <span>${_currencyFormat.format(claim.totalSettlements)}</span>
    </div>
    <div class="summary-row">
      <span>Pending Amount</span>
      <span>${_currencyFormat.format(claim.pendingAmount)}</span>
    </div>
  </div>

  <div class="footer">
    <p>Generated on ${_dateFormat.format(DateTime.now())} | Claim ID: ${claim.id}</p>
    <p>Insurance Claim Management System</p>
  </div>
</body>
</html>
''';
  }

  static String _getStatusColor(ClaimStatus status) {
    switch (status) {
      case ClaimStatus.draft:
        return '#9e9e9e';
      case ClaimStatus.submitted:
        return '#2196f3';
      case ClaimStatus.approved:
        return '#4caf50';
      case ClaimStatus.rejected:
        return '#f44336';
      case ClaimStatus.partiallysettled:
        return '#ff9800';
    }
  }
}
