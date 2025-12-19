import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/incident_model.dart';
import 'create_report_screen.dart';

class HomeUserScreen extends StatefulWidget{
  const HomeUserScreen({super.key});

  @override
  State<HomeUserScreen> createState() => _HomeUserScreenState();
}

class _HomeUserScreenState extends State<HomeUserScreen> {
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Resolved':
      case 'Done':
        return Colors.green;
      case 'Processing':
        return Colors.blue;
      case 'Pending':
      default:
        return Colors.orange;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'Resolved':
        return 'Đã xử lý';
      case 'Processing':
        return 'Đang sửa';
      case 'Pending':
        return 'Chờ tiếp nhận';
      case 'Closed':
        return 'Đã đóng';
      default:
        return 'Mới';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lịch sử báo cáo"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream:  FirebaseFirestore.instance
            .collection('incidents')
            .orderBy('timestamp', descending: true)
            .snapshots(),

        builder: (context, snapshot){
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 60, color: Colors.grey),
                  Text("Bạn chưa gửi yêu cầu nào"),
                ],
              ),
            );
          }

          final documents = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: documents.length,
            itemBuilder: (context, index){
              final data = documents[index].data() as Map<String, dynamic>;
              final docId = documents[index].id;

              final incident = IncidentModel.fromMap(data, docId);

              String dateString = DateFormat('HH:mm - dd/MM/yyyy').format(incident.timestamp);

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: incident.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                    child: (() {
                      // Kiểm tra xem có phải ảnh Base64 không (thường rất dài và không bắt đầu bằng http)
                      if (!incident.imageUrl.startsWith('http')) {
                        try {
                          // Giải mã Base64 để hiện ảnh
                          return Image.memory(
                            base64Decode(incident.imageUrl),
                            width: 60, height: 60, fit: BoxFit.cover,
                          );
                        } catch (e) {
                          return const Icon(Icons.error);
                        }
                      } else {
                        // Trường hợp cũ (nếu có link thật)
                        return Image.network(incident.imageUrl, width: 60, height: 60, fit: BoxFit.cover);
                      }
                    })(),
                        )
                      : const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),

                  title: Text(
                    incident.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text("Vị trí: ${incident.location}"),
                      Text("Ngày: $dateString", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),

                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(incident.status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusText(incident.status),
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),

                  onTap: () {
                    //
                  },
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateReportScreen()),
          );
        },
        label: const Text("Báo hỏng"),
        icon: const Icon(Icons.add_a_photo),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }
}