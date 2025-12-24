import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../../models/incident_model.dart';
import 'manage_tech_screen.dart';
import 'statistics_screen.dart';

class HomeStaffScreen extends StatefulWidget {
  const HomeStaffScreen({super.key});

  @override
  State<HomeStaffScreen> createState() => _HomeStaffScreenState();
}

class _HomeStaffScreenState extends State<HomeStaffScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Lắng nghe thay đổi khi gõ phím để cập nhật biến _searchText
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.toLowerCase();
      });
    });
  }

  // Hàm cập nhật trạng thái đơn hàng
  Future<void> _updateStatus(String docId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('incidents')
          .doc(docId)
          .update({'status': newStatus});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đã cập nhật: $newStatus")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ban Quản Lý"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: "Xem thống kê",
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StatisticsScreen())
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.manage_accounts),
            tooltip: "Quản Lý nhân viên",
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageTechScreen()));
            },
          ),
        ],

        // --- NÂNG CẤP: THÊM Ô TÌM KIẾM VÀO APPBAR ---
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110), // Tăng chiều cao để chứa cả Search và Tab
          child: Column(
            children: [
              // Ô NHẬP LIỆU TÌM KIẾM
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Tìm theo tên hoặc vị trí...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              // THANH TAB GIỮ NGUYÊN
              TabBar(
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
            ],
          ),
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

        // --- NÂNG CẤP: LOGIC LỌC DỮ LIỆU ---
        final allDocs = snapshot.data!.docs;

        // Lọc danh sách dựa trên từ khóa tìm kiếm
        final filteredDocs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final title = (data['title'] ?? '').toString().toLowerCase();
          final location = (data['location'] ?? '').toString().toLowerCase();

          // Logic: Nếu ô tìm kiếm trống HOẶC tên chứa từ khóa HOẶC vị trí chứa từ khóa
          return _searchText.isEmpty || title.contains(_searchText) || location.contains(_searchText);
        }).toList();

        // Nếu lọc xong mà không còn đơn nào
        if (filteredDocs.isEmpty) {
          return const Center(child: Text("Không tìm thấy kết quả phù hợp"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: filteredDocs.length, // Sử dụng danh sách đã lọc (filteredDocs)
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            final incident = IncidentModel.fromMap(data, doc.id);

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
                              Text("📍 ${incident.location}", style: const TextStyle(color: Colors.grey)),
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

                    // --- NÚT BẤM ---
                    const SizedBox(height: 10),
                    if (filterStatus == 'Pending')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _updateStatus(incident.id, 'Processing');
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text("TIẾP NHẬN XỬ LÝ"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),

                    if (filterStatus == 'Processing')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _updateStatus(incident.id, 'Resolved');
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text("HOÀN THÀNH"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
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