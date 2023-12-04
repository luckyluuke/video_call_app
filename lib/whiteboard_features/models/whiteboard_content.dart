import 'package:json_annotation/json_annotation.dart';
import 'package:video_call_app/whiteboard_features/models/line.dart';

part 'whiteboard_content.g.dart';

@JsonSerializable(anyMap: true, explicitToJson: true)
class WhiteboardContent {
  //WhiteboardContent(this.id, this.lines);
  WhiteboardContent(this.lines,this.isWriting);

  factory WhiteboardContent.fromJson(Map json) =>
      _$WhiteboardContentFromJson(json);

  final String? isWriting;
  final List<Line?>? lines;


  Map<String, dynamic> toJson() => _$WhiteboardContentToJson(this);
}