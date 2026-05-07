import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StatsScreen extends StatefulWidget {
  final String? doctorName;
  const StatsScreen({super.key, this.doctorName});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _selectedPeriod = 0;
  int _totalCount = 0;
  int _doneCount = 0;
  int _pendingCount = 0;
  int _cancelledCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  DateTime get _startDate {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 1:
        return DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 6));
      case 2:
        return DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 29));
      default:
        return DateTime(now.year, now.month, now.day);
    }
  }

  DateTime get _endDate {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('appointments')
          .select('status, appointment_date, notes')
          .gte('appointment_date', _startDate.toIso8601String())
          .lt('appointment_date', _endDate.toIso8601String());

      var list = List<Map<String, dynamic>>.from(data);

      if (widget.doctorName != null && widget.doctorName!.isNotEmpty) {
        list = list.where((a) {
          final notes = a['notes'] ?? '';
          return notes.contains('Эмч: ${widget.doctorName}');
        }).toList();
      }

      setState(() {
        _totalCount = list.length;
        _doneCount = list.where((a) => a['status'] == 'done').length;
        _pendingCount = list
            .where(
                (a) => a['status'] == 'pending' || a['status'] == 'confirmed')
            .length;
        _cancelledCount = list.where((a) => a['status'] == 'cancelled').length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F1FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A2B47)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Icon(Icons.bar_chart, color: Color(0xFF6B21A8)),
            const SizedBox(width: 8),
            Text(
              widget.doctorName != null
                  ? '\u041c\u0438\u043d\u0438\u0439 \u0441\u0442\u0430\u0442\u0438\u0441\u0442\u0438\u043a'
                  : '\u0421\u0442\u0430\u0442\u0438\u0441\u0442\u0438\u043a',
              style: const TextStyle(
                  color: Color(0xFF1A2B47), fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      color: Color(0xFF6B21A8), size: 18),
                  const SizedBox(width: 8),
                  const Text('\u0425\u0443\u0433\u0430\u0446\u0430\u0430:',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                            child: _buildPeriodTab(
                                '\u04e8\u043d\u04e9\u04e9\u0434\u04e9\u0440', 0)),
                        const SizedBox(width: 6),
                        Expanded(
                            child: _buildPeriodTab(
                                '7 \u0445\u043e\u043d\u043e\u0433', 1)),
                        const SizedBox(width: 6),
                        Expanded(
                            child: _buildPeriodTab(
                                '1 \u0441\u0430\u0440', 2)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                          color: Color(0xFF6B21A8)),
                    ),
                  )
                : GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      _buildStatCard(
                          Icons.people_alt_rounded,
                          '\u041d\u0438\u0439\u0442 \u0446\u0430\u0433 \u0430\u0432\u0441\u0430\u043d',
                          _totalCount,
                          const Color(0xFF1D61FF)),
                      _buildStatCard(
                          Icons.check_circle_outline,
                          '\u04ae\u0439\u043b\u0447\u043b\u04af\u04af\u043b\u0441\u044d\u043d',
                          _doneCount,
                          const Color(0xFF22C55E)),
                      _buildStatCard(
                          Icons.access_time_rounded,
                          '\u0425\u04af\u043b\u044d\u044d\u0436 \u0431\u0430\u0439\u0433\u0430\u0430',
                          _pendingCount,
                          const Color(0xFFFF6B35)),
                      _buildStatCard(
                          Icons.cancel_outlined,
                          '\u0426\u0443\u0446\u0430\u043b\u0441\u0430\u043d',
                          _cancelledCount,
                          const Color(0xFFEF4444)),
                    ],
                  ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                      '\u04ae\u0439\u043b\u0447\u0438\u043b\u0433\u044d\u044d\u043d\u0438\u0439 \u0445\u0430\u0440\u044c\u0446\u0430\u0430',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1A2B47))),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_totalCount == 0)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          children: [
                            Icon(Icons.bar_chart,
                                size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                                '\u0422\u0443\u0445\u0430\u0439\u043d \u0445\u0443\u0433\u0430\u0446\u0430\u0430\u043d\u0434 \u04e9\u0433\u04e9\u0433\u0434\u04e9\u043b \u0431\u0430\u0439\u0445\u0433\u04af\u0439 \u0431\u0430\u0439\u043d\u0430',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        _buildHorizontalBar(
                          icon: Icons.check_circle_outline,
                          label:
                              '\u04ae\u0439\u043b\u0447\u043b\u04af\u04af\u043b\u0441\u044d\u043d',
                          count: _doneCount,
                          total: _totalCount,
                          color: const Color(0xFF22C55E),
                        ),
                        const SizedBox(height: 14),
                        _buildHorizontalBar(
                          icon: Icons.access_time_rounded,
                          label:
                              '\u0425\u04af\u043b\u044d\u044d\u0436 \u0431\u0430\u0439\u0433\u0430\u0430',
                          count: _pendingCount,
                          total: _totalCount,
                          color: const Color(0xFFFF6B35),
                        ),
                        const SizedBox(height: 14),
                        _buildHorizontalBar(
                          icon: Icons.cancel_outlined,
                          label:
                              '\u0426\u0443\u0446\u0430\u043b\u0441\u0430\u043d',
                          count: _cancelledCount,
                          total: _totalCount,
                          color: const Color(0xFFEF4444),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalBar({
    required IconData icon,
    required String label,
    required int count,
    required int total,
    required Color color,
  }) {
    final percent = total == 0 ? 0.0 : count / total;
    final percentText = '${(percent * 100).round()}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(label,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A2B47))),
              ],
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count \u0445\u04af\u043d ($percentText)',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 10,
            backgroundColor: const Color(0xFFE9ECEF),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodTab(String label, int index) {
    final isActive = _selectedPeriod == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPeriod = index);
        _loadStats();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF6B21A8)
              : const Color(0xFFE9ECEF),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      IconData icon, String label, int count, Color color) {
    return Container(
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(14)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text('$count',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}