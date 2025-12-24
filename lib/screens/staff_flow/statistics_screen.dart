import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  // Màu sắc cho từng loại lỗi
  final Map<String, Color> categoryColors = {
    'Hệ thống Điện': Colors.amber,
    'Hệ thống Nước': Colors.blue,
    'Internet / Mạng': Colors.purple,
    'Cơ sở vật chất': Colors.brown,
    'Điều hòa / Tủ lạnh': Colors.cyan,
    'Xe cộ': Colors.red,
    'Khác': Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thống kê Sự cố"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('incidents').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("Chưa có dữ liệu để thống kê"));

          // 1. Tính toán số lượng từng loại
          Map<String, int> counts = {};
          for (var doc in docs) {
            String cat = (doc.data() as Map<String, dynamic>)['category'] ?? 'Khác';
            counts[cat] = (counts[cat] ?? 0) + 1;
          }

          // 2. Chuyển đổi dữ liệu để vẽ biểu đồ
          List<PieChartSectionData> sections = [];
          counts.forEach((key, value) {
            final isBig = value > 0;
            if (isBig) {
              final percentage = (value / docs.length * 100).toStringAsFixed(1);
              sections.add(
                PieChartSectionData(
                  color: categoryColors[key] ?? Colors.grey,
                  value: value.toDouble(),
                  title: '$percentage%',
                  radius: 60,
                  titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              );
            }
          });

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text("Tỷ lệ các loại sự cố", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 40),

                // --- VẼ BIỂU ĐỒ TRÒN ---
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

                // --- CHÚ THÍCH (LEGEND) ---
                const SizedBox(height: 40),
                Expanded(
                  child: ListView(
                    children: counts.entries.map((entry) {
                      return ListTile(
                        leading: Container(
                          width: 20, height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: categoryColors[entry.key] ?? Colors.grey,
                          ),
                        ),
                        title: Text(entry.key),
                        trailing: Text("${entry.value} đơn", style: const TextStyle(fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}