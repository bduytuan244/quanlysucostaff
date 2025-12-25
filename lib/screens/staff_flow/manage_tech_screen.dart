import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart'; // Đảm bảo đã thêm url_launcher vào pubspec.yaml
import '../../models/user_model.dart';

class ManageTechScreen extends StatefulWidget {
  const ManageTechScreen({super.key});

  @override
  State<ManageTechScreen> createState() => _ManageTechScreenState();
}

class _ManageTechScreenState extends State<ManageTechScreen> {

  // 1. Hàm bật/tắt tài khoản (Có kiểm tra mounted để tránh lỗi)
  Future<void> _toggleUserStatus(String docId, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(docId).update({
        'isActive': !currentStatus,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(currentStatus ? "Đã khóa tài khoản này!" : "Đã mở khóa tài khoản!"),
            duration: const Duration(seconds: 1),
            backgroundColor: currentStatus ? Colors.red : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      }
    }
  }

  // 2. Hàm gọi điện (Tách riêng ra cho gọn)
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw 'Could not launch $launchUri';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          // Lưu ý: Trên máy ảo Android Studio, nó sẽ mở app Điện thoại ảo lên chứ không gọi thực được.
          const SnackBar(content: Text("Không thể mở trình gọi điện (Lỗi do máy ảo hoặc chưa cấp quyền)")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý nhân sự"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'technician') // Chỉ lấy nhân viên
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Chưa có nhân viên nào."));
          }

          final documents = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final data = documents[index].data() as Map<String, dynamic>;
              final user = UserModel.fromMap(data, documents[index].id);

              // Lấy SĐT an toàn (nếu DB chưa có thì dùng số giả định)
              final String phoneNumber = data['phone'] ?? '0909123456';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  // Bỏ onTap ở đây để tránh bấm nhầm
                  leading: CircleAvatar(
                    backgroundColor: user.isActive ? Colors.green : Colors.grey,
                    child: Icon(
                      user.isActive ? Icons.check : Icons.block,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    user.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: user.isActive ? null : TextDecoration.lineThrough,
                      color: user.isActive ? Colors.black : Colors.grey,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.email),
                      // Hiển thị SĐT ra đây
                      Text("SĐT: $phoneNumber", style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                    ],
                  ),

                  // --- PHẦN QUAN TRỌNG: TRAILING CHỨA 2 NÚT ---
                  trailing: SizedBox(
                    width: 120, // Cần đặt chiều rộng cố định để Row không chiếm hết chỗ
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Nút Gọi Điện
                        IconButton(
                          icon: const Icon(Icons.phone, color: Colors.blue),
                          tooltip: "Gọi cho nhân viên",
                          onPressed: () => _makePhoneCall(phoneNumber),
                        ),
                        // Nút Switch Khóa/Mở
                        Transform.scale(
                          scale: 0.8, // Thu nhỏ nút Switch lại chút
                          child: Switch(
                            value: user.isActive,
                            activeColor: Colors.green,
                            inactiveThumbColor: Colors.red,
                            onChanged: (value) {
                              _toggleUserStatus(user.id, user.isActive);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}