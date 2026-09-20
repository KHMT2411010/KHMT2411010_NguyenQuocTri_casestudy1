import 'package:flutter/material.dart';

void main() {
  runApp(const ExpenseManagerApp());
}

class ExpenseManagerApp extends StatelessWidget {
  const ExpenseManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Expense Manager',
      theme: ThemeData(
        fontFamily: 'Arial',
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [
              // Nội dung chính
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ICON VÍ
                    const WalletIcon(),

                    const SizedBox(height: 20),

                    // TIÊU ĐỀ
                    const Text(
                      'Expense Manager',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF142238),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // MÔ TẢ
                    const Text(
                      'Quản lý chi tiêu cá nhân\nđơn giản và hiệu quả',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: Color(0xFF8A9AAF),
                      ),
                    ),
                  ],
                ),
              ),

              // NÚT BẮT ĐẦU
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Chuyển sang màn hình chính
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2176C9),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    child: const Text(
                      'Bắt đầu',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================
// ICON CÁI VÍ
// ==========================

class WalletIcon extends StatelessWidget {
  const WalletIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 90,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Tờ tiền phía sau
          Positioned(
            top: 5,
            left: 32,
            child: Container(
              width: 63,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFF77C47F),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),

          // Tờ tiền nhỏ phía sau
          Positioned(
            top: 14,
            left: 25,
            child: Container(
              width: 67,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF48B35A),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),

          // Thân ví
          Positioned(
            bottom: 5,
            child: Container(
              width: 102,
              height: 62,
              decoration: BoxDecoration(
                color: const Color(0xFF2176C9),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),

          // Miếng khóa ví
          Positioned(
            right: 0,
            bottom: 24,
            child: Container(
              width: 39,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF1258A5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: CircleAvatar(
                  radius: 5.5,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}