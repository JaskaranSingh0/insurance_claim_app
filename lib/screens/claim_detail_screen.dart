import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/claim.dart';
import '../providers/claims_provider.dart';
import '../services/export_service.dart';
import '../services/print_service.dart';
import '../utils/dialogs.dart';
import 'claim_form_screen.dart';
import '../widgets/bill_dialog.dart';
import '../widgets/advance_dialog.dart';
import '../widgets/settlement_dialog.dart';

class ClaimDetailScreen extends StatelessWidget {
  final String claimId;

  const ClaimDetailScreen({super.key, required this.claimId});

  @override
  Widget build(BuildContext context) {
    return Consumer<ClaimsProvider>(
      builder: (context, provider, _) {
        final claim = provider.getClaimById(claimId);

        if (claim == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Claim Details')),
            body: const Center(child: Text('Claim not found')),
          );
        }

        return _ClaimDetailContent(claim: claim);
      },
    );
  }
}

class _ClaimDetailContent extends StatefulWidget {
  final Claim claim;

  const _ClaimDetailContent({required this.claim});

  @override
  State<_ClaimDetailContent> createState() => _ClaimDetailContentState();
}

class _ClaimDetailContentState extends State<_ClaimDetailContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  final dateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final claim = widget.claim;
    final canEdit =
        claim.status == ClaimStatus.draft ||
        claim.status == ClaimStatus.rejected;

    return Scaffold(
      appBar: AppBar(
        title: Text(claim.patientName),
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit claim details',
              onPressed: () => _navigateToEdit(context),
            ),
          // Print button
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Print claim',
            onPressed: () => _printClaim(context),
          ),
          PopupMenuButton<String>(
            onSelected: (val) => _handleMenuAction(context, val),
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, size: 18),
                    SizedBox(width: 8),
                    Text('Export to CSV'),
                  ],
                ),
              ),
              if (claim.status == ClaimStatus.draft)
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete Claim'),
                ),
              const PopupMenuItem(value: 'refresh', child: Text('Refresh')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Claim summary card
          _buildSummaryCard(context, claim),

          // Status actions
          _buildStatusActions(context, claim),

          // Tabs for bills, advances, settlements
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Bills (${claim.bills.length})'),
              Tab(text: 'Advances (${claim.advances.length})'),
              Tab(text: 'Settlements (${claim.settlements.length})'),
            ],
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBillsTab(context, claim),
                _buildAdvancesTab(context, claim),
                _buildSettlementsTab(context, claim),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, Claim claim) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    claim.patientId,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    claim.diagnosis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              _StatusBadge(status: claim.status),
            ],
          ),
          const Divider(height: 24),

          // Insurance info
          Row(
            children: [
              const Icon(Icons.business, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${claim.insuranceProvider} • ${claim.policyNumber}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Dates
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Admitted: ${dateFormat.format(claim.admissionDate)}',
                style: TextStyle(color: Colors.grey[700]),
              ),
              if (claim.dischargeDate != null) ...[
                const Text(' • '),
                Text(
                  'Discharged: ${dateFormat.format(claim.dischargeDate!)}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ],
          ),
          const Divider(height: 24),

          // Financial summary
          _buildFinancialSummary(claim),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary(Claim claim) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 400;

        final items = [
          _FinancialItem(
            label: 'Total Bills',
            amount: claim.totalBills,
            color: Colors.blue,
          ),
          _FinancialItem(
            label: 'Advances',
            amount: claim.totalAdvances,
            color: Colors.purple,
          ),
          _FinancialItem(
            label: 'Settled',
            amount: claim.totalSettlements,
            color: Colors.green,
          ),
          _FinancialItem(
            label: 'Pending',
            amount: claim.pendingAmount,
            color: claim.pendingAmount > 0 ? Colors.orange : Colors.green,
            isBold: true,
          ),
        ];

        if (isWide) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: items
                .map((item) => _buildFinancialItemWidget(item))
                .toList(),
          );
        } else {
          return Wrap(
            spacing: 24,
            runSpacing: 12,
            children: items
                .map((item) => _buildFinancialItemWidget(item))
                .toList(),
          );
        }
      },
    );
  }

  Widget _buildFinancialItemWidget(_FinancialItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 2),
        Text(
          currencyFormat.format(item.amount),
          style: TextStyle(
            fontSize: item.isBold ? 16 : 14,
            fontWeight: item.isBold ? FontWeight.bold : FontWeight.w500,
            color: item.color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusActions(BuildContext context, Claim claim) {
    final allowedTransitions = claim.status.allowedTransitions;

    if (allowedTransitions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text(
              'Actions: ',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(width: 8),
            ...allowedTransitions.map((newStatus) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: OutlinedButton.icon(
                  onPressed: () => _changeStatus(context, claim, newStatus),
                  icon: Icon(_getStatusIcon(newStatus), size: 18),
                  label: Text(_getStatusActionText(newStatus)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _getStatusColor(newStatus),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBillsTab(BuildContext context, Claim claim) {
    final canAddBills = claim.status == ClaimStatus.draft;

    return Column(
      children: [
        if (canAddBills)
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () => _showAddBillDialog(context, claim),
              icon: const Icon(Icons.add),
              label: const Text('Add Bill'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ),
        Expanded(
          child: claim.bills.isEmpty
              ? _buildEmptyState(
                  'No bills added yet',
                  Icons.receipt_long_outlined,
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: claim.bills.length,
                  itemBuilder: (ctx, idx) {
                    final bill = claim.bills[idx];
                    return _BillListItem(
                      bill: bill,
                      canEdit: canAddBills,
                      onEdit: () => _showEditBillDialog(context, claim, bill),
                      onDelete: () => _deleteBill(context, claim, bill),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAdvancesTab(BuildContext context, Claim claim) {
    // Can add advances in draft or submitted state
    final canAddAdvance =
        claim.status == ClaimStatus.draft ||
        claim.status == ClaimStatus.submitted;

    return Column(
      children: [
        if (canAddAdvance)
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () => _showAddAdvanceDialog(context, claim),
              icon: const Icon(Icons.add),
              label: const Text('Add Advance'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ),
        Expanded(
          child: claim.advances.isEmpty
              ? _buildEmptyState(
                  'No advances recorded',
                  Icons.payments_outlined,
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: claim.advances.length,
                  itemBuilder: (ctx, idx) {
                    final advance = claim.advances[idx];
                    return _AdvanceListItem(
                      advance: advance,
                      canDelete: canAddAdvance,
                      onDelete: () => _deleteAdvance(context, claim, advance),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSettlementsTab(BuildContext context, Claim claim) {
    // Can only add settlements when approved or partially settled
    final canAddSettlement =
        claim.status == ClaimStatus.approved ||
        claim.status == ClaimStatus.partiallysettled;

    return Column(
      children: [
        if (canAddSettlement)
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () => _showAddSettlementDialog(context, claim),
              icon: const Icon(Icons.add),
              label: const Text('Add Settlement'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ),
        Expanded(
          child: claim.settlements.isEmpty
              ? _buildEmptyState(
                  'No settlements yet',
                  Icons.account_balance_wallet_outlined,
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: claim.settlements.length,
                  itemBuilder: (ctx, idx) {
                    final settlement = claim.settlements[idx];
                    return _SettlementListItem(
                      settlement: settlement,
                      onDelete: canAddSettlement
                          ? () => _deleteSettlement(context, claim, settlement)
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  // Helper methods
  void _navigateToEdit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClaimFormScreen(claimId: widget.claim.id),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'export':
        _exportClaim(context);
        break;
      case 'delete':
        _showDeleteConfirmation(context);
        break;
      case 'refresh':
        // Just triggers rebuild through consumer
        break;
    }
  }

  void _printClaim(BuildContext context) {
    try {
      PrintService.printClaim(widget.claim);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Print failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _exportClaim(BuildContext context) {
    try {
      ExportService.exportClaimToCsv(widget.claim);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Claim exported to CSV'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context) async {
    final confirmed = await DialogUtils.showConfirmDialog(
      context: context,
      title: 'Delete Claim?',
      message:
          'This action cannot be undone. Are you sure you want to delete this claim?',
      confirmText: 'Delete',
      isDangerous: true,
    );

    if (confirmed) {
      // Store the claim for potential undo
      final deletedClaim = widget.claim;
      final provider = context.read<ClaimsProvider>();

      if (provider.deleteClaim(widget.claim.id)) {
        Navigator.pop(context);

        // Show undo option (note: undo re-adds as draft)
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Claim deleted'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () {
                // Re-add the claim
                provider.addClaim(deletedClaim);
              },
            ),
          ),
        );
      }
    }
  }

  void _changeStatus(BuildContext context, Claim claim, ClaimStatus newStatus) {
    // Validate before changing status
    if (newStatus == ClaimStatus.submitted && claim.bills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot submit a claim without any bills'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Change to ${newStatus.displayName}?'),
        content: Text(_getStatusChangeDescription(newStatus)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              final provider = context.read<ClaimsProvider>();
              if (provider.changeClaimStatus(claim.id, newStatus)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Status changed to ${newStatus.displayName}'),
                  ),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(ClaimStatus status) {
    switch (status) {
      case ClaimStatus.draft:
        return Icons.edit_note;
      case ClaimStatus.submitted:
        return Icons.send;
      case ClaimStatus.approved:
        return Icons.check_circle_outline;
      case ClaimStatus.rejected:
        return Icons.cancel_outlined;
      case ClaimStatus.partiallysettled:
        return Icons.pending_actions;
    }
  }

  Color _getStatusColor(ClaimStatus status) {
    switch (status) {
      case ClaimStatus.draft:
        return Colors.grey;
      case ClaimStatus.submitted:
        return Colors.blue;
      case ClaimStatus.approved:
        return Colors.green;
      case ClaimStatus.rejected:
        return Colors.red;
      case ClaimStatus.partiallysettled:
        return Colors.orange;
    }
  }

  String _getStatusActionText(ClaimStatus status) {
    switch (status) {
      case ClaimStatus.draft:
        return 'Revert to Draft';
      case ClaimStatus.submitted:
        return 'Submit';
      case ClaimStatus.approved:
        return 'Approve';
      case ClaimStatus.rejected:
        return 'Reject';
      case ClaimStatus.partiallysettled:
        return 'Mark Partial';
    }
  }

  String _getStatusChangeDescription(ClaimStatus status) {
    switch (status) {
      case ClaimStatus.draft:
        return 'The claim will be moved back to draft status for editing.';
      case ClaimStatus.submitted:
        return 'The claim will be submitted for review. Bills cannot be modified after submission.';
      case ClaimStatus.approved:
        return 'The claim will be marked as approved. Settlements can now be recorded.';
      case ClaimStatus.rejected:
        return 'The claim will be rejected. It can be edited and resubmitted.';
      case ClaimStatus.partiallysettled:
        return 'The claim will be marked as partially settled.';
    }
  }

  // Dialog methods for bills, advances, settlements
  void _showAddBillDialog(BuildContext context, Claim claim) {
    showDialog(
      context: context,
      builder: (ctx) => BillDialog(
        onSave: (bill) {
          context.read<ClaimsProvider>().addBillToClaim(claim.id, bill);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Bill added')));
        },
      ),
    );
  }

  void _showEditBillDialog(BuildContext context, Claim claim, Bill bill) {
    showDialog(
      context: context,
      builder: (ctx) => BillDialog(
        bill: bill,
        onSave: (updatedBill) {
          context.read<ClaimsProvider>().updateBillInClaim(
            claim.id,
            updatedBill,
          );
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Bill updated')));
        },
      ),
    );
  }

  void _deleteBill(BuildContext context, Claim claim, Bill bill) async {
    final confirmed = await DialogUtils.showConfirmDialog(
      context: context,
      title: 'Delete Bill?',
      message:
          'Remove "${bill.description}" (${currencyFormat.format(bill.amount)})?',
      confirmText: 'Delete',
      isDangerous: true,
    );

    if (confirmed) {
      context.read<ClaimsProvider>().removeBillFromClaim(claim.id, bill.id);

      // Show undo snackbar
      DialogUtils.showUndoSnackBar(
        context: context,
        message: 'Bill removed',
        onUndo: () {
          // Re-add the bill
          context.read<ClaimsProvider>().addBillToClaim(claim.id, bill);
        },
      );
    }
  }

  void _showAddAdvanceDialog(BuildContext context, Claim claim) {
    showDialog(
      context: context,
      builder: (ctx) => AdvanceDialog(
        onSave: (advance) {
          context.read<ClaimsProvider>().addAdvanceToClaim(claim.id, advance);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Advance recorded')));
        },
      ),
    );
  }

  void _deleteAdvance(
    BuildContext context,
    Claim claim,
    Advance advance,
  ) async {
    final confirmed = await DialogUtils.showConfirmDialog(
      context: context,
      title: 'Delete Advance?',
      message: 'Remove advance of ${currencyFormat.format(advance.amount)}?',
      confirmText: 'Delete',
      isDangerous: true,
    );

    if (confirmed) {
      context.read<ClaimsProvider>().removeAdvanceFromClaim(
        claim.id,
        advance.id,
      );

      DialogUtils.showUndoSnackBar(
        context: context,
        message: 'Advance removed',
        onUndo: () {
          context.read<ClaimsProvider>().addAdvanceToClaim(claim.id, advance);
        },
      );
    }
  }

  void _showAddSettlementDialog(BuildContext context, Claim claim) {
    showDialog(
      context: context,
      builder: (ctx) => SettlementDialog(
        maxAmount: claim.pendingAmount,
        onSave: (settlement) {
          context.read<ClaimsProvider>().addSettlementToClaim(
            claim.id,
            settlement,
          );

          // Auto-transition to partially settled if there's still pending amount
          final updatedClaim = context.read<ClaimsProvider>().getClaimById(
            claim.id,
          );
          if (updatedClaim != null &&
              updatedClaim.pendingAmount > 0 &&
              updatedClaim.status == ClaimStatus.approved) {
            context.read<ClaimsProvider>().changeClaimStatus(
              claim.id,
              ClaimStatus.partiallysettled,
            );
          }

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Settlement recorded')));
        },
      ),
    );
  }

  void _deleteSettlement(
    BuildContext context,
    Claim claim,
    Settlement settlement,
  ) async {
    final confirmed = await DialogUtils.showConfirmDialog(
      context: context,
      title: 'Delete Settlement?',
      message:
          'Remove settlement of ${currencyFormat.format(settlement.amount)}?',
      confirmText: 'Delete',
      isDangerous: true,
    );

    if (confirmed) {
      context.read<ClaimsProvider>().removeSettlementFromClaim(
        claim.id,
        settlement.id,
      );

      DialogUtils.showUndoSnackBar(
        context: context,
        message: 'Settlement removed',
        onUndo: () {
          context.read<ClaimsProvider>().addSettlementToClaim(
            claim.id,
            settlement,
          );
        },
      );
    }
  }
}

// Supporting widgets
class _StatusBadge extends StatelessWidget {
  final ClaimStatus status;

  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case ClaimStatus.draft:
        return Colors.grey;
      case ClaimStatus.submitted:
        return Colors.blue;
      case ClaimStatus.approved:
        return Colors.green;
      case ClaimStatus.rejected:
        return Colors.red;
      case ClaimStatus.partiallysettled:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: _color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _FinancialItem {
  final String label;
  final double amount;
  final Color color;
  final bool isBold;

  _FinancialItem({
    required this.label,
    required this.amount,
    required this.color,
    this.isBold = false,
  });
}

class _BillListItem extends StatelessWidget {
  final Bill bill;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BillListItem({
    required this.bill,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final dateFormat = DateFormat('dd MMM');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withOpacity(0.1),
          child: Icon(Icons.receipt, color: Colors.blue[700], size: 20),
        ),
        title: Text(bill.description),
        subtitle: Text('${bill.category} • ${dateFormat.format(bill.date)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currencyFormat.format(bill.amount),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (canEdit) ...[
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: onEdit,
                tooltip: 'Edit',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: onDelete,
                tooltip: 'Delete',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AdvanceListItem extends StatelessWidget {
  final Advance advance;
  final bool canDelete;
  final VoidCallback onDelete;

  const _AdvanceListItem({
    required this.advance,
    required this.canDelete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final dateFormat = DateFormat('dd MMM yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple.withOpacity(0.1),
          child: Icon(Icons.payments, color: Colors.purple[700], size: 20),
        ),
        title: Text(currencyFormat.format(advance.amount)),
        subtitle: Text(
          '${dateFormat.format(advance.date)}${advance.notes != null ? ' • ${advance.notes}' : ''}',
        ),
        trailing: canDelete
            ? IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: onDelete,
                tooltip: 'Delete',
              )
            : null,
      ),
    );
  }
}

class _SettlementListItem extends StatelessWidget {
  final Settlement settlement;
  final VoidCallback? onDelete;

  const _SettlementListItem({required this.settlement, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final dateFormat = DateFormat('dd MMM yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.withOpacity(0.1),
          child: Icon(
            Icons.account_balance,
            color: Colors.green[700],
            size: 20,
          ),
        ),
        title: Text(currencyFormat.format(settlement.amount)),
        subtitle: Text(
          '${dateFormat.format(settlement.date)}${settlement.reference.isNotEmpty ? ' • Ref: ${settlement.reference}' : ''}',
        ),
        trailing: onDelete != null
            ? IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: onDelete,
                tooltip: 'Delete',
              )
            : null,
      ),
    );
  }
}
