// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'line.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Line _$LineFromJson(Map json) {

  return Line(
    (json['points'] as List)
        .map((e) => e == null
        ? null
        : Point.fromJson((e as Map).map(
          (k, e) => MapEntry(k as String, e),
    )))
        .toList(),
    Color(json['color']),
    json['penSize'],
    json['penShape'],
  );
}

Map<String, dynamic> _$LineToJson(Line instance) => <String, dynamic>{
  'penSize': instance.penSize,
  'penShape': instance.penShape,
  'color': instance.color.value,
  'points': (instance.penShape == "normal") ? instance.points.map((e) => e!.toJson()).toList() : [instance.points.map((e) => e!.toJson()).toList().first,instance.points.map((e) => e!.toJson()).toList().last],
};

Map<String, dynamic> _$LineToJsonDeleteLine(Line instance) => <String, dynamic>{
  'penSize': instance.penSize,
  'penShape': instance.penShape,
  'color': 'MaterialColor(primary value: ' + instance.color.toString() + ')',
  'points': (instance.penShape == "normal") ? instance.points.map((e) => e!.toJson()).toList() : [instance.points.map((e) => e!.toJson()).toList().first,instance.points.map((e) => e!.toJson()).toList().last],
};