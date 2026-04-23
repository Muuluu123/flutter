import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppointmentHistoryScreen extends StatefulWidget {
  const AppointmentHistoryScreen({super.key});

  @override
  State<AppointmentHistoryScreen> createState() =>
      _AppointmentHistoryScreenState();
}

class _AppointmentHistoryScreenState extends State<AppointmentHistoryScreen> {
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
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final patientData = await Supabase.instance.client
          .from('patients')
          .select('id')
          .eq('profile_id', user.id)
          .single();

      final data = await Supabase.instance.client
          .from('appointments')
          .select()
          .eq('patient_id', patientData['id'])
          .order('appointment_date', ascending: false);

      setState(() {
        _appointments = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelAppointment(String appointmentId) async {
    // Баталгаажуулах dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Цаг цуцлах',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Та энэ цагийг цуцлахдаа итгэлтэй байна уу?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Үгүй', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Тийм, цуцлах',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await Supabase.instance.client
          .from('appointments')
          .update({'status': 'cancelled'}).eq('id', appointmentId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Цаг амжилттай цуцлагдлаа'),
          backgroundColor: Colors.orange,
        ),
      );
      _loadAppointments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Алдаа: ${e.toString()}')),
      );
    }
  }

  // Notes-оос тасаг, эмч, шалтгааныг задлах
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

  String _formatDateTime(String isoString) {
    final dt = DateTime.parse(isoString).toLocal();
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min - ${dt.year}/${dt.month}/${dt.day}';
  }

  String _formatDay(String isoString) {
    final dt = DateTime.parse(isoString).toLocal();
    return '${dt.month}/${dt.day}';
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'pending':
        bgColor = const Color(0xFFFFF3CD);
        textColor = const Color(0xFF856404);
        label = 'Хүлээгдэж байна';
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
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: textColor, fontSize: 12, fontWeight: FontWeight.w600)),
    );
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
        title: const Row(
          children: [
            Icon(Icons.description_rounded, color: Color(0xFF22C55E)),
            SizedBox(width: 8),
            Text(
              'Цаг авалтын түүх',
              style: TextStyle(
                  color: Color(0xFF1A2B47), fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1D61FF)))
          : _appointments.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 60, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Цаг захиалга байхгүй байна',
                          style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAppointments,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _appointments.length,
                    itemBuilder: (context, index) {
                      final appt = _appointments[index];
                      final notes = _parseNotes(appt['notes']);
                      final status = appt['status'] ?? 'pending';
                      final canCancel =
                          status == 'pending' || status == 'confirmed';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Огноо хайрцаг
                            Container(
                              width: 56,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.calendar_month_rounded,
                                      color: Color(0xFF1D61FF), size: 22),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDay(appt['appointment_date']),
                                    style: const TextStyle(
                                      color: Color(0xFF1D61FF),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        notes['department'] ??
                                            'Тасаг тодорхойгүй',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFF1A2B47),
                                        ),
                                      ),
                                      _buildStatusBadge(status),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  // Цаг
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time,
                                          size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDateTime(
                                            appt['appointment_date']),
                                        style: const TextStyle(
                                            color: Colors.grey, fontSize: 13),
                                      ),
                                    ],
                                  ),

                                  // Эмч
                                  if (notes['doctor'] != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.person_outline,
                                            size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          notes['doctor']!,
                                          style: const TextStyle(
                                              color: Colors.grey, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ],

                                  // Шалтгаан
                                  if (notes['reason'] != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.description_outlined,
                                            size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            notes['reason']!,
                                            style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],

                                  // Цуцлах товч — зөвхөн pending/confirmed үед
                                  if (canCancel) ...[
                                    const SizedBox(height: 10),
                                    GestureDetector(
                                      onTap: () =>
                                          _cancelAppointment(appt['id']),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.red.shade300),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.cancel_outlined,
                                                size: 16,
                                                color: Colors.red.shade400),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Цуцлах',
                                              style: TextStyle(
                                                color: Colors.red.shade400,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
