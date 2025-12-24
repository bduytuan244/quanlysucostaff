import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import 'package:url_launcher/url_launcher.dart';

class ManageTechScreen extends StatefulWidget {
  const ManageTechScreen({super.key});

  @override
  State<ManageTechScreen> createState() => _ManageTechScreenState();
}

class _ManageTechScreenState extends State<ManageTechScreen> {
  Future<void> _toggleUserStatus(String docId, bool currentStatus) async {
    await FirebaseFirestore.instance.collection('users').doc(docId).update({'isActive': !currentStatus,});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(currentStatus ? "Đã khóa tài khoản này!": "Đã mở khóa tài khoản!"),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý nhân sự"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'technician')
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
            itemBuilder: (context, index){
              final data = documents[index].data() as Map<String, dynamic>;
              final user = UserModel.fromMap(data, documents[index].id);

              return Card(
                elevation: 2,
                margin:  const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  onTap: () async {
                    // Giả sử trong DB bạn đã lưu trường 'phone'. Nếu chưa có thì lấy số mẫu.
                    final phoneNumber = "0909123456"; // Hoặc: user.phone
                    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);

                    if (await canLaunchUrl(launchUri)) {
                      await launchUrl(launchUri);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Không thể thực hiện cuộc gọi")));
                    }
                  },
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
                  subtitle: Text(user.email),
                  trailing: Switch(value: user.isActive, activeColor: Colors.green, inactiveThumbColor: Colors.red, onChanged: (value){ _toggleUserStatus(user.id, user.isActive);
                    },),
                ),
              );
            },
          );
        },
      ),
    );
  }
}