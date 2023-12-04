import 'dart:ui';

import 'package:json_annotation/json_annotation.dart';
import 'package:video_call_app/whiteboard_features/models/point.dart';

part 'line.g.dart';

@JsonSerializable(anyMap: true, explicitToJson: true)
class Line {
  const Line(this.points, this.color, this.penSize, this.penShape);

  factory Line.fromJson(Map json) => _$LineFromJson(json);

  final List<Point?> points;
  final Color color;
  final penSize;
  final penShape;

  Map<String, dynamic> toJson() => _$LineToJson(this);

  Map<String, dynamic> toJsonDeleteLine() => _$LineToJsonDeleteLine(this);
}
