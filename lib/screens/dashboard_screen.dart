import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/claim.dart';
import '../providers/claims_provider.dart';
import 'claim_detail_screen.dart';
import 'claim_form_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  ClaimStatus? _filterStatus;
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  @override
  void initState() {
    super.initState();
    // Load sample data on first run
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClaimsProvider>().loadSampleData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insurance Claims'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter claims',
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Consumer<ClaimsProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats cards row
                _buildStatsSection(provider),
                const SizedBox(height: 24),

                // Status summary chips
                _buildStatusChips(provider),
                const SizedBox(height: 24),

                // Claims list header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _filterStatus != null
                          ? '${_filterStatus!.displayName} Claims'
                          : 'All Claims',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (_filterStatus != null)
                      TextButton(
                        onPressed: () {
                          setState(() => _filterStatus = null);
                        },
                        child: const Text('Clear filter'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Claims list
                _buildClaimsList(provider),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateClaim(context),
        icon: const Icon(Icons.add),
        label: const Text('New Claim'),
      ),
    );
  }

  Widget _buildStatsSection(ClaimsProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive: 2 columns on small screens, 4 on larger
        final isWide = constraints.maxWidth > 600;
        final cardWidth = isWide
            ? (constraints.maxWidth - 48) / 4
            : (constraints.maxWidth - 16) / 2;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _StatCard(
              title: 'Total Claims',
              value: provider.totalClaimsCount.toString(),
              icon: Icons.folder_open,
              color: Colors.blue,
              width: cardWidth,
            ),
            _StatCard(
              title: 'Total Billed',
              value: currencyFormat.format(provider.totalBilledAmount),
              icon: Icons.receipt_long,
              color: Colors.purple,
              width: cardWidth,
            ),
            _StatCard(
              title: 'Total Settled',
              value: currencyFormat.format(provider.totalSettledAmount),
              icon: Icons.check_circle_outline,
              color: Colors.green,
              width: cardWidth,
            ),
            _StatCard(
              title: 'Pending',
              value: currencyFormat.format(provider.totalPendingAmount),
              icon: Icons.pending_actions,
              color: Colors.orange,
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusChips(ClaimsProvider provider) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _StatusChip(
          label: 'Draft',
          count: provider.draftCount,
          color: Colors.grey,
          isSelected: _filterStatus == ClaimStatus.draft,
          onTap: () => setState(() {
            _filterStatus = _filterStatus == ClaimStatus.draft
                ? null
                : ClaimStatus.draft;
          }),
        ),
        _StatusChip(
          label: 'Submitted',
          count: provider.submittedCount,
          color: Colors.blue,
          isSelected: _filterStatus == ClaimStatus.submitted,
          onTap: () => setState(() {
            _filterStatus = _filterStatus == ClaimStatus.submitted
                ? null
                : ClaimStatus.submitted;
          }),
        ),
        _StatusChip(
          label: 'Approved',
          count: provider.approvedCount,
          color: Colors.green,
          isSelected: _filterStatus == ClaimStatus.approved,
          onTap: () => setState(() {
            _filterStatus = _filterStatus == ClaimStatus.approved
                ? null
                : ClaimStatus.approved;
          }),
        ),
        _StatusChip(
          label: 'Rejected',
          count: provider.rejectedCount,
          color: Colors.red,
          isSelected: _filterStatus == ClaimStatus.rejected,
          onTap: () => setState(() {
            _filterStatus = _filterStatus == ClaimStatus.rejected
                ? null
                : ClaimStatus.rejected;
          }),
        ),
        _StatusChip(
          label: 'Partially Settled',
          count: provider.partiallySettledCount,
          color: Colors.orange,
          isSelected: _filterStatus == ClaimStatus.partiallysettled,
          onTap: () => setState(() {
            _filterStatus = _filterStatus == ClaimStatus.partiallysettled
                ? null
                : ClaimStatus.partiallysettled;
          }),
        ),
      ],
    );
  }

  Widget _buildClaimsList(ClaimsProvider provider) {
    final claims = _filterStatus != null
        ? provider.getClaimsByStatus(_filterStatus!)
        : provider.claims;

    if (claims.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                _filterStatus != null
                    ? 'No ${_filterStatus!.displayName.toLowerCase()} claims'
                    : 'No claims yet',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Click the + button to create one',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: claims.length,
      itemBuilder: (context, index) {
        final claim = claims[index];
        return _ClaimCard(
          claim: claim,
          onTap: () => _navigateToClaimDetail(context, claim.id),
        );
      },
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filter by Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Claims'),
              leading: Radio<ClaimStatus?>(
                value: null,
                groupValue: _filterStatus,
                onChanged: (val) {
                  setState(() => _filterStatus = val);
                  Navigator.pop(ctx);
                },
              ),
              onTap: () {
                setState(() => _filterStatus = null);
                Navigator.pop(ctx);
              },
            ),
            ...ClaimStatus.values.map(
              (status) => ListTile(
                title: Text(status.displayName),
                leading: Radio<ClaimStatus?>(
                  value: status,
                  groupValue: _filterStatus,
                  onChanged: (val) {
                    setState(() => _filterStatus = val);
                    Navigator.pop(ctx);
                  },
                ),
                onTap: () {
                  setState(() => _filterStatus = status);
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCreateClaim(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ClaimFormScreen()),
    );
  }

  void _navigateToClaimDetail(BuildContext context, String claimId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ClaimDetailScreen(claimId: claimId)),
    );
  }
}

// Stats card widget
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double width;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
        ],
      ),
    );
  }
}

// Status chip widget
class _StatusChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.count,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text('$label ($count)'),
      backgroundColor: isSelected ? color.withOpacity(0.2) : null,
      side: BorderSide(color: isSelected ? color : Colors.grey[300]!),
      onPressed: onTap,
    );
  }
}

// Claim card widget
class _ClaimCard extends StatelessWidget {
  final Claim claim;
  final VoidCallback onTap;

  const _ClaimCard({required this.claim, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final dateFormat = DateFormat('dd MMM yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      claim.patientName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _StatusBadge(status: claim.status),
                ],
              ),
              const SizedBox(height: 8),

              // Patient ID and diagnosis
              Text(
                '${claim.patientId} • ${claim.diagnosis}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 4),

              // Insurance info
              Text(
                '${claim.insuranceProvider} - ${claim.policyNumber}',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
              const SizedBox(height: 12),

              // Amounts row
              Row(
                children: [
                  _AmountInfo(
                    label: 'Total',
                    amount: currencyFormat.format(claim.totalBills),
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 24),
                  _AmountInfo(
                    label: 'Pending',
                    amount: currencyFormat.format(claim.pendingAmount),
                    color: claim.pendingAmount > 0
                        ? Colors.orange
                        : Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Date info
              Text(
                'Admitted: ${dateFormat.format(claim.admissionDate)}',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: _color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _AmountInfo extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;

  const _AmountInfo({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        Text(
          amount,
          style: TextStyle(fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}
