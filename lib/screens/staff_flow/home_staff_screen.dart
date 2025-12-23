import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../../models/incident_model.dart';
import 'manage_tech_screen.dart';

class HomeStaffScreen extends StatefulWidget {
  const HomeStaffScreen({super.key});

  @override
  State<HomeStaffScreen> createState() => _HomeStaffScreenState();
}

class _HomeStaffScreenState extends State<HomeStaffScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Resolved': return Colors.green;
      case 'Processing': return Colors.blue;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bàn Quản Lý"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.manage_accounts),
            tooltip: "Quản Lý nhân viên",
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageTechScreen()),
              );
            },
          ),

        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Mới"),
            Tab(text: "Đang sửa"),
            Tab(text: 'Lịch sử'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListByStatus('Pending'),
          _buildListByStatus('Processing'),
          _buildListByStatus('Resolved'),
        ],
      ),
    );
  }

  Widget _buildListByStatus(String filterStatus) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('incidents')
          .where('status', isEqualTo: filterStatus)
          .snapshots(),
      builder: (context, snapshot){
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inbox, size: 50, color: Colors.grey),
                Text("Không có đơn nào ở mục $filterStatus"),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final incident = IncidentModel.fromMap(data, docs[index].id);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: incident.imageUrl.isNotEmpty && !incident.imageUrl.startsWith('http')
                              ? Image.memory(
                                  base64Decode(incident.imageUrl),
                                  width: 70, height: 70, fit: BoxFit.cover,
                                  errorBuilder: (_,__,___) => Container(width: 70, height: 70, color: Colors.grey, child: const Icon(Icons.error)),
                                )
                              : Container(width: 70, height: 70, color: Colors.grey[300], child: const Icon(Icons.image)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                incident.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),

                              ),
                              const SizedBox(height: 4),
                              Text(" ${incident.location}", style: const TextStyle(color: Colors.grey)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.blue.shade200)
                                ),
                                child: Text(
                                  incident.category,
                                  style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Mô tả: ${incident.description}",
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}