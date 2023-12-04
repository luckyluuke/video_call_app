import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
//import 'package:my_first_app/services/AlertDialogManager.dart';
//import 'package:my_first_app/services/UserManager.dart';
import 'package:uuid/uuid.dart';
import 'models/line.dart';
import 'models/point.dart';
import 'models/whiteboard_content.dart';
import 'package:path/path.dart';

enum Tool { pen, eraser, previousEraser, totalEraser }

void addNewLine(List<dynamic> values) {
  SendPort sendPort = values.last;
  var result = WhiteboardContent([...?values[0], values[1]],values[2]);
  sendPort.send(result);
}

class WhiteboardViewModel extends ChangeNotifier {

  WhiteboardViewModel(this._firestore, this._id, this._user_id, this._helper_id, this._taskId) {

    _whiteboardRef = _firestore.collection('whiteboards').doc(_id);
    _subscription = _whiteboardRef!.snapshots().listen(_onContentSnapshot);
    _imageBoardRef = _firestore.collection('temporaryUsersFilesLinks').doc(_id);
    _subscriptionImage = _imageBoardRef!.snapshots().listen(_onImageSnapshot);
    _callable = FirebaseFunctions.instanceFor(app: FirebaseFunctions.instance.app, region: "europe-west1").httpsCallable("updateWhiteboard");

    //debugPrint("DEBUG_LOG VIEW _user_id=$_user_id _helper_id$_helper_id");
    //(_userManager.userId! == _helper_id) ? pen_color = Colors.blue : pen_color = Colors.green;
  }
  HttpsCallable? _callable;
  final FirebaseFirestore _firestore;
  final String? _id;
  String _user_id = '';
  String _main_user_id = '';
  String _main_caller_name = '';
  String _main_helper_name = '';
  String _helper_id = '';
  String _swapUserId = '';
  String? newImageURL = "";
  String _taskId = '';
  String _isBotChecker = "";
  String _isSharing = "";
  List<dynamic> sharedFiles = [];
  List<dynamic> usersAvatars = [];
  List<dynamic> moreUsers = [];
  int updated = 0;
  bool isCameraSource = false;
  bool isDoingSomething = false;
  bool consumerIsDoingSomething = false;
  bool helperIsDoingSomething = false;
  bool _changeVideoMode = false;
  String _liveNearlyClosed = "";
  bool calleeLiveState = false;
  bool _callStatus = false;
  bool _appIsInMaintenance = false;
  bool isEraserSelected = false;
  bool _zoomUtility = false;
  String? _start_call = '';
  bool _drawingBlocked = false;
  String ? _buttonIndicator = "draw";
  String ? _eraserType = "singleEraser";

  DocumentReference ? _whiteboardRef;
  DocumentReference ? _imageBoardRef;
  StreamSubscription? _subscription;
  StreamSubscription? _subscriptionImage;

  //UserManager _userManager = UserManager();

  Color pen_color = Colors.blue;
  String pen_shape = "normal";
  double pen_size = 6600;
  int numOfIsolates = 0;

  //var _content = WhiteboardContent(Uuid().v1(), <Line>[]);
  var _content = WhiteboardContent(<Line>[],"");
  var _writtenIds = <String?>[];

  Line? _currentLine;
  Tool _tool = Tool.pen;

  List<Line?> get lines => [
    ...?_content.lines,
    if (_currentLine != null) _currentLine,
  ];

  Tool get tool => _tool;
  bool get pictureFromCameraSource => isCameraSource;
  //bool get userAction => isDoingSomething;
  bool get callStatus => _callStatus;
  bool get appIsInMaintenance => _appIsInMaintenance;
  String? get startCall => _start_call;
  String get helperId => _helper_id;
  String get swapUserId => _swapUserId;
  String get userId => _user_id;
  String get mainUserId => _main_user_id;
  String get mainCallerName=> _main_caller_name;
  String get mainHelperName=> _main_helper_name;
  String get isBotChecker => _isBotChecker;
  String get isSharing=> _isSharing;
  bool get consumerAction => consumerIsDoingSomething;
  bool get helperAction => helperIsDoingSomething;
  bool get eraserStatus => isEraserSelected;
  bool get drawingIsBlocked => _drawingBlocked;
  String? get buttonIndicator => _buttonIndicator;
  String? get eraserType => _eraserType;
  bool get changeVideoMode => _changeVideoMode;
  String get liveNearlyClosed => _liveNearlyClosed;
  bool get zoomUtility => _zoomUtility;


  void setZoomUtility(bool state){
    _zoomUtility = state;
    notifyListeners();
  }

  void setButtonIndicator(String? indicator) {
    _buttonIndicator = indicator;
    notifyListeners();
  }

  void setEraserType(String? type) {
    _eraserType = type;
    notifyListeners();
  }



  void setColor(Color customcolor) {
    pen_color = customcolor;
    notifyListeners();
  }

  void setShape(String penShape) {
    pen_shape = penShape;
    notifyListeners();
  }

  void disableDrawing(bool drawingIsBlocked) {
    _drawingBlocked = drawingIsBlocked;
    notifyListeners();
  }

