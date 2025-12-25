import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'statistic_detail_screen.dart';
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  // Màu sắc cho biểu đồ tròn
  final Map<String, Color> categoryColors = {
    'Hệ thống Điện': Colors.amber,
    'Hệ thống Nước': Colors.blue,
    'Internet / Mạng': Colors.purple,
    'Cơ sở vật chất': Colors.brown,
    'Điều hòa / Tủ lạnh': Colors.cyan,
    'Xe cộ': Colors.red,
    'Khác': Colors.grey,
  };

  int _todayCount = 0;
  int _weekCount = 0;
  int _monthCount = 0;
  int _quarterCount = 0;

  // Hàm tính toán số liệu theo thời gian
  void _calculateTimeStats(List<QueryDocumentSnapshot> docs) {
    final now = DateTime.now();

    // 1. Xác định mốc thời gian
    final startOfDay = DateTime(now.year, now.month, now.day);

    // Đầu tuần (Thứ 2)
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekClean = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    // Đầu tháng
    final startOfMonth = DateTime(now.year, now.month, 1);

    // Đầu quý
    // Quý 1: T1-T3, Quý 2: T4-T6...
    final int currentQuarter = ((now.month - 1) / 3).floor() + 1;
    final startOfQuarter = DateTime(now.year, (currentQuarter - 1) * 3 + 1, 1);

    int d = 0, w = 0, m = 0, q = 0;

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      // --- ĐOẠN SỬA LỖI QUAN TRỌNG ---
      DateTime? date;
      final dynamic rawTs = data['timestamp']; // Lấy dữ liệu thô (dynamic)

      if (rawTs is Timestamp) {
        date = rawTs.toDate(); // Nếu là Timestamp thì đổi sang Date
      } else if (rawTs is int) {
        date = DateTime.fromMillisecondsSinceEpoch(rawTs); // Nếu là số Int thì đổi từ mili-giây
      }
      // -------------------------------

      if (date != null) {
        if (date.isAfter(startOfDay)) d++;
        if (date.isAfter(startOfWeekClean)) w++;
        if (date.isAfter(startOfMonth)) m++;
        if (date.isAfter(startOfQuarter)) q++;
      }
    }

    // Cập nhật giao diện một lần duy nhất sau khi tính toán xong
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _todayCount = d;
          _weekCount = w;
          _monthCount = m;
          _quarterCount = q;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thống kê & Báo cáo"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('incidents').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("Chưa có dữ liệu thống kê"));

          // Gọi hàm tính toán số liệu thời gian
          // Lưu ý: Đặt trong Future để tránh lỗi build lại liên tục
          _calculateTimeStats(docs);

          // --- 1. TÍNH TOÁN BIỂU ĐỒ TRÒN ---
          Map<String, int> catCounts = {};
          for (var doc in docs) {
            String cat = (doc.data() as Map<String, dynamic>)['category'] ?? 'Khác';
            catCounts[cat] = (catCounts[cat] ?? 0) + 1;
          }

          List<PieChartSectionData> sections = [];
          catCounts.forEach((key, value) {
            if (value > 0) {
              final percentage = (value / docs.length * 100).toStringAsFixed(1);
              sections.add(
                PieChartSectionData(
                  color: categoryColors[key] ?? Colors.grey,
                  value: value.toDouble(),
                  title: '$percentage%',
                  radius: 50,
                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              );
            }
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Tổng quan hoạt động", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),

                // --- 2. GRIDVIEW HIỂN THỊ 4 Ô THỐNG KÊ ---
                GridView.count(
                  crossAxisCount: 2, // 2 cột
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  shrinkWrap: true, // Quan trọng để nằm trong ScrollView
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.2, // Tỷ lệ chiều rộng/cao
                  children: [
                    _buildStatCard("Hôm nay", _todayCount, Colors.orange, Icons.today, "today", docs),
                    _buildStatCard("Tuần này", _weekCount, Colors.blue, Icons.calendar_view_week, "week", docs),
                    _buildStatCard("Tháng này", _monthCount, Colors.green, Icons.calendar_month, "month", docs),
                    _buildStatCard("Quý này", _quarterCount, Colors.purple, Icons.pie_chart, "quarter", docs),
                  ],
                ),

                const SizedBox(height: 30),
                const Divider(),
                const SizedBox(height: 20),

                const Text("Tỷ lệ loại sự cố (Tất cả)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                // --- 3. BIỂU ĐỒ TRÒN ---
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                // Chú thích
                Column(
                  children: catCounts.entries.map((entry) {
                    return ListTile(
                      dense: true,
                      leading: Container(
                        width: 15, height: 15,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: categoryColors[entry.key] ?? Colors.grey),
                      ),
                      title: Text(entry.key),
                      trailing: Text("${entry.value} đơn", style: const TextStyle(fontWeight: FontWeight.bold)),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget vẽ thẻ thống kê nhỏ
  // Cập nhật tham số nhận vào
  Widget _buildStatCard(
      String title,
      int count,
      Color color,
      IconData icon,
      String filterType, // Mới: Loại lọc
      List<QueryDocumentSnapshot> docs // Mới: Danh sách dữ liệu
      ) {
    return GestureDetector( // Bọc bằng GestureDetector để bắt sự kiện bấm
      onTap: () {
        // Chuyển sang màn hình chi tiết
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StatisticDetailScreen(
              title: "Chi tiết: $title",
              filterType: filterType,
              allDocs: docs, // Truyền toàn bộ dữ liệu sang để bên kia tự lọc
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                  "$count",
                  style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)
              ),
            ),
            const Text("đơn", style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}