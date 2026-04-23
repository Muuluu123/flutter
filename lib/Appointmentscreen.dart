import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  final TextEditingController _reasonController = TextEditingController();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedDepartment;
  String? _selectedDoctorId;
  bool _isLoading = false;
  bool _showCalendar = false;

  List<Map<String, dynamic>> _allDoctors = [];
  List<Map<String, dynamic>> _filteredDoctors = [];

  final List<String> _departments = [
    'Дотрын тасаг',
    'Мэс заслын тасаг',
    'Хүүхдийн тасаг',
    'Эмэгтэйчүүдийн тасаг',
    'Яаралтай тусламж',
    'Сэтгэцийн тасаг',
    'Зүрх судас',
    'Нүдний тасаг',
    'Шүдний тасаг',
  ];

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    try {
      final data = await Supabase.instance.client
          .from('doctors')
          .select()
          .order('department');
      setState(() {
        _allDoctors = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      // doctors хүснэгт байхгүй бол алдаа гарахгүй байх
    }
  }

  void _onDepartmentChanged(String? dept) {
    setState(() {
      _selectedDepartment = dept;
      _selectedDoctorId = null;
      _filteredDoctors =
          _allDoctors.where((d) => d['department'] == dept).toList();
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF1D61FF)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _save() async {
    if (_selectedDate == null ||
        _selectedTime == null ||
        _selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Огноо, цаг, тасгаа заавал сонгоно уу')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final patientData = await Supabase.instance.client
          .from('patients')
          .select('id')
          .eq('profile_id', user.id)
          .single();

      final appointmentDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Сонгосон эмчийн нэрийг авах
      String doctorName = '';
      if (_selectedDoctorId != null) {
        final doc = _filteredDoctors.firstWhere(
          (d) => d['id'] == _selectedDoctorId,
          orElse: () => {},
        );
        doctorName = doc['name'] ?? '';
      }

      String notes = 'Тасаг: $_selectedDepartment';
      if (doctorName.isNotEmpty) notes += '\nЭмч: $doctorName';
      if (_reasonController.text.isNotEmpty)
        notes += '\nШалтгаан: ${_reasonController.text}';

      await Supabase.instance.client.from('appointments').insert({
        'patient_id': patientData['id'],
        'appointment_date': appointmentDateTime.toIso8601String(),
        'status': 'pending',
        'notes': notes,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Цаг амжилттай захиалагдлаа!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Алдаа: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
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
            Icon(Icons.calendar_month_rounded, color: Color(0xFF1D61FF)),
            SizedBox(width: 8),
            Text('Цаг захиалах',
                style: TextStyle(
                    color: Color(0xFF1A2B47), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Огноо ──
              _buildLabel('Огноо *'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => setState(() => _showCalendar = !_showCalendar),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F3F5),
                    borderRadius: BorderRadius.circular(10),
                    border: _showCalendar
                        ? Border.all(color: const Color(0xFF1D61FF), width: 1.5)
                        : null,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: Color(0xFF1D61FF), size: 18),
                      const SizedBox(width: 10),
                      Text(
                        _selectedDate == null
                            ? 'Огноо сонгох'
                            : _formatDate(_selectedDate!),
                        style: TextStyle(
                          color: _selectedDate == null
                              ? Colors.grey
                              : const Color(0xFF1A2B47),
                          fontSize: 15,
                          fontWeight: _selectedDate != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                          _showCalendar
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.grey),
                    ],
                  ),
                ),
              ),
              if (_showCalendar) ...[
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E7FF)),
                  ),
                  child: TableCalendar(
                    firstDay: DateTime.now(),
                    lastDay: DateTime.now().add(const Duration(days: 365)),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) =>
                        isSameDay(_selectedDate, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDate = selectedDay;
                        _focusedDay = focusedDay;
                        _showCalendar = false;
                      });
                    },
                    calendarStyle: const CalendarStyle(
                      selectedDecoration: BoxDecoration(
                          color: Color(0xFF1D61FF), shape: BoxShape.circle),
                      todayDecoration: BoxDecoration(
                          color: Color(0xFFBFD0FF), shape: BoxShape.circle),
                      selectedTextStyle: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                      todayTextStyle: TextStyle(
                          color: Color(0xFF1D61FF),
                          fontWeight: FontWeight.bold),
                      weekendTextStyle: TextStyle(color: Colors.red),
                      outsideDaysVisible: false,
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                          color: Color(0xFF1A2B47),
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                      leftChevronIcon:
                          Icon(Icons.chevron_left, color: Color(0xFF1D61FF)),
                      rightChevronIcon:
                          Icon(Icons.chevron_right, color: Color(0xFF1D61FF)),
                    ),
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekdayStyle: TextStyle(
                          color: Color(0xFF1A2B47),
                          fontWeight: FontWeight.w600),
                      weekendStyle: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // ── Цаг ──
              _buildLabel('Цаг *'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickTime,
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F3F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time,
                          color: Color(0xFF1D61FF), size: 18),
                      const SizedBox(width: 10),
                      Text(
                        _selectedTime == null
                            ? 'Цаг сонгох'
                            : _selectedTime!.format(context),
                        style: TextStyle(
                          color: _selectedTime == null
                              ? Colors.grey
                              : const Color(0xFF1A2B47),
                          fontSize: 15,
                          fontWeight: _selectedTime != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Тасаг ──
              _buildLabel('Тасаг *'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDepartment,
                    isExpanded: true,
                    hint: const Text('Тасаг сонгох',
                        style: TextStyle(color: Colors.grey)),
                    items: _departments.map((dept) {
                      return DropdownMenuItem(value: dept, child: Text(dept));
                    }).toList(),
                    onChanged: _onDepartmentChanged,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Эмч — тасаг сонгосны дараа гарна ──
              if (_selectedDepartment != null) ...[
                _buildLabel('Эмч сонгох'),
                const SizedBox(height: 8),
                _filteredDoctors.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F3F5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.grey, size: 16),
                            SizedBox(width: 8),
                            Text('Тэр тасагт эмч бүртгэгдээгүй байна',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F3F5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedDoctorId,
                            isExpanded: true,
                            hint: const Text('Эмч сонгох (сонголттой)',
                                style: TextStyle(color: Colors.grey)),
                            items: _filteredDoctors.map((doc) {
                              return DropdownMenuItem<String>(
                                value: doc['id'],
                                child: Text(doc['name']),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _selectedDoctorId = val),
                          ),
                        ),
                      ),
                const SizedBox(height: 16),
              ],

              // ── Шалтгаан ──
              _buildLabel('Шалтгаан (сонголттой)'),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Үзлэгийн шалтгаан...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFF1F3F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 30),

              // ── Товчлуурууд ──
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF1D61FF)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Болих',
                          style: TextStyle(
                              color: Color(0xFF1D61FF), fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D61FF),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Хадгалах',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF1A2B47)));
  }
}
