import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../../models/incident_model.dart';

class IncidentDetailScreen extends StatefulWidget {
  final IncidentModel incident;
  final bool isReadOnly; // Biến cờ hiệu: true = Chỉ xem (Staff), false = Được sửa (User)

  const IncidentDetailScreen({
    super.key,
    required this.incident,
    this.isReadOnly = false, // Mặc định là User (được bấm nút)
  });

  @override
  State<IncidentDetailScreen> createState() => _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends State<IncidentDetailScreen> {
  bool _isUpdating = false;

  // --- HÀM MỚI: ZOOM ẢNH TOÀN MÀN HÌNH ---
  void _showFullImage(BuildContext context, String base64String) {
    if (base64String.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black, // Nền đen cho dễ nhìn
        insetPadding: EdgeInsets.zero, // Full màn hình
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            // Ảnh có thể zoom, kéo thả
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0, // Zoom tối đa 4 lần
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Image.memory(
                  base64Decode(base64String),
                  fit: BoxFit.contain, // Hiển thị trọn vẹn ảnh
                ),
              ),
            ),
            // Nút đóng
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hàm xử lý khi KTV bấm hoàn thành
  Future<void> _markAsCompleted() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận hoàn thành"),
        content: const Text("Bạn đã sửa xong sự cố này chưa?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Chưa")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text("Đã xong"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isUpdating = true);

    try {
      await FirebaseFirestore.instance
          .collection('incidents')
          .doc(widget.incident.id)
          .update({
        'status': 'Resolved',
        'resolvedTime': DateTime.now().millisecondsSinceEpoch,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã cập nhật trạng thái: HOÀN THÀNH!")));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'Resolved': color = Colors.green; label = "Đã hoàn thành"; break;
      case 'Processing': color = Colors.blue; label = "Đang xử lý"; break;
      default: color = Colors.orange; label = "Chờ tiếp nhận";
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Format thời gian an toàn
    String timeString = "";
    try {
      timeString = widget.incident.timestamp.toString().substring(0, 16);
    } catch (e) {
      timeString = "N/A";
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Chi tiết sự cố")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Ảnh hiện trường (Có tính năng bấm để Zoom)
            GestureDetector(
              onTap: () {
                // Gọi hàm zoom ảnh khi bấm vào
                if (widget.incident.imageUrl.isNotEmpty) {
                  _showFullImage(context, widget.incident.imageUrl);
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: widget.incident.imageUrl.isNotEmpty
                    ? Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.memory(
                        base64Decode(widget.incident.imageUrl),
                        fit: BoxFit.cover, width: double.infinity, height: 250
                    ),
                    // Icon gợi ý bấm vào để zoom
                    Positioned(
                      right: 10, bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                        child: const Icon(Icons.zoom_in, color: Colors.white),
                      ),
                    )
                  ],
                )
                    : Container(height: 250, color: Colors.grey[300], child: const Center(child: Icon(Icons.image_not_supported, size: 50))),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Tiêu đề và Trạng thái
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(widget.incident.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                const SizedBox(width: 8),
                _buildStatusBadge(widget.incident.status),
              ],
            ),
            const SizedBox(height: 10),

            // 3. Thông tin chi tiết
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _rowInfo(Icons.category, "Loại sự cố", widget.incident.category),
                    const Divider(),
                    _rowInfo(Icons.location_on, "Vị trí", widget.incident.location),
                    const Divider(),
                    _rowInfo(Icons.description, "Mô tả", widget.incident.description),
                    const Divider(),
                    _rowInfo(Icons.access_time, "Thời gian", timeString),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 4. Nút Hoàn thành
            // LOGIC QUAN TRỌNG:
            // Chỉ hiện khi:
            // (1) Trạng thái là Processing
            // (2) VÀ KHÔNG PHẢI chế độ ReadOnly (tức là User đang xem, không phải Staff)
            if (!widget.isReadOnly && widget.incident.status == 'Processing')
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isUpdating ? null : _markAsCompleted,
                  icon: const Icon(Icons.check_circle),
                  label: _isUpdating
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("BÁO CÁO HOÀN THÀNH CÔNG VIỆC"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                ),
              ),

            // Nếu là Staff (ReadOnly) và đang Processing
            if (widget.isReadOnly && widget.incident.status == 'Processing')
              const Center(
                  child: Text(
                      "Đang chờ nhân viên kỹ thuật xử lý...",
                      style: TextStyle(color: Colors.blue, fontStyle: FontStyle.italic)
                  )
              ),

            if (widget.incident.status == 'Pending')
              const Center(child: Text("Đang chờ Quản lý tiếp nhận...", style: TextStyle(color: Colors.orange, fontStyle: FontStyle.italic))),

            if (widget.incident.status == 'Resolved')
              const Center(child: Text("Sự cố này đã được khắc phục xong.", style: TextStyle(color: Colors.green, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  Widget _rowInfo(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 10),
          SizedBox(width: 90, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}