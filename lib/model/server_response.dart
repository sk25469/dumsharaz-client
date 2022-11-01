// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:scribble_demo/model/drawn_line.dart';
import 'package:scribble_demo/model/room_info.dart';

import 'client_info.dart';

class ServerResponse {
  // ignore: non_constant_identifier_names
  final String response_type;
  final RoomInfo room_info;
  final ClientInfo client_info;
  final List<DrawnLine> drawn_points;
  ServerResponse({
    required this.response_type,
    required this.room_info,
    required this.client_info,
    required this.drawn_points,
  });

  ServerResponse copyWith({
    String? response_type,
    RoomInfo? room_info,
    ClientInfo? client_info,
    List<DrawnLine>? drawn_points,
  }) {
    return ServerResponse(
      response_type: response_type ?? this.response_type,
      room_info: room_info ?? this.room_info,
      client_info: client_info ?? this.client_info,
      drawn_points: drawn_points ?? this.drawn_points,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'response_type': response_type,
      'room_info': room_info.toMap(),
      'client_info': client_info.toMap(),
      'drawn_points': drawn_points.map((x) => x.toMap()).toList(),
    };
  }

  factory ServerResponse.fromMap(Map<String, dynamic> map) {
    return ServerResponse(
      response_type: map['response_type'] as String,
      room_info: RoomInfo.fromMap(map['room_info'] as Map<String, dynamic>),
      client_info: ClientInfo.fromMap(map['client_info'] as Map<String, dynamic>),
      drawn_points: List<DrawnLine>.from(
        (map['drawn_points'] as List<dynamic>).map<DrawnLine>(
          (x) => DrawnLine.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory ServerResponse.fromJson(String source) =>
      ServerResponse.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ServerResponse(response_type: $response_type, room_info: $room_info, client_info: $client_info, drawn_points: $drawn_points)';
  }

  @override
  bool operator ==(covariant ServerResponse other) {
    if (identical(this, other)) return true;

    return other.response_type == response_type &&
        other.room_info == room_info &&
        other.client_info == client_info &&
        listEquals(other.drawn_points, drawn_points);
  }

  @override
  int get hashCode {
    return response_type.hashCode ^
        room_info.hashCode ^
        client_info.hashCode ^
        drawn_points.hashCode;
  }
}
