import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'homepage.dart';
import 'Staffhomepage.dart';
import 'Register.dart';
import 'ForgotPasswordScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isUser = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F1FF),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 25),
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1D61FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_outline,
                      color: Colors.white, size: 40),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Эмнэлгийн Систем',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2B47)),
                ),
                const Text('Нэвтрэх',
                    style: TextStyle(color: Colors.grey, fontSize: 16)),
                const SizedBox(height: 30),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9ECEF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => isUser = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isUser ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: isUser
                                  ? [
                                      BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.1),
                                          blurRadius: 4)
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: const Text('Үйлчлүүлэгч',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => isUser = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color:
                                  !isUser ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: !isUser
                                  ? [
                                      BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.1),
                                          blurRadius: 4)
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: const Text('Дотоод ажилтан',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                _buildInputField(
                  label: 'Нэвтрэх нэр',
                  icon: Icons.person_outline,
                  hint: 'Нэвтрэх нэр',
                  controller: _emailController,
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  label: 'Нууц үг',
                  icon: Icons.lock_outline,
                  hint: 'Нууц үг',
                  isPassword: true,
                  controller: _passwordController,
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D61FF),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Нэвтрэх',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ForgotPasswordScreen(isStaff: !isUser),
                      ),
                    );
                  },
                  child: const Text(
                    'Нууц үгээ мартсан уу?',
                    style: TextStyle(
                        color: Color(0xFFFF6B35),
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Бүртгэлгүй юу? '),
                    TextButton(
                      onPressed: _goToRegister,
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: const Text(
                        'Бүртгүүлэх',
                        style: TextStyle(
                            color: Color(0xFF1D61FF),
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 40, thickness: 0.5),
                const Text(
                  'Туршилтын хувьд:\nDemo үйлчлүүлэгч: demo1 / demo123\nДотоод ажилтан: admin1 / admin123',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: Colors.grey, fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegisterScreen()),
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Мэдээллээ бүрэн оруулна уу')),
      );
      return;
    }

    try {
      // Нэвтрэх нэрийг email болгох
      final fakeEmail = email.contains('@') ? email : '$email@hospital.mn';
      final response = await Supabase.instance.client.auth
          .signInWithPassword(email: fakeEmail, password: password);

      if (!mounted) return;

      if (response.user != null) {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('role')
            .eq('id', response.user!.id)
            .single();

        final role = profile['role'];
        if (!mounted) return;

        // Сонгосон tab болон бүртгэлийн role тохирч байгаа эсэхийг шалгах
        final bool isStaff = role == 'staff';
        final bool isPatient = role == 'patient';

        if (isUser && isStaff) {
          // Үйлчлүүлэгч tab сонгосон боловч дотоод ажилтан account
          await Supabase.instance.client.auth.signOut();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Энэ бүртгэл дотоод ажилтанд зориулагдсан байна. "Дотоод ажилтан" tab-г сонгож нэвтэрнэ үү.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
          return;
        }

        if (!isUser && isPatient) {
          // Дотоод ажилтан tab сонгосон боловч үйлчлүүлэгч account
          await Supabase.instance.client.auth.signOut();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Энэ бүртгэл үйлчлүүлэгчид зориулагдсан байна. "Үйлчлүүлэгч" tab-г сонгож нэвтэрнэ үү.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
          return;
        }

        if (isStaff) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => StaffHomeScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Алдаа: ${e.toString()}')),
      );
    }
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required String hint,
    bool isPassword = false,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            prefixIcon: Icon(icon, color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFFF1F3F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ],
    );
  }
}