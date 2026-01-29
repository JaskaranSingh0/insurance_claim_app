import 'package:flutter/foundation.dart';
import '../models/claim.dart';

class ClaimsProvider extends ChangeNotifier {
  final List<Claim> _claims = [];

  // Getter for all claims
  List<Claim> get claims => List.unmodifiable(_claims);

  // Get claims filtered by status
  List<Claim> getClaimsByStatus(ClaimStatus status) {
    return _claims.where((c) => c.status == status).toList();
  }

  // Get a single claim by id
  Claim? getClaimById(String id) {
    try {
      return _claims.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  // Add a new claim
  void addClaim(Claim claim) {
    _claims.add(claim);
    notifyListeners();
  }

  // Update an existing claim
  void updateClaim(Claim updatedClaim) {
    final idx = _claims.indexWhere((c) => c.id == updatedClaim.id);
    if (idx != -1) {
      _claims[idx] = updatedClaim;
      notifyListeners();
    }
  }

  // Delete a claim (only drafts can be deleted)
  bool deleteClaim(String id) {
    final claim = getClaimById(id);
    if (claim != null && claim.status == ClaimStatus.draft) {
      _claims.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    }
    return false;
  }

  // Change claim status with validation
  bool changeClaimStatus(String id, ClaimStatus newStatus) {
    final claim = getClaimById(id);
    if (claim != null && claim.canTransitionTo(newStatus)) {
      final updated = claim.copyWith(status: newStatus);
      updateClaim(updated);
      return true;
    }
    return false;
  }

  // Add bill to a claim
  void addBillToClaim(String claimId, Bill bill) {
    final claim = getClaimById(claimId);
    if (claim != null) {
      final updatedBills = List<Bill>.from(claim.bills)..add(bill);
      updateClaim(claim.copyWith(bills: updatedBills));
    }
  }

  // Update bill in a claim
  void updateBillInClaim(String claimId, Bill updatedBill) {
    final claim = getClaimById(claimId);
    if (claim != null) {
      final updatedBills = claim.bills.map((b) {
        return b.id == updatedBill.id ? updatedBill : b;
      }).toList();
      updateClaim(claim.copyWith(bills: updatedBills));
    }
  }

  // Remove bill from a claim
  void removeBillFromClaim(String claimId, String billId) {
    final claim = getClaimById(claimId);
    if (claim != null) {
      final updatedBills = claim.bills.where((b) => b.id != billId).toList();
      updateClaim(claim.copyWith(bills: updatedBills));
    }
  }

  // Add advance to a claim
  void addAdvanceToClaim(String claimId, Advance advance) {
    final claim = getClaimById(claimId);
    if (claim != null) {
      final updatedAdvances = List<Advance>.from(claim.advances)..add(advance);
      updateClaim(claim.copyWith(advances: updatedAdvances));
    }
  }

  // Remove advance from a claim
  void removeAdvanceFromClaim(String claimId, String advanceId) {
    final claim = getClaimById(claimId);
    if (claim != null) {
      final updatedAdvances = claim.advances
          .where((a) => a.id != advanceId)
          .toList();
      updateClaim(claim.copyWith(advances: updatedAdvances));
    }
  }

  // Add settlement to a claim
  void addSettlementToClaim(String claimId, Settlement settlement) {
    final claim = getClaimById(claimId);
    if (claim != null) {
      final updatedSettlements = List<Settlement>.from(claim.settlements)
        ..add(settlement);
      updateClaim(claim.copyWith(settlements: updatedSettlements));
    }
  }

  // Remove settlement from a claim
  void removeSettlementFromClaim(String claimId, String settlementId) {
    final claim = getClaimById(claimId);
    if (claim != null) {
      final updatedSettlements = claim.settlements
          .where((s) => s.id != settlementId)
          .toList();
      updateClaim(claim.copyWith(settlements: updatedSettlements));
    }
  }

  // Dashboard stats
  int get totalClaimsCount => _claims.length;

  int get draftCount => getClaimsByStatus(ClaimStatus.draft).length;
  int get submittedCount => getClaimsByStatus(ClaimStatus.submitted).length;
  int get approvedCount => getClaimsByStatus(ClaimStatus.approved).length;
  int get rejectedCount => getClaimsByStatus(ClaimStatus.rejected).length;
  int get partiallySettledCount =>
      getClaimsByStatus(ClaimStatus.partiallysettled).length;

  double get totalPendingAmount {
    return _claims.fold(0.0, (sum, claim) => sum + claim.pendingAmount);
  }

  double get totalBilledAmount {
    return _claims.fold(0.0, (sum, claim) => sum + claim.totalBills);
  }

  double get totalSettledAmount {
    return _claims.fold(
      0.0,
      (sum, claim) => sum + claim.totalSettlements + claim.totalAdvances,
    );
  }

  // Add some sample data for testing
  void loadSampleData() {
    if (_claims.isNotEmpty) return; // don't reload if already have data

    final sampleClaim1 = Claim(
      patientName: 'Rahul Sharma',
      patientId: 'PAT-2024-001',
      insuranceProvider: 'HDFC Ergo',
      policyNumber: 'HE-2024-789456',
      admissionDate: DateTime(2024, 1, 15),
      dischargeDate: DateTime(2024, 1, 20),
      diagnosis: 'Appendectomy',
      status: ClaimStatus.submitted,
      bills: [
        Bill(
          description: 'Room charges (5 days)',
          amount: 25000,
          category: 'Room',
        ),
        Bill(
          description: 'Surgery charges',
          amount: 45000,
          category: 'Surgery',
        ),
        Bill(description: 'Anesthesia', amount: 8000, category: 'Surgery'),
        Bill(description: 'Medicines', amount: 12000, category: 'Medication'),
        Bill(description: 'Lab tests', amount: 5500, category: 'Lab'),
      ],
      advances: [Advance(amount: 30000, notes: 'Initial deposit')],
    );

    final sampleClaim2 = Claim(
      patientName: 'Priya Patel',
      patientId: 'PAT-2024-002',
      insuranceProvider: 'Star Health',
      policyNumber: 'SH-2024-123789',
      admissionDate: DateTime(2024, 1, 22),
      diagnosis: 'Dengue treatment',
      status: ClaimStatus.draft,
      bills: [
        Bill(description: 'Room charges', amount: 15000, category: 'Room'),
        Bill(
          description: 'IV fluids and medications',
          amount: 8000,
          category: 'Medication',
        ),
        Bill(description: 'Blood tests', amount: 4500, category: 'Lab'),
      ],
    );

    final sampleClaim3 = Claim(
      patientName: 'Amit Kumar',
      patientId: 'PAT-2024-003',
      insuranceProvider: 'ICICI Lombard',
      policyNumber: 'IL-2024-456123',
      admissionDate: DateTime(2024, 1, 10),
      dischargeDate: DateTime(2024, 1, 12),
      diagnosis: 'Fracture treatment',
      status: ClaimStatus.approved,
      bills: [
        Bill(
          description: 'Emergency room',
          amount: 5000,
          category: 'Consultation',
        ),
        Bill(description: 'X-Ray', amount: 2000, category: 'Lab'),
        Bill(
          description: 'Cast and bandages',
          amount: 3500,
          category: 'Medical Supplies',
        ),
        Bill(
          description: 'Orthopedic consultation',
          amount: 1500,
          category: 'Consultation',
        ),
      ],
      advances: [Advance(amount: 5000, notes: 'Emergency deposit')],
      settlements: [Settlement(amount: 7000, reference: 'CHQ-123456')],
    );

    _claims.addAll([sampleClaim1, sampleClaim2, sampleClaim3]);
    notifyListeners();
  }
}
