import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StaffIncidentView extends StatelessWidget {
  final String incidentId;
  final bool isEditable;

  const StaffIncidentView({
    super.key,
    required this.incidentId,
    this.isEditable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditable ? "Xử lý sự cố" : "Chi tiết lịch sử"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('incidents').doc(incidentId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var data = snapshot.data!.data() as Map<String, dynamic>;

          bool isCheckedIn = data['checkInTime'] != null;
          String checkInInfo = "Chưa check-in";
          if (isCheckedIn) {
            DateTime dt;
            if (data['checkInTime'] is Timestamp) {
              dt = (data['checkInTime'] as Timestamp).toDate();
            } else {
              dt = DateTime.fromMillisecondsSinceEpoch(data['checkInTime']);
            }
            checkInInfo = DateFormat('HH:mm dd/MM/yyyy').format(dt);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['title'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.grey, size: 20),
                    const SizedBox(width: 5),
                    Text(data['location'] ?? '', style: const TextStyle(fontSize: 16)),
                  ],
                ),
                const Divider(height: 30),

                const Text("📍 TRẠNG THÁI HIỆN TRƯỜNG", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCheckedIn ? Colors.blue[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isCheckedIn ? Colors.blue : Colors.orange),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer, color: isCheckedIn ? Colors.blue : Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isCheckedIn ? "Nhân viên đã có mặt" : "Chưa đến hiện trường",
                                style: TextStyle(fontWeight: FontWeight.bold, color: isCheckedIn ? Colors.blue[800] : Colors.deepOrange)),
                            if (isCheckedIn)
                              Text("Thời gian: $checkInInfo", style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const Divider(height: 30),

                const Text("🛠️ VẬT TƯ YÊU CẦU", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
                const SizedBox(height: 10),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('incidents')
                      .doc(incidentId)
                      .collection('materials')
                      .snapshots(),
                  builder: (context, matSnapshot) {
                    if (matSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!matSnapshot.hasData || matSnapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text("Không có yêu cầu vật tư nào.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                        ),
                      );
                    }

                    var materials = matSnapshot.data!.docs;
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: materials.length,
                      itemBuilder: (context, index) {
                        var mat = materials[index].data() as Map<String, dynamic>;
                        String status = mat['status'] ?? 'Pending';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal.shade100,
                              child: Text("${mat['quantity']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                            ),
                            title: Text(mat['name'] ?? 'Vật tư', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(status == 'Approved' ? "Đã duyệt" : "Đang chờ duyệt..."),

                            trailing: status == 'Pending'
                                ? (isEditable
                                ? ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                              onPressed: () {
                                materials[index].reference.update({'status': 'Approved'});
                              },
                              child: const Text("Duyệt"),
                            )
                                : const Text("Chờ duyệt", style: TextStyle(color: Colors.orange, fontStyle: FontStyle.italic))) // Nếu không thì hiện chữ
                                : const Icon(Icons.check_circle, color: Colors.green),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}