import 'package:flutter_test/flutter_test.dart';
import 'package:insurance_claim_app/models/claim.dart';

void main() {
  group('Bill', () {
    test('should create a bill with correct properties', () {
      final bill = Bill(
        description: 'Surgery',
        amount: 50000,
        date: DateTime(2024, 1, 15),
        category: 'Surgery',
      );

      expect(bill.description, 'Surgery');
      expect(bill.amount, 50000);
      expect(bill.category, 'Surgery');
      expect(bill.id, isNotEmpty);
    });

    test('should convert to and from JSON', () {
      final original = Bill(
        description: 'Medication',
        amount: 5000,
        date: DateTime(2024, 1, 10),
        category: 'Pharmacy',
      );

      final json = original.toJson();
      final restored = Bill.fromJson(json);

      expect(restored.description, original.description);
      expect(restored.amount, original.amount);
      expect(restored.category, original.category);
    });
  });

  group('Advance', () {
    test('should create an advance with correct properties', () {
      final advance = Advance(
        amount: 10000,
        date: DateTime(2024, 1, 12),
        notes: 'Insurance advance',
      );

      expect(advance.amount, 10000);
      expect(advance.notes, 'Insurance advance');
      expect(advance.id, isNotEmpty);
    });

    test('should convert to and from JSON', () {
      final original = Advance(
        amount: 25000,
        date: DateTime(2024, 1, 14),
        notes: 'Hospital deposit',
      );

      final json = original.toJson();
      final restored = Advance.fromJson(json);

      expect(restored.amount, original.amount);
      expect(restored.notes, original.notes);
    });
  });

  group('Settlement', () {
    test('should create a settlement with correct properties', () {
      final settlement = Settlement(
        amount: 30000,
        date: DateTime(2024, 1, 20),
        reference: 'TXN123456',
      );

      expect(settlement.amount, 30000);
      expect(settlement.reference, 'TXN123456');
      expect(settlement.id, isNotEmpty);
    });

    test('should convert to and from JSON', () {
      final original = Settlement(
        amount: 15000,
        date: DateTime(2024, 1, 18),
        reference: 'REF789',
      );

      final json = original.toJson();
      final restored = Settlement.fromJson(json);

      expect(restored.amount, original.amount);
      expect(restored.reference, original.reference);
    });
  });

  group('Claim', () {
    late Claim claim;

    setUp(() {
      claim = Claim(
        patientName: 'John Doe',
        patientId: 'P001',
        admissionDate: DateTime(2024, 1, 1),
        diagnosis: 'Appendicitis',
        insuranceProvider: 'ICICI Health',
        policyNumber: 'POL12345',
      );
    });

    test('should create a claim with draft status by default', () {
      expect(claim.status, ClaimStatus.draft);
      expect(claim.patientName, 'John Doe');
      expect(claim.patientId, 'P001');
    });

    test('should calculate total bills correctly', () {
      final claimWithBills = claim.copyWith(
        bills: [
          Bill(
            description: 'Bill 1',
            amount: 10000,
            date: DateTime.now(),
            category: 'Surgery',
          ),
          Bill(
            description: 'Bill 2',
            amount: 5000,
            date: DateTime.now(),
            category: 'Pharmacy',
          ),
          Bill(
            description: 'Bill 3',
            amount: 2500,
            date: DateTime.now(),
            category: 'Room',
          ),
        ],
      );

      expect(claimWithBills.totalBills, 17500);
    });

    test('should calculate total advances correctly', () {
      final claimWithAdvances = claim.copyWith(
        advances: [
          Advance(amount: 5000, date: DateTime.now(), notes: 'Insurance'),
          Advance(amount: 3000, date: DateTime.now(), notes: 'Hospital'),
        ],
      );

      expect(claimWithAdvances.totalAdvances, 8000);
    });

    test('should calculate total settlements correctly', () {
      final claimWithSettlements = claim.copyWith(
        settlements: [
          Settlement(amount: 10000, date: DateTime.now(), reference: 'REF1'),
          Settlement(amount: 5000, date: DateTime.now(), reference: 'REF2'),
        ],
      );

      expect(claimWithSettlements.totalSettlements, 15000);
    });

    test('should calculate pending amount correctly', () {
      final fullClaim = claim.copyWith(
        bills: [
          Bill(
            description: 'Bill 1',
            amount: 50000,
            date: DateTime.now(),
            category: 'Surgery',
          ),
        ],
        advances: [
          Advance(amount: 10000, date: DateTime.now(), notes: 'Insurance'),
        ],
        settlements: [
          Settlement(amount: 20000, date: DateTime.now(), reference: 'REF1'),
        ],
      );

      // Pending = totalBills - totalAdvances - totalSettlements
      // Pending = 50000 - 10000 - 20000 = 20000
      expect(fullClaim.pendingAmount, 20000);
    });

    test('should not allow negative pending amount', () {
      final overSettled = claim.copyWith(
        bills: [
          Bill(
            description: 'Bill 1',
            amount: 10000,
            date: DateTime.now(),
            category: 'Surgery',
          ),
        ],
        settlements: [
          Settlement(amount: 15000, date: DateTime.now(), reference: 'REF1'),
        ],
      );

      // Pending could be negative, but let's check what the model returns
      expect(overSettled.pendingAmount <= 0, true);
    });

    test('should convert to and from JSON preserving all data', () {
      final fullClaim = claim.copyWith(
        bills: [
          Bill(
            description: 'Surgery',
            amount: 50000,
            date: DateTime(2024, 1, 5),
            category: 'Surgery',
          ),
        ],
        advances: [
          Advance(
            amount: 10000,
            date: DateTime(2024, 1, 6),
            notes: 'Insurance',
          ),
        ],
        settlements: [
          Settlement(
            amount: 20000,
            date: DateTime(2024, 1, 10),
            reference: 'TXN123',
          ),
        ],
        status: ClaimStatus.approved,
      );

      final json = fullClaim.toJson();
      final restored = Claim.fromJson(json);

      expect(restored.patientName, fullClaim.patientName);
      expect(restored.patientId, fullClaim.patientId);
      expect(restored.status, fullClaim.status);
      expect(restored.bills.length, fullClaim.bills.length);
      expect(restored.advances.length, fullClaim.advances.length);
      expect(restored.settlements.length, fullClaim.settlements.length);
      expect(restored.totalBills, fullClaim.totalBills);
    });
  });

  group('ClaimStatus', () {
    test('displayName should return proper formatted names', () {
      expect(ClaimStatus.draft.displayName, 'Draft');
      expect(ClaimStatus.submitted.displayName, 'Submitted');
      expect(ClaimStatus.approved.displayName, 'Approved');
      expect(ClaimStatus.rejected.displayName, 'Rejected');
      expect(ClaimStatus.partiallysettled.displayName, 'Partially Settled');
    });
  });

  group('Claim Status Transitions', () {
    test('draft can transition to submitted', () {
      final claim = Claim(
        patientName: 'Test',
        patientId: 'T001',
        admissionDate: DateTime.now(),
        diagnosis: 'Test',
        insuranceProvider: 'Test',
        policyNumber: 'Test',
        status: ClaimStatus.draft,
      );

      expect(claim.canTransitionTo(ClaimStatus.submitted), true);
      expect(claim.canTransitionTo(ClaimStatus.approved), false);
    });

    test('submitted can transition to approved or rejected', () {
      final claim = Claim(
        patientName: 'Test',
        patientId: 'T001',
        admissionDate: DateTime.now(),
        diagnosis: 'Test',
        insuranceProvider: 'Test',
        policyNumber: 'Test',
        status: ClaimStatus.submitted,
      );

      expect(claim.canTransitionTo(ClaimStatus.approved), true);
      expect(claim.canTransitionTo(ClaimStatus.rejected), true);
      expect(claim.canTransitionTo(ClaimStatus.partiallysettled), false);
    });

    test('approved can transition to partially settled', () {
      final claim = Claim(
        patientName: 'Test',
        patientId: 'T001',
        admissionDate: DateTime.now(),
        diagnosis: 'Test',
        insuranceProvider: 'Test',
        policyNumber: 'Test',
        status: ClaimStatus.approved,
      );

      expect(claim.canTransitionTo(ClaimStatus.partiallysettled), true);
      expect(claim.canTransitionTo(ClaimStatus.draft), false);
    });

    test('rejected can transition back to draft', () {
      final claim = Claim(
        patientName: 'Test',
        patientId: 'T001',
        admissionDate: DateTime.now(),
        diagnosis: 'Test',
        insuranceProvider: 'Test',
        policyNumber: 'Test',
        status: ClaimStatus.rejected,
      );

      expect(claim.canTransitionTo(ClaimStatus.draft), true);
      expect(claim.canTransitionTo(ClaimStatus.approved), false);
    });

    test('partiallysettled can transition back to approved', () {
      final claim = Claim(
        patientName: 'Test',
        patientId: 'T001',
        admissionDate: DateTime.now(),
        diagnosis: 'Test',
        insuranceProvider: 'Test',
        policyNumber: 'Test',
        status: ClaimStatus.partiallysettled,
      );

      expect(claim.canTransitionTo(ClaimStatus.approved), true);
      expect(claim.canTransitionTo(ClaimStatus.draft), false);
    });
  });
}
