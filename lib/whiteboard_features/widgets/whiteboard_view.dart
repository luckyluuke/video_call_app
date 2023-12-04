import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_call_app/whiteboard_features/models/line.dart';
import 'package:video_call_app/whiteboard_features/models/point.dart';

const aspectRatio = 9 / 16;

class WhiteboardView extends StatelessWidget {
  WhiteboardView({
    Key? key,
    required this.lines,
    required this.onGestureStart,
    required this.onGestureUpdate,
    required this.onGestureEnd,
    required this.drawingIsBlocked,
  })  :
        super(key: key);

  final List<Line?> lines;
  final ValueChanged<Point> onGestureStart;
  final void Function(Point point, Point previousPoint) onGestureUpdate;
  final VoidCallback onGestureEnd;
  final bool drawingIsBlocked;

  Widget build(BuildContext context) => Container(
    //elevation: 4,
    width: 20000,
    height: 20000,
    child: LayoutBuilder(
      builder: (context, constraints) => Listener(
        onPointerDown: (details) {
            onGestureStart.call(_getOffsetPoint(details.localPosition, constraints.biggest));
        },
        onPointerMove: (details) {
          //debugPrint("DEBUG_LOG WHITEBOARD VIEW: details.localPosition=" + details.localPosition.toString() +" constraints.biggest=" + constraints.biggest.width.toString() );

            onGestureUpdate(
              _getOffsetPoint(details.localPosition, constraints.biggest),
              _getOffsetPoint(
                details.localPosition
                    .translate(-details.delta.dx, -details.delta.dy),
                constraints.biggest,
              ),
            );
        },
        onPointerUp: (_) {
          onGestureEnd.call();
        },
        //onPanEnd: (_) => onGestureEnd.call(),
        child: CustomPaint(
          painter: WhiteboardPainter(lines),
          isComplex: true,
          willChange: true,
        ),
      ),
    ),
  );

  Point _getOffsetPoint(Offset offset, Size size) => Point(
    (offset.dx / size.width),//.clamp(0, 1).toDouble(),
    (offset.dy / size.width)//.clamp(0, 1 / aspectRatio).toDouble(),
  );
}

class WhiteboardPainter extends CustomPainter {
  const WhiteboardPainter(this._lines); //: assert(_lines != null);

  final List<Line?> _lines;

  @override
  void paint(Canvas canvas, Size size) {

    final paint = Paint()
      ..strokeCap = StrokeCap.round;

    for (final line in _lines) {
      if (line != null){
        paint.color = line.color;
        paint.strokeWidth = size.width / line.penSize;
        //debugPrint("DEBUG_LOG WHITEBOARD POINTS SIZE: size.width=" + size.width.toString() + " line.penSize="+line.penSize.toString() );

        if (line.penShape == "normal"){

          paint.style = PaintingStyle.stroke;
          paint.strokeJoin = StrokeJoin.round;

          final path = Path();

          path.moveTo(line.points.first!.x * size.width, line.points.first!.y * size.width);
          path.lineTo(line.points.first!.x * size.width, line.points.first!.y * size.width);

          line.points.sublist(1).forEach((point) {
            path.lineTo(point!.x * size.width, point.y * size.width);
          });

          canvas.drawPath(path, paint);
        }
        else if(line.penShape == "drawLine"){
          canvas.drawLine(
            _getPointOffset(line.points.first!, size),
            _getPointOffset(line.points.last!, size),
            paint,
          );
        }
        else if(line.penShape == "drawCircle"){

          paint.style = PaintingStyle.stroke;
          canvas.drawOval(
              Rect.fromPoints(
                _getPointOffset(line.points.first!, size),
                _getPointOffset(line.points.last!, size),
              ),
              paint
          );
        }
        else if(line.penShape == "drawTriangle"){
          //TODO: Let helpers choose their income (from 5 to 15) + Change LIVE button name ?
          paint.style = PaintingStyle.stroke;
          var path = Path();

          path.moveTo(line.points.first!.x * size.width, line.points.first!.y * size.width);
          path.lineTo(line.points.first!.x * size.width, line.points.last!.y * size.width);
          path.lineTo(line.points.last!.x * size.width , line.points.last!.y * size.width);
          path.close();

          canvas.drawPath(path, paint);
        }
        else if(line.penShape == "drawSquare"){
          paint.style = PaintingStyle.stroke;
          canvas.drawRect(
              Rect.fromPoints(
                _getPointOffset(line.points.first!, size),
                _getPointOffset(line.points.last!, size),
              ),
              paint
          );
        }

      }

    }
  }

  Offset _getPointOffset(Point point, Size size) =>
      Offset(point.x * size.width, point.y * size.width);

  @override
  bool shouldRepaint(WhiteboardPainter oldDelegate) =>
      _lines != oldDelegate._lines;
}