import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../models/incident_model.dart';

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descController = TextEditingController();

  File? _imageFile;
  String? _base64Image;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 30);
    if (pickedFile != null) {
      final bytes = await File(pickedFile.path).readAsBytes();
      setState(() {
        _imageFile = File(pickedFile.path);
        _base64Image = base64Encode(bytes);
      });
    }
  }

  Future<void> _submitReport() async {
    if (_titleController.text.isEmpty || _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên thiết bị và vị trí')),
      );
      return;
    }

    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chụp ảnh sự cố')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {

      String incidentId = const Uuid().v4();

      IncidentModel newIncident = IncidentModel(id: incidentId, title: _titleController.text, location: _locationController.text, description: _descController.text, imageUrl: _base64Image!, reporterId: "user_sdt_09999999", timestamp: DateTime.now(), status: 'Pending');

      await FirebaseFirestore.instance
            .collection('incidents')
            .doc(incidentId)
            .set(newIncident.toMap());

      if (mounted) {
        setState(() {
          _isUploading = false;
        });

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Thành công!"),
            content: const Text("Cảm ơn bạn. Sự cố đã được gửi đến kỹ thuật viên."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text("Đóng"),
              )
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi gửi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Báo cáo sự cố mới")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                          Text("Chạm để chụp ảnh (bắt buộc)"),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Tên thiết bị",
                hintText: "VD: Bóng đèn, Vòi nước,...",
                prefixIcon: Icon(Icons.lightbulb_outline),
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: "Vị trí",
                hintText: "VD: phòng 301, Tầng 3...",
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _descController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: "Mô tả lỗi",
                hintText: "VD: không mát, chảy nước...",
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("GỬI YÊU CẦU", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}