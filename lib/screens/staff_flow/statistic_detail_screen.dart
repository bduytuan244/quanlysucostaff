import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../models/incident_model.dart';
import 'staff_incident_view.dart';

class StatisticDetailScreen extends StatelessWidget {
  final String title;
  final String filterType;
  final List<QueryDocumentSnapshot> allDocs;

  const StatisticDetailScreen({
    super.key,
    required this.title,
    required this.filterType,
    required this.allDocs,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);
    final int currentQuarter = ((now.month - 1) / 3).floor() + 1;
    final startOfQuarter = DateTime(now.year, (currentQuarter - 1) * 3 + 1, 1);

    final filteredDocs = allDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;

      DateTime? date;
      final dynamic rawTs = data['timestamp'];
      if (rawTs is Timestamp) date = rawTs.toDate();
      else if (rawTs is int) date = DateTime.fromMillisecondsSinceEpoch(rawTs);

      if (date == null) return false;

      switch (filterType) {
        case 'today': return date.isAfter(startOfDay);
        case 'week': return date.isAfter(startOfWeek);
        case 'month': return date.isAfter(startOfMonth);
        case 'quarter': return date.isAfter(startOfQuarter);
        default: return false;
      }
    }).toList();

    filteredDocs.sort((a, b) {
      final d1 = a.data() as Map<String, dynamic>;
      final d2 = b.data() as Map<String, dynamic>;
      int getMillis(dynamic raw) => (raw is Timestamp) ? raw.millisecondsSinceEpoch : (raw is int ? raw : 0);
      return getMillis(d2['timestamp']).compareTo(getMillis(d1['timestamp']));
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: filteredDocs.isEmpty
          ? const Center(child: Text("Không có đơn nào trong khoảng thời gian này"))
          : ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: filteredDocs.length,
        itemBuilder: (context, index) {
          final doc = filteredDocs[index];
          final data = doc.data() as Map<String, dynamic>;
          final incident = IncidentModel.fromMap(data, doc.id);

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: const EdgeInsets.all(10),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: incident.imageUrl.isNotEmpty && !incident.imageUrl.startsWith('http')
                    ? Image.memory(base64Decode(incident.imageUrl), width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (_,__,___)=>const Icon(Icons.error))
                    : Container(width: 60, height: 60, color: Colors.grey[300], child: const Icon(Icons.image)),
              ),
              title: Text(incident.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("📍 ${incident.location}"),
                  Text(DateFormat('HH:mm dd/MM/yyyy').format(incident.timestamp), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: incident.status == 'Resolved' ? Colors.green[50] : Colors.blue[50],
                        borderRadius: BorderRadius.circular(4)
                    ),
                    child: Text(
                        incident.status == 'Resolved' ? 'Đã xong' : (incident.status == 'Processing' ? 'Đang sửa' : 'Mới'),
                        style: TextStyle(
                            fontSize: 10,
                            color: incident.status == 'Resolved' ? Colors.green : Colors.blue
                        )
                    ),
                  )
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StaffIncidentView(
                      incidentId: incident.id,
                      isEditable: false,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}