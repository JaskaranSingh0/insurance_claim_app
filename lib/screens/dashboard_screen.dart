import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/claim.dart';
import '../providers/claims_provider.dart';
import '../providers/theme_provider.dart';
import '../services/export_service.dart';
import 'claim_detail_screen.dart';
import 'claim_form_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  ClaimStatus? _filterStatus;
  String _searchQuery = '';
  String _sortBy = 'date'; // 'date', 'amount', 'name'
  bool _sortAscending = false;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  @override
  void initState() {
    super.initState();
    // Initialize provider and load data
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<ClaimsProvider>();
      await provider.initialize();
      // Load sample data only if no saved data exists
      provider.loadSampleData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // Handle keyboard shortcuts
  void _handleKeyPress(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isCtrl = HardwareKeyboard.instance.isControlPressed;

      // Ctrl+N: New claim
      if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyN) {
        _navigateToCreateClaim(context);
      }
      // Ctrl+F: Focus search
      else if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyF) {
        _searchFocusNode.requestFocus();
      }
      // Escape: Clear search/filter
      else if (event.logicalKey == LogicalKeyboardKey.escape) {
        if (_searchQuery.isNotEmpty || _filterStatus != null) {
          setState(() {
            _searchQuery = '';
            _searchController.clear();
            _filterStatus = null;
          });
        }
      }
    }
  }

  // Get filtered and sorted claims
  List<Claim> _getFilteredClaims(ClaimsProvider provider) {
    var claims = _filterStatus != null
        ? provider.getClaimsByStatus(_filterStatus!)
        : provider.claims.toList();

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      claims = claims.where((c) {
        final query = _searchQuery.toLowerCase();
        return c.patientName.toLowerCase().contains(query) ||
            c.patientId.toLowerCase().contains(query) ||
            c.insuranceProvider.toLowerCase().contains(query) ||
            c.policyNumber.toLowerCase().contains(query) ||
            c.diagnosis.toLowerCase().contains(query);
      }).toList();
    }

    // Apply sorting
    claims.sort((a, b) {
      int result;
      switch (_sortBy) {
        case 'amount':
          result = a.totalBills.compareTo(b.totalBills);
          break;
        case 'name':
          result = a.patientName.toLowerCase().compareTo(
            b.patientName.toLowerCase(),
          );
          break;
        case 'date':
        default:
          result = a.createdAt.compareTo(b.createdAt);
      }
      return _sortAscending ? result : -result;
    });

    return claims;
  }

  // Handle export actions
  void _handleExport(BuildContext context, String exportType) {
    final provider = context.read<ClaimsProvider>();

    try {
      if (exportType == 'all_csv') {
        if (provider.claims.isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No claims to export')));
          return;
        }
        ExportService.exportAllClaimsToCsv(provider.claims);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All claims exported to CSV'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (exportType == 'filtered_csv') {
        final filteredClaims = _getFilteredClaims(provider);
        if (filteredClaims.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No claims match the current filter')),
          );
          return;
        }
        ExportService.exportAllClaimsToCsv(filteredClaims);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${filteredClaims.length} filtered claims exported to CSV',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      autofocus: true,
      onKeyEvent: _handleKeyPress,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Insurance Claims'),
          centerTitle: false,
          actions: [
            // Theme toggle (only show on mobile, desktop has nav rail)
            if (MediaQuery.of(context).size.width <= 900)
              IconButton(
                icon: Icon(
                  themeProvider.isDark ? Icons.light_mode : Icons.dark_mode,
                ),
                tooltip: 'Toggle theme',
                onPressed: () => themeProvider.toggleTheme(),
              ),
            // Keyboard shortcuts help
            IconButton(
              icon: const Icon(Icons.keyboard),
              tooltip:
                  'Keyboard shortcuts:\nCtrl+N: New claim\nCtrl+F: Search\nEsc: Clear filters',
              onPressed: () => _showShortcutsHelp(context),
            ),
            // Sort button
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort),
              tooltip: 'Sort claims',
              onSelected: (value) {
                setState(() {
                  if (_sortBy == value) {
                    _sortAscending = !_sortAscending;
                  } else {
                    _sortBy = value;
                    _sortAscending = false;
                  }
                });
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'date',
                  child: Row(
                    children: [
                      Icon(
                        _sortBy == 'date'
                            ? (_sortAscending
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward)
                            : null,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text('Date'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'name',
                  child: Row(
                    children: [
                      Icon(
                        _sortBy == 'name'
                            ? (_sortAscending
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward)
                            : null,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text('Patient Name'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'amount',
                  child: Row(
                    children: [
                      Icon(
                        _sortBy == 'amount'
                            ? (_sortAscending
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward)
                            : null,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text('Amount'),
                    ],
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filter claims',
              onPressed: _showFilterDialog,
            ),
            // Export button
            PopupMenuButton<String>(
              icon: const Icon(Icons.download),
              tooltip: 'Export claims',
              onSelected: (value) => _handleExport(context, value),
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'all_csv',
                  child: Row(
                    children: [
                      Icon(Icons.table_chart, size: 18),
                      SizedBox(width: 8),
                      Text('Export All to CSV'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'filtered_csv',
                  child: Row(
                    children: [
                      Icon(Icons.filter_alt, size: 18),
                      SizedBox(width: 8),
                      Text('Export Filtered to CSV'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Consumer<ClaimsProvider>(
          builder: (context, provider, child) {
            // Show loading indicator while initializing
            if (provider.isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading claims...'),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search bar
                  _buildSearchBar(),
                  const SizedBox(height: 16),

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
                      Expanded(
                        child: Text(
                          _filterStatus != null
                              ? '${_filterStatus!.displayName} Claims'
                              : 'All Claims',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      if (_filterStatus != null || _searchQuery.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _filterStatus = null;
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                          child: const Text('Clear all'),
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
      ),
    );
  }

  void _showShortcutsHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.keyboard),
            SizedBox(width: 8),
            Text('Keyboard Shortcuts'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ShortcutRow(keys: 'Ctrl + N', description: 'Create new claim'),
            SizedBox(height: 8),
            _ShortcutRow(keys: 'Ctrl + F', description: 'Focus search bar'),
            SizedBox(height: 8),
            _ShortcutRow(keys: 'Esc', description: 'Clear search/filters'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      decoration: InputDecoration(
        hintText: 'Search by patient, ID, insurance...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      onChanged: (val) => setState(() => _searchQuery = val),
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
    final claims = _getFilteredClaims(provider);

    if (claims.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isNotEmpty
                    ? 'No claims matching "$_searchQuery"'
                    : _filterStatus != null
                    ? 'No ${_filterStatus!.displayName.toLowerCase()} claims'
                    : 'No claims yet',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty || _filterStatus != null
                    ? 'Try adjusting your search or filters'
                    : 'Click the + button to create one',
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

class _ShortcutRow extends StatelessWidget {
  final String keys;
  final String description;

  const _ShortcutRow({required this.keys, required this.description});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            keys,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(description),
      ],
    );
  }
}
