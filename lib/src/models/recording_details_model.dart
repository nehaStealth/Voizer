class RecordingDetails {
  int id;
  int userId;
  String recordingName;
  String fileName;
  DateTime createdAt;

  RecordingDetails({
    required this.id,
    required this.userId,
    required this.recordingName,
    required this.fileName,
    required this.createdAt,
  });

  factory RecordingDetails.fromJson(Map<String, dynamic> json) => RecordingDetails(
    id: json["id"],
    userId: json["user_id"],
    recordingName: json["recording_name"],
    fileName: json["file_name"],
    createdAt: DateTime.parse(json["created_at"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "user_id": userId,
    "recording_name": recordingName,
    "file_name": fileName,
    "createdAt": createdAt.toIso8601String(),
  };
}