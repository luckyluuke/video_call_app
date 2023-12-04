import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
//import 'package:my_first_app/services/AlertDialogManager.dart';
//import 'package:my_first_app/services/CommonFunctionsManager.dart';
import 'package:video_call_app/whiteboard_features/whiteboard_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';



class ToolButtons extends StatefulWidget {
  final WhiteboardViewModel? viewmodel;
  final String currentUserId;

  const ToolButtons({Key? key, required this.viewmodel, required this.currentUserId});

  @override
  State<ToolButtons> createState() => _MyToolButtonsWidget(viewmodel: viewmodel, currentUserId: currentUserId);
}

class _MyToolButtonsWidget extends State<ToolButtons> {
  WhiteboardViewModel? viewmodel;
  String currentUserId;

  _MyToolButtonsWidget({required this.viewmodel, required this.currentUserId}){
    if (viewmodel != null){
      (viewmodel!.userId == viewmodel!.helperId) ? buttonPressed = "blue" : buttonPressed = "green";
    }
  }

  double _currentSliderValue = 3;
  String ? buttonPressed = "blue";
  String ? buttonShapePressed = "normal";


  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          decoration: (viewmodel == null) ? null :
          ("draw" == viewmodel!.buttonIndicator ? BoxDecoration(
            border: Border.all(
            color: Colors.green,
            width: 3, //                   <--- border width here
            ),
            color: Color(0xff00E091)
          ) : null),
          child: IconButton(
            icon: Image.asset("images/pencil.png"),//Icon(Icons.edit),
            onPressed: () {

              if (viewmodel != null){

                if((viewmodel!.mainUserId == currentUserId) || (viewmodel!.helperId == currentUserId)){
                  viewmodel!.setButtonIndicator("draw");
                  viewmodel!.disableDrawing(false);
                  viewmodel!.enableEraser(false);

                  showDialog(
                      context: context,
                      builder: (context) {
                        return StatefulBuilder(
                            builder: (context, setState) {
                              return AlertDialog(
                                titlePadding: EdgeInsets.all(1),
                                actionsPadding: EdgeInsets.only(bottom: 10.0,),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Text(
                                      'Modifier le style',
                                      style: GoogleFonts.inter(
                                        color: Colors.grey,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),

                                    ElevatedButton(
                                      onPressed: (){
                                        Navigator.pop(context);
                                      },
                                      child: Icon(Icons.close),
                                      style: ElevatedButton.styleFrom(
                                        shape: CircleBorder(),
                                        primary: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  Center(
                                    child: Column(
                                      children: [

                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                                          children: [
                                            Icon(Icons.remove,size: 20),
                                            Expanded(
                                              child: SliderTheme(
                                                data: SliderTheme.of(context).copyWith(
                                                  trackHeight: 10.0,
                                                  trackShape: RoundedRectSliderTrackShape(),
                                                  activeTrackColor: Colors.purple.shade800,
                                                  inactiveTrackColor: Colors.purple.shade100,
                                                  thumbShape: RoundSliderThumbShape(
                                                    enabledThumbRadius: 14.0,
                                                    pressedElevation: 8.0,
                                                  ),
                                                  thumbColor: Colors.pinkAccent,
                                                  overlayColor: Colors.pink.withOpacity(0.2),
                                                  overlayShape: RoundSliderOverlayShape(overlayRadius: 32.0),
                                                  tickMarkShape: RoundSliderTickMarkShape(),
                                                  activeTickMarkColor: Colors.pinkAccent,
                                                  inactiveTickMarkColor: Colors.white,
                                                  valueIndicatorShape: PaddleSliderValueIndicatorShape(),
                                                  valueIndicatorColor: Colors.black,
                                                  valueIndicatorTextStyle: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 20.0,
                                                  ),
                                                ),
                                                child: Slider(
                                                  activeColor: Colors.pink,
                                                  inactiveColor: Colors.purple.shade100,
                                                  min: 1,
                                                  max: 10,
                                                  divisions: 10,
                                                  label: _currentSliderValue.round().toString(),
                                                  // Change track when its ends
                                                  value: _currentSliderValue,
                                                  onChanged: (value) {
                                                    if (viewmodel != null){
                                                      setState(() {
                                                        _currentSliderValue = value;
                                                        viewmodel!.setPenSize(20000/value);
                                                      });
                                                    }
                                                  },
                                                ),
                                              ),
                                            ),
                                            Icon(Icons.add,size: 20),
                                          ],
                                        ),
                                        SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              ConstrainedBox(
                                                constraints: const BoxConstraints
                                                    .tightFor(width: 30, height: 30),
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    if (viewmodel!=null){
                                                      setState(() {
                                                        buttonPressed = "yellow";
                                                      });
                                                      viewmodel!.setColor(Colors.yellow);
                                                    }

                                                    //Navigator.pop(context);
                                                  },
                                                  child: ("yellow" == buttonPressed) ?
                                                  Icon(Icons.check_circle, color: Colors.purple, size: 15)
                                                      : Container(),
                                                  style: ElevatedButton.styleFrom(
                                                    shape: CircleBorder(),
                                                    primary: Colors.yellow,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 5),
                                              ConstrainedBox(
                                                constraints: const BoxConstraints
                                                    .tightFor(width: 30, height: 30),
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    if(viewmodel != null){
                                                      setState(() {
                                                        buttonPressed = "orange";
                                                      });
                                                      viewmodel!.setColor(Colors.orange);
                                                    }

                                                    //Navigator.pop(context);
                                                  },
                                                  child: ("orange" == buttonPressed) ?
                                                  Icon(Icons.check_circle, color: Colors.blue[900], size: 15)
                                                      : Container(),
                                                  style: ElevatedButton.styleFrom(
                                                    shape: CircleBorder(),
                                                    primary: Colors.orange,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 5),
                                              ConstrainedBox(
                                                constraints: const BoxConstraints
                                                    .tightFor(width: 30, height: 30),
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    if(viewmodel != null){
                                                      setState(() {
                                                        buttonPressed = "black";
                                                      });
                                                      viewmodel!.setColor(Colors.black);
                                                    }

                                                    //Navigator.pop(context);
                                                  },
                                                  child: ("black" == buttonPressed) ?
                                                  Icon(Icons.check_circle, color: Colors.white, size: 15)
                                                      : Container(),
                                                  style: ElevatedButton.styleFrom(
                                                    shape: CircleBorder(),
                                                    primary: Colors.black,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 5),
                                              ConstrainedBox(
                                                constraints: const BoxConstraints
                                                    .tightFor(width: 30, height: 30),
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    if(viewmodel != null){
                                                      setState(() {
                                                        buttonPressed = "blue";
                                                      });
                                                      viewmodel!.setColor(Colors.blue);
                                                    }

                                                    //Navigator.pop(context);
                                                  },
                                                  child: ("blue" == buttonPressed) ?
                                                  Icon(Icons.check_circle, color: Colors.black, size: 15)
                                                      : Container(),
                                                  style: ElevatedButton.styleFrom(
                                                    shape: CircleBorder(),
                                                    primary: Colors.blue,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 5),
                                              ConstrainedBox(
                                                constraints: const BoxConstraints
                                                    .tightFor(width: 30, height: 30),
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    if(viewmodel != null){
                                                      setState(() {
                                                        buttonPressed = "red";
                                                      });
                                                      viewmodel!.setColor(Colors.red);
                                                    }

                                                    //Navigator.pop(context);
                                                  },
                                                  child: ("red" == buttonPressed) ?
                                                  Icon(Icons.check_circle, color: Colors.yellow, size: 15)
                                                      : Container(),
                                                  style: ElevatedButton.styleFrom(
                                                    shape: CircleBorder(),
                                                    primary: Colors.red,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 5),
                                              ConstrainedBox(
                                                constraints: const BoxConstraints
                                                    .tightFor(width: 30, height: 30),
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    if(viewmodel != null){
                                                      setState(() {
                                                        buttonPressed = "green";
                                                      });
                                                      viewmodel!.setColor(Colors.green);
                                                    }

                                                    //Navigator.pop(context);
                                                  },
                                                  child: ("green" == buttonPressed) ?
                                                  Icon(Icons.check_circle, color: Colors.pink, size: 15)
                                                      : Container(),
                                                  style: ElevatedButton.styleFrom(
                                                    shape: CircleBorder(),
                                                    primary: Colors.green,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 5),
                                              ConstrainedBox(
                                                constraints: const BoxConstraints
                                                    .tightFor(width: 30, height: 30),
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    if(viewmodel != null){
                                                      setState(() {
                                                        buttonPressed = "purple";
                                                      });
                                                      viewmodel!.setColor(Colors.purple);
                                                    }

                                                    //Navigator.pop(context);
                                                  },
                                                  child: ("purple" == buttonPressed) ?
                                                  Icon(Icons.check_circle, color: Colors.yellow, size: 15)
                                                      : Container(),
                                                  style: ElevatedButton.styleFrom(
                                                    shape: CircleBorder(),
                                                    primary: Colors.purple,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 20),
                                        SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                height: "normal" == buttonShapePressed ? null : 35,
                                                width: "normal" == buttonShapePressed ? null : 35,
                                                decoration: (viewmodel == null) ? null :
                                                ("normal" == buttonShapePressed ? BoxDecoration(
                                                    border: Border.all(
                                                      color: Colors.green,
                                                      width: 3, //                   <--- border width here
                                                    ),
                                                    color: Color(0xff00E091)
                                                ) : null),
                                                color: "normal" == buttonShapePressed ? null : Colors.lightGreenAccent,
                                                child: IconButton(
                                                  iconSize: "normal" == buttonShapePressed ? null : 20,
                                                  onPressed: () {

                                                    if(viewmodel != null){
                                                      setState(() {
                                                        buttonShapePressed = "normal";
                                                      });
                                                      viewmodel!.setShape(buttonShapePressed!);
                                                    }

                                                    //Navigator.pop(context);
                                                  },
                                                  icon: Icon(Icons.draw_rounded,color: Colors.black),
                                                ),
                                              ),
                                              SizedBox(width: 5),
                                              Container(
                                                height: "drawLine" == buttonShapePressed ? null : 35,
                                                width: "drawLine" == buttonShapePressed ? null : 35,
                                                decoration: (viewmodel == null) ? null :
                                                ("drawLine" == buttonShapePressed ? BoxDecoration(
                                                    border: Border.all(
                                                      color: Colors.green,
                                                      width: 3, //                   <--- border width here
                                                    ),
                                                    color: Color(0xff00E091)
                                                ) : null),
                                                color: "drawLine" == buttonShapePressed ? null : Colors.lightGreenAccent,
                                                child: IconButton(
                                                  iconSize: "drawLine" == buttonShapePressed ? null : 20,
                                                  onPressed: () {

                                                    if(viewmodel != null){
                                                      setState(() {
                                                        buttonShapePressed = "drawLine";
                                                      });
                                                      viewmodel!.setShape(buttonShapePressed!);
                                                    }

                                                    //Navigator.pop(context);
                                                  },
                                                  icon: Icon(Icons.insights_outlined,color: Colors.black),
                                                ),
                                              ),
                                              SizedBox(width: 5),
                                              Container(
                                                height: "drawCircle" == buttonShapePressed ? null : 35,
                                                width: "drawCircle" == buttonShapePressed ? null : 35,
                                                decoration: (viewmodel == null) ? null :
                                                ("drawCircle" == buttonShapePressed ? BoxDecoration(
                                                    border: Border.all(
                                                      color: Colors.green,
                                                      width: 3, //                   <--- border width here
                                                    ),
                                                    color: Color(0xff00E091)
                                                ) : null),
                                                color: "drawCircle" == buttonShapePressed ? null : Colors.lightGreenAccent,
                                                child: IconButton(
                                                  iconSize: "drawCircle" == buttonShapePressed ? null : 20,
                                                  onPressed: () {

                                                    if(viewmodel != null){
                                                      setState(() {
                                                        buttonShapePressed = "drawCircle";
                                                      });
                                                      viewmodel!.setShape(buttonShapePressed!);
                                                    }

                                                    //Navigator.pop(context);
                                                  },
                                                  icon: Icon(Icons.brightness_1_outlined,color: Colors.black),
                                                ),
                                              ),
                                              SizedBox(width: 5),
                                              Container(
                                                height: "drawTriangle" == buttonShapePressed ? null : 35,
                                                width: "drawTriangle" == buttonShapePressed ? null : 35,
                                                decoration: (viewmodel == null) ? null :
                                                ("drawTriangle" == buttonShapePressed ? BoxDecoration(
                                                    border: Border.all(
                                                      color: Colors.green,
                                                      width: 3, //                   <--- border width here
                                                    ),
                                                    color: Color(0xff00E091)
                                                ) : null),
                                                color: "drawTriangle" == buttonShapePressed ? null : Colors.lightGreenAccent,
                                                child: IconButton(
                                                  iconSize: "drawTriangle" == buttonShapePressed ? null : 20,
                                                  onPressed: () {

                                                    if(viewmodel != null){
                                                      setState(() {
                                                        buttonShapePressed = "drawTriangle";
                                                      });
                                                      viewmodel!.setShape(buttonShapePressed!);
                                                    }

                                                    //Navigator.pop(context);
                                                  },
                                                  icon: Transform(
                                                      alignment: Alignment.center,
                                                      transform: Matrix4.rotationY(3.14),
                                                      child: Icon(Icons.signal_cellular_0_bar_rounded,color: Colors.black)
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 5),
                                              Container(
                                                height: "drawSquare" == buttonShapePressed ? null : 35,
                                                width: "drawSquare" == buttonShapePressed ? null : 35,
                                                decoration: (viewmodel == null) ? null :
                                                ("drawSquare" == buttonShapePressed ? BoxDecoration(
                                                    border: Border.all(
                                                      color: Colors.green,
                                                      width: 3, //                   <--- border width here
                                                    ),
                                                    color: Color(0xff00E091)
                                                ) : null),
                                                color: "drawSquare" == buttonShapePressed ? null : Colors.lightGreenAccent,
                                                child: IconButton(
                                                  iconSize: "drawSquare" == buttonShapePressed ? null : 20,
                                                  onPressed: () {

                                                    if(viewmodel != null){
                                                      setState(() {
                                                        buttonShapePressed = "drawSquare";
                                                      });
                                                      viewmodel!.setShape(buttonShapePressed!);
                                                    }

                                                    //Navigator.pop(context);
                                                  },
                                                  icon: Icon(Icons.crop_din_sharp,color: Colors.black),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }
                        );
                      });
                }else{
                  //AlertDialogManager.shortDialog(context, "C'est bientôt ton tour ! ${CommonFunctionsManager.capitalize(viewmodel!.mainHelperName)} termine actuellement son explication avec un élève et poursuivra ensuite avec toi dans quelques instants.",titleColor: Colors.grey);
                }

              } else {
                //AlertDialogManager.shortDialog(context, "Action impossible pour le moment",withTimer: true);
              }

              if (viewmodel != null){
                //viewmodel!.selectTool(Tool.pen);
              }

            },
          ),
        ),
        Container(
          decoration: (viewmodel == null) ? null :
          ("erase" == viewmodel!.buttonIndicator? BoxDecoration(
              border: Border.all(
                color: Colors.green,
                width: 3, //                   <--- border width here
              ),
              color: Color(0xff00E091)
          ) : null),
          child: IconButton(
            icon: Image.asset("images/eraser.png"),//Icon(Icons.delete_outline),
            //color: viewmodel.tool == Tool.eraser ? Colors.black : Colors.black54,
            onPressed: () {
              if(viewmodel != null){
                if((viewmodel!.mainUserId == currentUserId) || (viewmodel!.helperId == currentUserId)){
                  viewmodel!.setEraserType("singleEraser");
                  viewmodel!.setButtonIndicator("erase");
                  viewmodel!.disableDrawing(false);
                  viewmodel!.enableEraser(true);
                  //viewmodel!.selectTool(Tool.eraser);
                }else{
                  //AlertDialogManager.shortDialog(context, "C'est bientôt ton tour ! ${CommonFunctionsManager.capitalize(viewmodel!.mainHelperName)} termine actuellement son explication avec un élève et poursuivra ensuite avec toi dans quelques instants.",titleColor: Colors.grey);
                }

              }else{
                //AlertDialogManager.shortDialog(context, "Action impossible pour le moment", withTimer: true);
              }
            },
          ),
        ),
        Container(
          decoration: (viewmodel == null) ? null :
          ("zoom" == viewmodel!.buttonIndicator ? BoxDecoration(
              border: Border.all(
                color: Colors.green,
                width: 3, //                   <--- border width here
              ),
              color: Color(0xff00E091)
          ) : null),
          child: IconButton(
            icon: Image.asset("images/magnifying_glass.png"),//Icon(Icons.zoom_in),
            color: Colors.black54,
            onPressed: () async {
              if(viewmodel != null){
                viewmodel!.setButtonIndicator("zoom");
                viewmodel!.enableEraser(false);
                viewmodel!.disableDrawing(true);

                final prefs = await SharedPreferences.getInstance();
                int? zoomAlertMessage = await prefs.getInt("zoomAlertMessage");
                if (zoomAlertMessage == null) {
                  debugPrint("DEBUG_LOG FIRST ZOOM UTILITY");
                  await prefs.setInt("zoomAlertMessage", 1);
                  viewmodel!.setZoomUtility(true);
                }else if (zoomAlertMessage < 2){
                  await prefs.setInt("zoomAlertMessage", 2);
                  viewmodel!.setZoomUtility(true);
                }else if ((zoomAlertMessage == 2) && (viewmodel!.zoomUtility)){
                  viewmodel!.setZoomUtility(false);
                }

              }else{
                //AlertDialogManager.shortDialog(context, "Action impossible pour le moment", withTimer: true);
              }

            }),
        ),
      ],
    );
  }
}