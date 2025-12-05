class SessionUserDetails {
  int id;
  String name;
  int? volume;
  bool? isMuted;

  SessionUserDetails({
    required this.id,
    required this.name,
    required this.volume,
    required this.isMuted,
  });

  factory SessionUserDetails.fromJson(Map<String, dynamic> json) => SessionUserDetails(
    id: json["id"],
    name: json["name"],
    volume: json["volume"],
    isMuted: json["isMuted"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "volume": volume,
    "isMuted": isMuted,
  };
}