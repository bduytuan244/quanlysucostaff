import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import để format ngày tháng
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
  DateTime? _selectedDate; // Biến lưu ngày được chọn

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.toLowerCase();
      });
    });
  }

  // Hàm chọn ngày
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'CHỌN NGÀY CẦN XEM',
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Hàm xóa lọc ngày
  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
    });
  }

  // Hàm cập nhật trạng thái
  Future<void> _updateStatus(String docId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('incidents').doc(docId).update({'status': newStatus});
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã cập nhật: $newStatus")));
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      }
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
          // --- 1. NÚT CHỌN NGÀY ---
          IconButton(
            icon: Icon(_selectedDate == null ? Icons.calendar_month : Icons.event_available),
            color: _selectedDate == null ? Colors.white : Colors.yellowAccent, // Vàng nếu đang lọc
            tooltip: "Lọc theo ngày",
            onPressed: _pickDate,
          ),

          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: "Xem thống kê",
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const StatisticsScreen()));
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

        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_selectedDate != null ? 140 : 110), // Tăng chiều cao nếu đang hiện ngày lọc
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Tìm tên thiết bị, vị trí...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                  ),
                ),
              ),

              // --- 2. HIỂN THỊ NGÀY ĐANG LỌC (NẾU CÓ) ---
              if (_selectedDate != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: Colors.teal.shade700, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.filter_list, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          "Đang lọc ngày: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _clearDateFilter,
                          child: const Icon(Icons.close, color: Colors.yellowAccent, size: 20),
                        )
                      ],
                    ),
                  ),
                ),

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
      // .orderBy('timestamp', descending: true) // Tạm bỏ order trên server để client tự lọc cho dễ
          .snapshots(),
      builder: (context, snapshot){
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _emptyView(filterStatus);
        }

        final allDocs = snapshot.data!.docs;

        // --- 3. LOGIC LỌC DỮ LIỆU (SEARCH + DATE) ---
        final filteredDocs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          final title = (data['title'] ?? '').toString().toLowerCase();
          final location = (data['location'] ?? '').toString().toLowerCase();
          final matchesSearch = _searchText.isEmpty || title.contains(_searchText) || location.contains(_searchText);

          bool matchesDate = true;
          if (_selectedDate != null) {
            // --- XỬ LÝ NGÀY THÁNG AN TOÀN ---
            DateTime? dt;
            final dynamic rawTs = data['timestamp'];

            if (rawTs is Timestamp) {
              dt = rawTs.toDate();
            } else if (rawTs is int) {
              dt = DateTime.fromMillisecondsSinceEpoch(rawTs);
            }

            if (dt != null) {
              matchesDate = dt.year == _selectedDate!.year &&
                  dt.month == _selectedDate!.month &&
                  dt.day == _selectedDate!.day;
            } else {
              matchesDate = false;
            }
          }

          return matchesSearch && matchesDate;
        }).toList();

        // Sắp xếp giảm dần theo thời gian (Mới nhất lên đầu) - Client side sorting
        filteredDocs.sort((a, b) {
          final d1 = a.data() as Map<String, dynamic>;
          final d2 = b.data() as Map<String, dynamic>;

          // Hàm phụ để lấy milliseconds từ mọi loại dữ liệu
          int getMillis(dynamic raw) {
            if (raw is Timestamp) return raw.millisecondsSinceEpoch;
            if (raw is int) return raw;
            return 0;
          }

          int t1 = getMillis(d1['timestamp']);
          int t2 = getMillis(d2['timestamp']);

          return t2.compareTo(t1); // So sánh số nguyên (milliseconds)
        });
        if (filteredDocs.isEmpty) {
          return const Center(child: Text("Không tìm thấy đơn nào phù hợp"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: filteredDocs.length,
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
                              ? Image.memory(base64Decode(incident.imageUrl), width: 70, height: 70, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(width: 70, height: 70, color: Colors.grey))
                              : Container(width: 70, height: 70, color: Colors.grey[300], child: const Icon(Icons.image)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(incident.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text("📍 ${incident.location}", style: const TextStyle(color: Colors.grey)),
                              const SizedBox(height: 4),
                              // Hiển thị ngày giờ
                              Text(DateFormat('HH:mm dd/MM/yyyy').format(incident.timestamp), style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.blue.shade200)),
                      child: Text(incident.category, style: TextStyle(fontSize: 12, color: Colors.blue.shade800)),
                    ),
                    const SizedBox(height: 4),
                    Text("Mô tả: ${incident.description}", maxLines: 2, overflow: TextOverflow.ellipsis),

                    const SizedBox(height: 10),
                    if (filterStatus == 'Pending')
                      SizedBox(width: double.infinity, child: ElevatedButton.icon(
                        onPressed: () => _updateStatus(incident.id, 'Processing'),
                        icon: const Icon(Icons.play_arrow), label: const Text("TIẾP NHẬN"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                      )),

                    if (filterStatus == 'Processing')
                      SizedBox(width: double.infinity, child: ElevatedButton.icon(
                        onPressed: () => _updateStatus(incident.id, 'Resolved'),
                        icon: const Icon(Icons.check_circle), label: const Text("HOÀN THÀNH (ADMIN)"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      )),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _emptyView(String status) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox, size: 50, color: Colors.grey),
          Text("Không có đơn nào ở mục $status"),
        ],
      ),
    );
  }
}