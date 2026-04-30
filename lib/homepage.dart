import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';
import 'AppointmentScreen.dart';
import 'AppointmentHistoryScreen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title:
            const Text('Гарах', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Та гарахдаа итгэлтэй байна уу?'),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Тийм',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Үгүй', style: TextStyle(color: Colors.grey)),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );

    if (confirm != true) return;
    await Supabase.instance.client.auth.signOut();
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F1FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // Дээд хэсэг
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1D61FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite,
                            color: Colors.white, size: 30),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Эмнэлгийн\nсонголт',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A2B47),
                        ),
                      ),
                    ],
                  ),
                  // Гарах товч
                  IconButton(
                    icon: const Icon(Icons.logout_rounded,
                        color: Color(0xFF1D61FF), size: 28),
                    onPressed: () => _confirmLogout(context),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Цаг захиалах
              _buildMenuCard(
                context,
                icon: Icons.calendar_month_rounded,
                label: 'Цаг захиалах',
                color: const Color(0xFF1D61FF),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AppointmentScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Цаг авалтын түүх
              _buildMenuCard(
                context,
                icon: Icons.description_rounded,
                label: 'Цаг авалтын түүх',
                color: const Color(0xFF22C55E),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => AppointmentHistoryScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 50),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 60),
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
