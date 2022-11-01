// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class MyOffset {
  final double dx;
  final double dy;
  MyOffset({
    required this.dx,
    required this.dy,
  });

  MyOffset copyWith({
    double? dx,
    double? dy,
  }) {
    return MyOffset(
      dx: dx ?? this.dx,
      dy: dy ?? this.dy,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'dx': dx,
      'dy': dy,
    };
  }

  factory MyOffset.fromMap(Map<String, dynamic> map) {
    return MyOffset(
      dx: map['dx'] as double,
      dy: map['dy'] as double,
    );
  }

  String toJson() => json.encode(toMap());

  factory MyOffset.fromJson(String source) =>
      MyOffset.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'MyOffset(dx: $dx, dy: $dy)';

  @override
  bool operator ==(covariant MyOffset other) {
    if (identical(this, other)) return true;

    return other.dx == dx && other.dy == dy;
  }

  @override
  int get hashCode => dx.hashCode ^ dy.hashCode;
}
