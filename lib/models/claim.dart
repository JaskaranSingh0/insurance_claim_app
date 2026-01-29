import 'package:uuid/uuid.dart';

// Enum for claim status - matches the workflow requirements
enum ClaimStatus { draft, submitted, approved, rejected, partiallysettled }

extension ClaimStatusExtension on ClaimStatus {
  String get displayName {
    switch (this) {
      case ClaimStatus.draft:
        return 'Draft';
      case ClaimStatus.submitted:
        return 'Submitted';
      case ClaimStatus.approved:
        return 'Approved';
      case ClaimStatus.rejected:
        return 'Rejected';
      case ClaimStatus.partiallysettled:
        return 'Partially Settled';
    }
  }

  // Returns which statuses this status can transition to
  List<ClaimStatus> get allowedTransitions {
    switch (this) {
      case ClaimStatus.draft:
        return [ClaimStatus.submitted];
      case ClaimStatus.submitted:
        return [ClaimStatus.approved, ClaimStatus.rejected];
      case ClaimStatus.approved:
        return [ClaimStatus.partiallysettled];
      case ClaimStatus.rejected:
        return [ClaimStatus.draft]; // can re-edit and resubmit
      case ClaimStatus.partiallysettled:
        return [ClaimStatus.approved]; // fully settled = approved
    }
  }
}

// Bill item model
class Bill {
  final String id;
  String description;
  double amount;
  DateTime date;
  String category; // e.g., "Lab", "Medication", "Consultation", etc.

  Bill({
    String? id,
    required this.description,
    required this.amount,
    DateTime? date,
    this.category = 'General',
  }) : id = id ?? const Uuid().v4(),
       date = date ?? DateTime.now();

  Bill copyWith({
    String? description,
    double? amount,
    DateTime? date,
    String? category,
  }) {
    return Bill(
      id: id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
    );
  }
}

// Advance payment model
class Advance {
  final String id;
  double amount;
  DateTime date;
  String? notes;

  Advance({String? id, required this.amount, DateTime? date, this.notes})
    : id = id ?? const Uuid().v4(),
      date = date ?? DateTime.now();
}

// Settlement record model
class Settlement {
  final String id;
  double amount;
  DateTime date;
  String reference; // payment reference number or cheque no
  String? notes;

  Settlement({
    String? id,
    required this.amount,
    DateTime? date,
    this.reference = '',
    this.notes,
  }) : id = id ?? const Uuid().v4(),
       date = date ?? DateTime.now();
}

// Main Claim model
class Claim {
  final String id;
  String patientName;
  String patientId; // hospital ID or insurance ID
  String insuranceProvider;
  String policyNumber;
  DateTime admissionDate;
  DateTime? dischargeDate;
  String diagnosis;
  ClaimStatus status;
  List<Bill> bills;
  List<Advance> advances;
  List<Settlement> settlements;
  DateTime createdAt;
  DateTime updatedAt;
  String? notes;

  Claim({
    String? id,
    required this.patientName,
    required this.patientId,
    required this.insuranceProvider,
    required this.policyNumber,
    required this.admissionDate,
    this.dischargeDate,
    required this.diagnosis,
    this.status = ClaimStatus.draft,
    List<Bill>? bills,
    List<Advance>? advances,
    List<Settlement>? settlements,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.notes,
  }) : id = id ?? const Uuid().v4(),
       bills = bills ?? [],
       advances = advances ?? [],
       settlements = settlements ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Calculate total bills amount
  double get totalBills {
    return bills.fold(0.0, (sum, bill) => sum + bill.amount);
  }

  // Calculate total advances paid
  double get totalAdvances {
    return advances.fold(0.0, (sum, adv) => sum + adv.amount);
  }

  // Calculate total settlements received
  double get totalSettlements {
    return settlements.fold(0.0, (sum, set) => sum + set.amount);
  }

  // Calculate pending amount (what's still owed)
  double get pendingAmount {
    // Total bills minus what's been paid (advances + settlements)
    double paid = totalAdvances + totalSettlements;
    return totalBills - paid;
  }

  // Check if claim can transition to a specific status
  bool canTransitionTo(ClaimStatus newStatus) {
    return status.allowedTransitions.contains(newStatus);
  }

  // Create a copy with updated fields
  Claim copyWith({
    String? patientName,
    String? patientId,
    String? insuranceProvider,
    String? policyNumber,
    DateTime? admissionDate,
    DateTime? dischargeDate,
    String? diagnosis,
    ClaimStatus? status,
    List<Bill>? bills,
    List<Advance>? advances,
    List<Settlement>? settlements,
    String? notes,
  }) {
    return Claim(
      id: id,
      patientName: patientName ?? this.patientName,
      patientId: patientId ?? this.patientId,
      insuranceProvider: insuranceProvider ?? this.insuranceProvider,
      policyNumber: policyNumber ?? this.policyNumber,
      admissionDate: admissionDate ?? this.admissionDate,
      dischargeDate: dischargeDate ?? this.dischargeDate,
      diagnosis: diagnosis ?? this.diagnosis,
      status: status ?? this.status,
      bills: bills ?? this.bills,
      advances: advances ?? this.advances,
      settlements: settlements ?? this.settlements,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      notes: notes ?? this.notes,
    );
  }
}
