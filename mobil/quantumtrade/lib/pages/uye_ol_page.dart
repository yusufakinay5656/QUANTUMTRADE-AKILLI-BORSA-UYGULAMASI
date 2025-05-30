import 'package:flutter/material.dart';

class UyeOlPage extends StatelessWidget {
  const UyeOlPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage('assets/images/logo.jpg'),
              radius: 30,
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QuantumTrade',
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '"The world is yours"',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          _navItem("Ana Sayfa", onTap: () => Navigator.pushNamed(context, '/')),
          _navItem("Piyasa", onTap: () => Navigator.pushNamed(context, '/piyasa')),
          _navItem("Profilim", onTap: () => Navigator.pushNamed(context, '/profilim')),
          _navItem("AI Asistan", onTap: () => Navigator.pushNamed(context, '/ai-asistan')),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Hızlı Üye Ol',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildTextField('İsim'),
            _buildTextField('Soyisim'),
            _buildTextField('Kullanıcı Adı'),
            _buildTextField('E-posta', inputType: TextInputType.emailAddress),
            _buildTextField('Şifre', isPassword: true),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Kayıt işlemi yapılabilir
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Kaydol',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(15),
        decoration: const BoxDecoration(
          color: Color(0xFF111111),
          border: Border(top: BorderSide(color: Color(0xFFFFD700))),
        ),
        child: const Text(
          "© 2025 QuantumTrade • Tüm Hakları Saklıdır",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _navItem(String title, {bool active = false, VoidCallback? onTap}) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        title,
        style: TextStyle(
          color: active ? Colors.white : const Color(0xFFFFD700),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTextField(String hint,
      {bool isPassword = false, TextInputType inputType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        obscureText: isPassword,
        keyboardType: inputType,
        style: const TextStyle(color: Color(0xFFFFD700)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: const Color(0xFF111111),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF444444)),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFFFFD700)),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

