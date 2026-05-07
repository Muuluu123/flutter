import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'VisitDetailScreen.dart';

class TodayAppointmentsScreen extends StatefulWidget {
  // doctorName == null бол бүх цагийг харна (admin), үгүй бол зөвхөн тухайн эмчийнхийг
  final String? doctorName;

  const TodayAppointmentsScreen({super.key, this.doctorName});

  @override
  State<TodayAppointmentsScreen> createState() =>
      _TodayAppointmentsScreenState();
}

class _TodayAppointmentsScreenState extends State<TodayAppointmentsScreen> {
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final data = await Supabase.instance.client
          .from('appointments')
          .select('*, patients(profile_id, profiles(full_name))')
          .gte('appointment_date', startOfDay.toIso8601String())
          .lt('appointment_date', endOfDay.toIso8601String())
          .order('appointment_date', ascending: true);

      var list = List<Map<String, dynamic>>.from(data);

      // Эмч нэвтэрсэн бол зөвхөн өөрийн цагуудыг шүүнэ
      if (widget.doctorName != null && widget.doctorName!.isNotEmpty) {
        list = list.where((a) {
          final notes = a['notes'] ?? '';
          return notes.contains('Эмч: ${widget.doctorName}');
        }).toList();
      }

      setState(() {
        _appointments = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('appointments')
          .update({'status': newStatus}).eq('id', id);
      _loadAppointments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Алдаа: ${e.toString()}')),
      );
    }
  }

  Map<String, String> _parseNotes(String? notes) {
    if (notes == null) return {};
    final result = <String, String>{};
    for (final line in notes.split('\n')) {
      if (line.startsWith('Тасаг: '))
        result['department'] = line.replaceFirst('Тасаг: ', '');
      if (line.startsWith('Эмч: '))
        result['doctor'] = line.replaceFirst('Эмч: ', '');
      if (line.startsWith('Шалтгаан: '))
        result['reason'] = line.replaceFirst('Шалтгаан: ', '');
    }
    return result;
  }

  String _formatTime(String isoString) {
    final dt = DateTime.parse(isoString).toLocal();
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  int get _doneCount =>
      _appointments.where((a) => a['status'] == 'done').length;
  int get _pendingCount => _appointments
      .where((a) => a['status'] == 'pending' || a['status'] == 'confirmed')
      .length;
  int get _cancelledCount =>
      _appointments.where((a) => a['status'] == 'cancelled').length;

  @override
  Widget build(BuildContext context) {
    final title = widget.doctorName != null
        ? 'Миний өнөөдрийн цагууд'
        : 'Өнөөдрийн цаг авалтууд';

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
            const Icon(Icons.people_alt_outlined, color: Color(0xFF7C3AED)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      color: Color(0xFF1A2B47),
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
          : RefreshIndicator(
              onRefresh: _loadAppointments,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Дээд статистик
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Color(0xFF7C3AED), size: 18),
                        const SizedBox(width: 8),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 14, color: Color(0xFF1A2B47)),
                            children: [
                              const TextSpan(
                                  text: 'Нийт: ',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(
                                text: '${_appointments.length} цаг авалт  ',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        _buildMiniStat('Үйлчлүүлсэн:', _doneCount,
                            const Color(0xFF22C55E)),
                        const SizedBox(width: 10),
                        _buildMiniStat('Хүлээж\nбайгаа:', _pendingCount,
                            const Color(0xFFFF6B35)),
                        const SizedBox(width: 10),
                        _buildMiniStat('Цуцалсан:', _cancelledCount,
                            const Color(0xFFEF4444)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_appointments.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 60, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('Өнөөдөр цаг авалт байхгүй байна',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 15)),
                          ],
                        ),
                      ),
                    )
                  else
                    ...(_appointments
                        .map((appt) => _buildAppointmentCard(appt))),
                ],
              ),
            ),
    );
  }

  Widget _buildMiniStat(String label, int count, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        Text('$count',
            style: TextStyle(
                fontSize: 16, color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appt) {
    final notes = _parseNotes(appt['notes']);
    final status = appt['status'] ?? 'pending';
    final time = _formatTime(appt['appointment_date']);
    final patientName =
        appt['patients']?['profiles']?['full_name'] ?? 'Тодорхойгүй';

    final isDone = status == 'done';
    final isPending = status == 'pending' || status == 'confirmed';

    final cardColor =
        isDone ? const Color(0xFF22C55E) : const Color(0xFF7C3AED);

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => VisitDetailScreen(appointment: appt)));
        if (result == true) _loadAppointments();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                spreadRadius: 1),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Цагийн хайрцаг
            Container(
              width: 60,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  const Icon(Icons.access_time, color: Colors.white, size: 18),
                  const SizedBox(height: 4),
                  Text(time,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Мэдээлэл
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(patientName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF1A2B47))),
                      ),
                      const SizedBox(width: 6),
                      _buildStatusBadge(status),
                    ],
                  ),
                  if (notes['reason'] != null) ...[
                    const SizedBox(height: 4),
                    Text(notes['reason']!,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 13)),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (notes['doctor'] != null) ...[
                        const Icon(Icons.person_outline,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(notes['doctor']!,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 13)),
                        const SizedBox(width: 16),
                      ],
                      if (notes['department'] != null) ...[
                        const Icon(Icons.local_hospital_outlined,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(notes['department']!,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 13)),
                        ),
                      ],
                    ],
                  ),

                  if (isPending) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _updateStatus(appt['id'], 'done'),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: const Text('✓ Үйлчлүүлсэн',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () =>
                              _updateStatus(appt['id'], 'cancelled'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: Colors.red.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Цуцлах',
                                style: TextStyle(
                                    color: Colors.red.shade400,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;
    switch (status) {
      case 'pending':
        bgColor = const Color(0xFFFFF3CD);
        textColor = const Color(0xFF856404);
        label = 'Хүлээж байна';
        break;
      case 'confirmed':
        bgColor = const Color(0xFFD1ECF1);
        textColor = const Color(0xFF0C5460);
        label = 'Баталгаажсан';
        break;
      case 'done':
        bgColor = const Color(0xFFD4EDDA);
        textColor = const Color(0xFF155724);
        label = 'Үйлчлүүлсэн';
        break;
      case 'cancelled':
        bgColor = const Color(0xFFF8D7DA);
        textColor = const Color(0xFF721C24);
        label = 'Цуцлагдсан';
        break;
      default:
        bgColor = const Color(0xFFE9ECEF);
        textColor = Colors.grey;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    );
  }
}