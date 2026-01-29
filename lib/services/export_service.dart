import 'package:intl/intl.dart';
import '../models/claim.dart';

// Conditional import for web vs non-web
import 'export_service_stub.dart'
    if (dart.library.html) 'export_service_web.dart'
    as platform;

class ExportService {
  static final _dateFormat = DateFormat('dd-MM-yyyy');

  // Export a single claim to CSV
  static void exportClaimToCsv(Claim claim) {
    final csvContent = _generateClaimCsv(claim);
    platform.downloadFile(
      'claim_${claim.patientId}_${_dateFormat.format(DateTime.now())}.csv',
      csvContent,
    );
  }

  // Export all claims to CSV
  static void exportAllClaimsToCsv(List<Claim> claims) {
    final csvContent = _generateAllClaimsCsv(claims);
    platform.downloadFile(
      'all_claims_${_dateFormat.format(DateTime.now())}.csv',
      csvContent,
    );
  }

  static String _generateClaimCsv(Claim claim) {
    final buffer = StringBuffer();

    // Header info
    buffer.writeln('INSURANCE CLAIM REPORT');
    buffer.writeln('Generated on,${_dateFormat.format(DateTime.now())}');
    buffer.writeln('');

    // Patient Information
    buffer.writeln('PATIENT INFORMATION');
    buffer.writeln('Patient Name,${_escapeCSV(claim.patientName)}');
    buffer.writeln('Patient ID,${_escapeCSV(claim.patientId)}');
    buffer.writeln('Diagnosis,${_escapeCSV(claim.diagnosis)}');
    buffer.writeln('Admission Date,${_dateFormat.format(claim.admissionDate)}');
    if (claim.dischargeDate != null) {
      buffer.writeln(
        'Discharge Date,${_dateFormat.format(claim.dischargeDate!)}',
      );
    }
    buffer.writeln('');

    // Insurance Information
    buffer.writeln('INSURANCE INFORMATION');
    buffer.writeln('Insurance Provider,${_escapeCSV(claim.insuranceProvider)}');
    buffer.writeln('Policy Number,${_escapeCSV(claim.policyNumber)}');
    buffer.writeln('Claim Status,${claim.status.displayName}');
    buffer.writeln('');

    // Bills Section
    buffer.writeln('BILLS');
    buffer.writeln('Description,Category,Amount,Date');
    for (final bill in claim.bills) {
      buffer.writeln(
        '${_escapeCSV(bill.description)},${_escapeCSV(bill.category)},${bill.amount},${_dateFormat.format(bill.date)}',
      );
    }
    buffer.writeln('');

    // Advances Section
    buffer.writeln('ADVANCES');
    buffer.writeln('Amount,Date,Notes');
    for (final advance in claim.advances) {
      buffer.writeln(
        '${advance.amount},${_dateFormat.format(advance.date)},${_escapeCSV(advance.notes ?? '')}',
      );
    }
    buffer.writeln('');

    // Settlements Section
    buffer.writeln('SETTLEMENTS');
    buffer.writeln('Amount,Date,Reference');
    for (final settlement in claim.settlements) {
      buffer.writeln(
        '${settlement.amount},${_dateFormat.format(settlement.date)},${_escapeCSV(settlement.reference)}',
      );
    }
    buffer.writeln('');

    // Summary
    buffer.writeln('FINANCIAL SUMMARY');
    buffer.writeln('Total Bills,${claim.totalBills}');
    buffer.writeln('Total Advances,${claim.totalAdvances}');
    buffer.writeln('Total Settlements,${claim.totalSettlements}');
    buffer.writeln('Pending Amount,${claim.pendingAmount}');

    return buffer.toString();
  }

  static String _generateAllClaimsCsv(List<Claim> claims) {
    final buffer = StringBuffer();

    // Header info
    buffer.writeln('INSURANCE CLAIMS SUMMARY');
    buffer.writeln('Generated on,${_dateFormat.format(DateTime.now())}');
    buffer.writeln('Total Claims,${claims.length}');
    buffer.writeln('');

    // Table header
    buffer.writeln(
      'Patient Name,Patient ID,Insurance Provider,Policy Number,Diagnosis,Status,Total Bills,Total Advances,Total Settlements,Pending Amount,Created Date',
    );

    // Data rows
    for (final claim in claims) {
      buffer.writeln(
        '${_escapeCSV(claim.patientName)},${_escapeCSV(claim.patientId)},${_escapeCSV(claim.insuranceProvider)},${_escapeCSV(claim.policyNumber)},${_escapeCSV(claim.diagnosis)},${claim.status.displayName},${claim.totalBills},${claim.totalAdvances},${claim.totalSettlements},${claim.pendingAmount},${_dateFormat.format(claim.createdAt)}',
      );
    }

    return buffer.toString();
  }

  static String _escapeCSV(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