  void enableEraser(bool isSelected) {
    isEraserSelected = isSelected;
    notifyListeners();
  }

  void endCall(bool m_callStatus, String m_helper_id) async {

    try{
      //await _userManager.updateValue("temporaryUsersFilesLinks", "end_call", m_callStatus, docId: _id!);
    }catch(error){
      _callStatus = m_callStatus;
      _helper_id = m_helper_id;
      notifyListeners();
    }

  }

  Future<void> deleteCallActivity() async {
    HttpsCallable initCallActivityCallable = await FirebaseFunctions
        .instanceFor(
        app: FirebaseFunctions.instance.app, region: "europe-west1")
        .httpsCallable('deleteCallActivity');

    try{
      await initCallActivityCallable.call(<String, dynamic>{
        "taskId": _taskId,
      });
    }catch(error){
      debugPrint("DEBUG_LOG WARNING, Current task has already been deleted.");
    }


  }

  void setPenSize(double penSize) {
    pen_size = penSize;
    notifyListeners();
  }

  void onGestureStart(Point point) {
    if (_tool == Tool.pen) {
      _currentLine = Line([point],pen_color, pen_size, pen_shape);
      notifyListeners();
    } else if (_tool == Tool.eraser){
      _remove(point);
    }
  }

  String?  get urlImage => newImageURL;

  void setImageUrl(bool fromCameraSource,{BuildContext? context}) async {

    File? image = null;
    final _picker = ImagePicker();

    final XFile? localImage = await _picker.pickImage(source: fromCameraSource ? ImageSource.camera : ImageSource.gallery, imageQuality: 85);

    image = File(localImage!.path);
    final filename = basename(image.path);
    Reference ref = FirebaseStorage.instance.ref();
    TaskSnapshot addImg = await ref.child("temporary_users_files/$_id/$filename").putFile(image);

    String m_returnURL = await addImg.ref.getDownloadURL();
    sharedFiles.add(m_returnURL);

    //await _userManager.updateValue("temporaryUsersFilesLinks", "sharedfiles", sharedFiles, docId: _id!);

    notifyListeners();

  }

  void _onImageSnapshot(DocumentSnapshot snapshot) {
    Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;

    if (data != null){
      //newImageURL = data['imageURL'];
      sharedFiles = data['sharedfiles'];
      usersAvatars = data['usersAvatars'];
      _isBotChecker = data['isBotChecker'];
      _isSharing = data['isSharing'];

      if(!listEquals(data['moreUsers'],moreUsers)){
        moreUsers = data['moreUsers'];
        if(moreUsers.isNotEmpty){
          for(int i=0; i<moreUsers.length;i++){
            /*if(moreUsers[i]["userId"] == _userManager.userId){
              //_userManager.updateValue("status", _userManager.userId! , moreUsers[i]["lastUpdatedServer"],docId: _id!);
            }*/
          }
        }
      }

      consumerIsDoingSomething = data['consumer_is_doing_something'];
      helperIsDoingSomething = data['helper_is_doing_something'];
      _callStatus = data['end_call'];
      _appIsInMaintenance = data['appIsInMaintenance'];
      _helper_id = data['helper_id'];
      _main_user_id = data['caller_id'];
      _main_caller_name = data['caller_name'];
      _main_helper_name = data['helper_name'];
      _swapUserId = data['swapUserId'];
      _start_call = data['start_call'];
      _callStatus = data['end_call'];
      _taskId = data['taskId'];

      if (updated != data['updated']){
        updated = data['updated'];

        /*if (_userManager.userId == _helper_id){
          _userManager.updateValue("status", "updated" , updated,docId: _id!);
        } else if ((_userManager.userId == _main_user_id) && (_start_call != "2")){
          _userManager.updateValue("status", "updated" , updated,docId: _id!);
        }*/
      }

      _changeVideoMode = data['change_video_mode'];
      _liveNearlyClosed = data['live_nearly_closed'];
      notifyListeners();

    }
  }

  void onGestureUpdate(Point point, Point previousPoint) {
    if (_tool == Tool.pen) {
      if (_currentLine != null) {
        _currentLine!.points.add(point);
        notifyListeners();
      }

    } else if (_tool == Tool.eraser) {
      _remove(point, previousPoint);
    }
  }


  void onGestureEnd() async {
    if (_tool == Tool.pen) {

      _content = WhiteboardContent([...?_content.lines, _currentLine], /*(_user_id == _userManager.userId) ? _user_id :*/ _helper_id);
      //_writtenIds.clear();
      //_writtenIds.add(_id);


      _callable!.call(
          {
            'whiteboardId':_id,
            'isWriting': /*(_user_id == _userManager.userId) ? _user_id :*/ _helper_id,
            'lines':_currentLine!.toJson()
          }
      );

      _currentLine = null;
      notifyListeners();
    }
  }

  void selectTool(Tool tool) {
    _tool = tool;
    notifyListeners();
  }

