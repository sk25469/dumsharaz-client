// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:convert';

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

import 'package:scribble_demo/model/my_offset.dart';

class DrawnLine {
  final List<MyOffset> path;
  final Color color;
  final double width;
  DrawnLine({
    required this.path,
    required this.color,
    required this.width,
  });

  DrawnLine copyWith({
    List<MyOffset>? path,
    Color? color,
    double? width,
  }) {
    return DrawnLine(
      path: path ?? this.path,
      color: color ?? this.color,
      width: width ?? this.width,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'path': path.map((x) => x.toMap()).toList(),
      'color': color.value,
      'width': width,
    };
  }

  factory DrawnLine.fromMap(Map<String, dynamic> map) {
    return DrawnLine(
      path: List<MyOffset>.from(
        (map['path'] as List<dynamic>).map<MyOffset>(
          (x) => MyOffset.fromMap(x as Map<String, dynamic>),
        ),
      ),
      color: Color(map['color'] as int),
      width: map['width'] as double,
    );
  }

  String toJson() => json.encode(toMap());

  factory DrawnLine.fromJson(String source) =>
      DrawnLine.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'DrawnLine(path: $path, color: $color, width: $width)';

  @override
  bool operator ==(covariant DrawnLine other) {
    if (identical(this, other)) return true;

    return listEquals(other.path, path) && other.color == color && other.width == width;
  }

  @override
  int get hashCode => path.hashCode ^ color.hashCode ^ width.hashCode;
}
