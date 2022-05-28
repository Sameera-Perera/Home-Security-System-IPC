import 'dart:convert';

Map<String, History> historyFromJson(String str) => Map.from(json.decode(str))
    .map((k, v) => MapEntry<String, History>(k, History.fromJson(v)));

String historyToJson(Map<String, History> data) => json.encode(
    Map.from(data).map((k, v) => MapEntry<String, dynamic>(k, v.toJson())));

class History {
  History({
    required this.doorStatus,
    required this.timestamp,
  });

  final int doorStatus;
  final int timestamp;

  factory History.fromJson(Map<String, dynamic> json) => History(
        doorStatus: json["door_status"],
        timestamp: json["timestamp"],
      );

  Map<String, dynamic> toJson() => {
        "door_status": doorStatus,
        "timestamp": timestamp,
      };
}
