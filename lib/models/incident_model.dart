class IncidentModel {
  final String id;
  final String title;
  final String location;
  final String description;
  final String imageUrl;
  final String reporterId;
  final String? staffId;
  final DateTime timestamp;
  final String status;
  final String? resultImageUrl;
  final String category;

  IncidentModel({
    required this.id,
    required this.title,
    required this.location,
    required this.description,
    required this.imageUrl,
    required this.reporterId,
    required this.timestamp,
    this.staffId,
    this.status = 'Pending',
    this.resultImageUrl,
    this.category = 'Khác'
  });
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'description': description,
      'imageUrl': imageUrl,
      'reporterId': reporterId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'resultImageUrl': resultImageUrl,
      'cagetory': category,
    };
  }
  
  factory IncidentModel.fromMap(Map<String, dynamic> map, String documentId) {
    return IncidentModel(
      id: documentId,
      title: map['title'] ?? '',
      location: map['location'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      reporterId: map['reporterId'] ?? '',
      staffId: map['staffId'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      resultImageUrl: map['resultImageUrl'],
      category: map['cagetory'] ?? 'Khác',
    );
  }
}