  void _remove(Point point1, [Point? point2]) {
    point2 ??= point1;

    final lines = _content.lines?.where((line) {
      if (line != null){
        if (line.points.length == 1) {
          final point = line.points.first;
          return _rectanglesIntersect(
            Point(point!.x - 0.01, point.y - 0.01),
            Point(point.x + 0.01, point.y + 0.01),
            point1,
            point1,
          );
        } else {
          for (var i = 0; i < line.points.length - 1; i++) {
            if (_rectanglesIntersect(
                line.points[i]!, line.points[i + 1]!, point1, point2!)) {
              return false;
            }
          }
          return true;
        }
      }
      else{
        return false;
      }

    }).toList();

    if (lines?.length != _content.lines?.length) {

      var firstPart = lines!.toSet();
      var secondPart = _content.lines!.toSet();

      var linesToRemove = firstPart.union(secondPart).difference(firstPart.intersection(secondPart)).toList();

      _content = WhiteboardContent(lines,/*(_user_id == _userManager.userId) ? _user_id :*/ _helper_id);

      _whiteboardRef!.set({
        "lines": FieldValue.arrayRemove([linesToRemove.first!.toJson()]),
      },
          SetOptions(merge: true)
      );

      notifyListeners();
    }
  }

  bool _rectanglesIntersect(
      Point point11,
      Point point12,
      Point point21,
      Point point22,
      ) =>
      _rectangleContainsPoint(point11, point12, point21) ||
          _rectangleContainsPoint(point11, point12, point22) ||
          _rectangleContainsPoint(point21, point22, point11);

  bool _rectangleContainsPoint(
      Point rectangle1, Point rectangle2, Point contained) =>
      contained.x >= min(rectangle1.x, rectangle2.x) &&
          contained.x <= max(rectangle1.x, rectangle2.x) &&
          contained.y >= min(rectangle1.y, rectangle2.y) &&
          contained.y <= max(rectangle1.y, rectangle2.y);

  void _onContentSnapshot(DocumentSnapshot snapshot) {
    if (snapshot.data() == null) {
      return;
    }

    if (snapshot.data() != null){

      final content = WhiteboardContent.fromJson(snapshot.data()! as Map<String, dynamic>);

      if (content.isWriting != (/*(_user_id == _userManager.userId) ? _user_id :*/ _helper_id)){
        if (lines.length != content.lines?.length){

          if (!_writtenIds.contains(_id)) {
            _content = content;
          } else {
            _writtenIds = _writtenIds.sublist(_writtenIds.indexOf(_id) + 1);
          }
          notifyListeners();
        }
      }
    }
  }

  void deleteAllFiles(){
    if (sharedFiles.isNotEmpty) {
      sharedFiles.forEach((file) {
        FirebaseStorage.instance.refFromURL(file).delete();
      });
    }
  }

  void removeLastLine(){
    if(lines.length > 0){

      _whiteboardRef!.set({
        "lines": FieldValue.arrayRemove([lines.last!.toJson()]),
      },
          SetOptions(merge: true)
      );

      _content = WhiteboardContent(lines.sublist(0, lines.length - 1),/*(_user_id == _userManager.userId) ? _user_id :*/ _helper_id);

      notifyListeners();
    }
  }

  void updateHelperId(String helperId){
    _helper_id = helperId;
  }

  void clearWhiteboard(){
    if(lines.length > 0){
      _content = WhiteboardContent([],/*(_user_id == _userManager.userId) ? _user_id :*/ _helper_id);
      _whiteboardRef!.set(
          _content.toJson(),
          SetOptions(merge: true)
      );
      notifyListeners();
    }
  }

  void switchVideoAudienceMode(bool state){
    _changeVideoMode = state;
    notifyListeners();
  }


  Future<void> updateMoreUsers(bool enableAddUser, {int index = 0, bool mainUserHasLeft = false}) async {

    var selectedUser = (enableAddUser ? moreUsers.removeLast() : moreUsers.removeAt(index));

    List<dynamic> updatedUsers = [];

    updatedUsers = List.from(moreUsers);

    if(!mainUserHasLeft){
      updatedUsers.add({
        "avatarUrl":usersAvatars[0],
        "userId": _main_user_id,
        "name":_main_caller_name,
        "lastUpdatedServer":0
      });

      /*await _userManager.updateMultipleValues(
          "status",
          {
            _main_user_id:0,
          },
          docId: _id!
      );*/

    }

    /*await _userManager.updateMultipleValues(
        "temporaryUsersFilesLinks",
        {
          'swapUserId': enableAddUser ? "": selectedUser["userId"],
          'moreUsers':updatedUsers,
          'usersAvatars': [selectedUser["avatarUrl"],usersAvatars[1]],
          'caller_id': selectedUser["userId"],
          'caller_name':selectedUser["name"],
        },
        docId: _id!
    );*/

    /*await _userManager.updateMultipleValues(
        "whiteboards",
        {
          'caller_id': selectedUser["userId"],
        },
        docId: _id!
    );*/

  }

  @override
  void dispose() {
    super.dispose();
    _subscription!.cancel();
    _subscriptionImage!.cancel();
  }

}