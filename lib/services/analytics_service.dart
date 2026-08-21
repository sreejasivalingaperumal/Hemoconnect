import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Analytics data container holding real metrics from Supabase database.
class AnalyticsData {
  final int totalProfiles;
  final int totalDonors;
  final int approvedDonors;
  final int pendingDonors;
  final int rejectedDonors;
  final int totalEmergencyRequests;
  final int pendingEmergencyRequests;
  final int processingEmergencyRequests;
  final int completedEmergencyRequests;
  final Map<String, int> bloodGroupDistribution;

  AnalyticsData({
    required this.totalProfiles,
    required this.totalDonors,
    required this.approvedDonors,
    required this.pendingDonors,
    required this.rejectedDonors,
    required this.totalEmergencyRequests,
    required this.pendingEmergencyRequests,
    required this.processingEmergencyRequests,
    required this.completedEmergencyRequests,
    required this.bloodGroupDistribution,
  });
}

/// Analytics service retrieving aggregated real data for admin dashboards & fl_charts.
class AnalyticsService {
  final SupabaseClient _client = SupabaseConfig.client;

  /// Fetch full analytics metrics from real database records
  Future<AnalyticsData> getAnalyticsSummary() async {
    // 1. Fetch Donors Summary
    final donorsResponse = await _client.from('donors').select('status, blood_group');
    final donorsList = donorsResponse as List<dynamic>;

    int approved = 0;
    int pending = 0;
    int rejected = 0;

    final bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
    final Map<String, int> dist = {for (var g in bloodGroups) g: 0};

    for (var item in donorsList) {
      final status = item['status'] as String? ?? 'Pending';
      final bg = item['blood_group'] as String?;

      if (status == 'Approved') approved++;
      else if (status == 'Pending') pending++;
      else if (status == 'Rejected') rejected++;

      if (bg != null && dist.containsKey(bg)) {
        dist[bg] = (dist[bg] ?? 0) + 1;
      }
    }

    // 2. Fetch Emergency Requests Summary
    final emergencyResponse = await _client.from('emergency_requests').select('status');
    final emergencyList = emergencyResponse as List<dynamic>;

    int ePending = 0;
    int eProcessing = 0;
    int eCompleted = 0;

    for (var item in emergencyList) {
      final status = item['status'] as String? ?? 'Pending';
      if (status == 'Pending') ePending++;
      else if (status == 'Processing') eProcessing++;
      else if (status == 'Completed') eCompleted++;
    }

    // 3. Fetch Total Profiles Count
    final profilesResponse = await _client.from('profiles').select('id');
    final profilesCount = (profilesResponse as List<dynamic>).length;

    return AnalyticsData(
      totalProfiles: profilesCount,
      totalDonors: donorsList.length,
      approvedDonors: approved,
      pendingDonors: pending,
      rejectedDonors: rejected,
      totalEmergencyRequests: emergencyList.length,
      pendingEmergencyRequests: ePending,
      processingEmergencyRequests: eProcessing,
      completedEmergencyRequests: eCompleted,
      bloodGroupDistribution: dist,
    );
  }
}
