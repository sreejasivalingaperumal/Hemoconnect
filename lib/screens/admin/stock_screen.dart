import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/donor_service.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/loading_widget.dart';

/// Blood Stock Inventory Dashboard calculating available approved donors across all 8 blood types.
class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final DonorService _donorService = DonorService();

  Map<String, int> _bloodStock = {};
  bool _isLoading = true;

  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  @override
  void initState() {
    super.initState();
    _loadStockData();
  }

  Future<void> _loadStockData() async {
    setState(() => _isLoading = true);
    try {
      final stock = await _donorService.getBloodStockCount();
      if (mounted) setState(() => _bloodStock = stock);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Stock Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Inventory',
            onPressed: _loadStockData,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Calculating live blood stock levels...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card Info
                      PremiumCard(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.invert_colors_rounded, color: AppColors.primary, size: 28),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Live Blood Availability Stock',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Calculated in real-time from verified active Approved blood donors.',
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // 8 Blood Group Cards Grid
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final cols = constraints.maxWidth > 800
                              ? 4
                              : constraints.maxWidth > 500
                                  ? 2
                                  : 1;

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.25,
                            ),
                            itemCount: _bloodGroups.length,
                            itemBuilder: (context, index) {
                              final group = _bloodGroups[index];
                              final count = _bloodStock[group] ?? 0;
                              return _buildBloodStockCard(group, count);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildBloodStockCard(String group, int count) {
    Color statusColor;
    String statusText;
    Color bgLightColor;

    if (count >= 10) {
      statusColor = AppColors.success;
      statusText = 'High Availability';
      bgLightColor = AppColors.successBg;
    } else if (count >= 5) {
      statusColor = AppColors.info;
      statusText = 'Moderate Stock';
      bgLightColor = AppColors.infoBg;
    } else if (count >= 1) {
      statusColor = AppColors.warning;
      statusText = 'Low Stock';
      bgLightColor = AppColors.warningBg;
    } else {
      statusColor = AppColors.danger;
      statusText = 'Critical Shortage';
      bgLightColor = AppColors.dangerBg;
    }

    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  group,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Icon(Icons.water_drop_rounded, color: statusColor, size: 28),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count Donors',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: bgLightColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
