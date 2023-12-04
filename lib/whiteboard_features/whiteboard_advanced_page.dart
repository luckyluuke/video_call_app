import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
//import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:diacritic/diacritic.dart';
import 'package:draggable_widget/draggable_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_call_app/eraser_display.dart';
import 'package:video_call_app/maintenance_page.dart';
import 'package:video_call_app/flying_dots_animation.dart';
import 'package:video_call_app/zoom_widget.dart';
import 'package:video_call_app/shake_widget.dart';
import 'package:video_call_app/UserManager.dart';
import 'package:video_call_app/enums.dart';
import 'package:video_call_app/whiteboard_features/signaling.dart';
import 'package:video_call_app/whiteboard_features/whiteboard_view_model.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:video_call_app/whiteboard_features/widgets/tool_buttons.dart';
import 'package:video_call_app/whiteboard_features/widgets/whiteboard_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_ripple_animation/simple_ripple_animation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;

import 'package:square_percent_indicater/square_percent_indicater.dart';


const int billion = 1000000000;
const int one_million = 1000000;
const int hundred_thousand = 100000;
const int ten_thousand = 10000;
const int maxSearch = 20; //old: 10
const int intervalSearchStep = 5; //old: 10



class WhiteboardPageAdvanced extends StatefulWidget {
  WhiteboardPageAdvanced(this.whiteboardId, this.token_call, this.fromPreviousTime, this.helperId, var signaling /*Signaling? _signaling*/,RTCVideoRenderer? _localRenderer,RTCVideoRenderer? _remoteRenderer, this.callerAvatar, this.isNewUser,this.pseudo,this.searchInput,this.enableAutoResearch, this.serverDestination, this.isMoreUser,this.isBotChecker, this.userIdParam,{List? moreUsersAttending = null, String fullSpotPathOption = "",bool receiverIsHelper=true, String globalUserCountryCode = ""}) :
        signaling = null/*(_signaling != null ? _signaling : Signaling(serverDestination))*/,
        localRenderer = (_localRenderer != null ? _localRenderer : RTCVideoRenderer()),
        remoteRenderer = (_remoteRenderer != null ? _remoteRenderer : RTCVideoRenderer()),
        moreUsersAttending = moreUsersAttending,
        fullSpotPathOption = fullSpotPathOption,
        receiverIsHelper = receiverIsHelper,
        globalUserCountryCode = globalUserCountryCode,
        remoteRendererSecondUser = RTCVideoRenderer();


  final String? whiteboardId;
  String searchInput;
  final int fromPreviousTime;
  final String token_call;
  final String helperId;
  final String userIdParam;
  final String serverDestination;
  var signaling; //Signaling signaling;
  RTCVideoRenderer localRenderer;
  RTCVideoRenderer remoteRenderer;
  RTCVideoRenderer? remoteRendererSecondUser;
  String? callerAvatar;
  String? isNewUser;
  String? pseudo;
  bool enableAutoResearch;
  bool isMoreUser;
  bool isBotChecker;
  bool receiverIsHelper;
  List? moreUsersAttending;
  String fullSpotPathOption;
  String globalUserCountryCode;


  @override
  State<WhiteboardPageAdvanced> createState() => _WhiteboardPageAdvancedState(whiteboardId, token_call, fromPreviousTime, helperId, signaling,localRenderer,remoteRenderer,callerAvatar,isNewUser,pseudo, searchInput, enableAutoResearch, serverDestination, isMoreUser, isBotChecker, remoteRendererSecondUser, moreUsersAttending, fullSpotPathOption, receiverIsHelper,userIdParam,globalUserCountryCode);
}

class _WhiteboardPageAdvancedState extends State<WhiteboardPageAdvanced> with WidgetsBindingObserver {
  //const WhiteboardPage({Key? key}) : super(key: key);
  _WhiteboardPageAdvancedState(String? whiteboardId, String token_call_id, int fromPreviousTime, String helperId, var signaling /*Signaling signaling*/,RTCVideoRenderer localRenderer,RTCVideoRenderer remoteRenderer,String? callerAvatar,String? isNewUser, String? pseudo, String searchInput,bool enableAutoResearch, String serverDestination, bool isMoreUser, bool isBotChecker, RTCVideoRenderer? remoteRendererSecondUser, List? moreUsersAttending, String? fullSpotPathOption, bool receiverIsHelper, String userIdParam, String globalUserCountryCode){
    this.whiteboardId = whiteboardId;
    this.fromPreviousTime = fromPreviousTime;

    //TODO:Uncomment this
    //this.token_call_id = token_call_id;
    this.roomId = token_call_id;
    this._helperId = helperId;
    this._userId = userIdParam;
    this.signaling = signaling;
    this._localRenderer = localRenderer;
    this._remoteRenderer = remoteRenderer;
    this.callerAvatar = callerAvatar;
    this.isNewUser = isNewUser;
    this.pseudo = pseudo;
    this.searchInput = searchInput;
    this.enableAutoResearch = enableAutoResearch;
    this.serverDestination = serverDestination;
    this.isMoreUser = isMoreUser;
    this.isBotChecker = isBotChecker;
    this._remoteRendererSecondUser = remoteRendererSecondUser;
    this.moreUsersAttending = moreUsersAttending;
    this.fullSpotPathOption = fullSpotPathOption;
    this.receiverIsHelper = receiverIsHelper;
    this.globalUserCountryCode = globalUserCountryCode;
  }

  var signaling; //Signaling? signaling;
  RTCVideoRenderer? _localRenderer;
  RTCVideoRenderer? _remoteRenderer;
  RTCVideoRenderer? _remoteRendererSecondUser;

  List? moreUsersAttending;
  String? fullSpotPathOption;
  String? roomId;
  bool newUserAdded = false;
  bool secondUserAdded = false;
  bool showButtons = true;
  bool hasSwitchedDisplay = false;
  Timer? customTimer;
  String searchInput = "";
  bool enableAutoResearch = false;
  bool isMoreUser = false;
  bool algorithmStarted = false;
  bool receiverIsHelper = true;
  String not_found = "";
  String? serverDestination;
  bool isBotChecker = false;
  bool isBotCheckerDone = false;
  int sharingRepeatDialogState = 0;

  bool timerActivated = false;
  bool currentSwapUserIdUpdated = false;
  int previousAddedNewCallerLength = 0;
  String currentSwapUserId = "";
  String? returnURL = null;
  String? whiteboardId;
  String? callerAvatar;
  String? isNewUser;
  String? pseudo;
  final ScrollController _controller = ScrollController();
  int imagesIndex = 0;
  bool showCalling = true;
  bool showSearchMore = false;
  double _progress = 0.0;
  Timer? progressTimer;
  Timer? endCallTimer;
  bool progressTimerStarted = false;
  bool spotHelperCheckerDone = false;
  String globalUserCountryCode = "";

  //AgoraClient? client; //TODO:Uncomment this
  String? _helperId;
  String? _userId;
  String _helperName = "";

  String token_call_id = "";
  bool changeVideoMode = false;
  bool pictureTakenFromCamera = false;

  final ScrollController _controllerOne = ScrollController();
  double controllerOneScrollOffset = 0;
  User? user = FirebaseAuth.instance.currentUser;
  int fromPreviousTime = 0;
  String lastHelperTemporaryId = '';
  String? displayTimeInHoursMinuteSeconds='00:00:00';
  int likedButtonTapped = 0;
  bool isLiked = false;
  int thresholdLikes = 1;
  int current_duration_live = 0;
  int buttonPressed = 0;
  int buttonVipPressed = 0;
  bool buttonQuit = false;
  UserManager _userManager = UserManager();
  bool stopActivity = false;
  bool forceQuitChannel = false;
  bool localVideoChange = false;
  bool showAlertMessage = false;
  Timer? timerAutoResearch;
  Completer? timerAutoResearchCompleter;
  //NotificationApi? timerManagement;
  List foundAvailableRoom = [];

  Reference ref = FirebaseStorage.instance.ref();
  String defaultAvatarURL = '';
  StreamSubscription? subscription;

  bool isCameraSwitched = false;
  bool isMicMuted = false;
  bool isVideoDisabled = false;
  bool isSharingScreen = false;


  void initCallingTimer(WhiteboardViewModel viewModel){
    if(((_helperId != null) && (_helperId != _userManager.userId) && !isMoreUser && !isBotChecker) || (fullSpotPathOption!.isNotEmpty && ('2' != viewModel.startCall))){
      progressTimerStarted = true;
      progressTimer = Timer.periodic(Duration(milliseconds: enableAutoResearch ?  100 : 35), (timer) {


        if(((progressTimer != null) && ('2' == viewModel.startCall)) || stopActivity){
          progressTimer?.cancel();
          progressTimer = null;
        } else if((progressTimer != null) && (_progress == 1.0)){

          progressTimer!.cancel();
          progressTimer = null;

          if(!enableAutoResearch && ("2" != viewModel.startCall)){
            endCallNow("L'interlocuter ne répond pas pour le moment. Réessaies encore.", viewModel);
          }

        }else{
          double updatedValue = _progress + 0.001;//0.0000055;
          setState(() {
            _progress = (updatedValue < 1.0) ? updatedValue : 1.0;
          });
        }

      });
    }
  }

  Future<void> endRtcLiveCall(bool canDelete) async {
    await signaling!.hangUp(_localRenderer!,canDelete: canDelete);
  }

  Future<void> sendMissedCallNotification() async {
    HttpsCallable sendNotificationCallable = await FirebaseFunctions.instanceFor(app: FirebaseFunctions.instance.app, region: "europe-west1").httpsCallable('sendNotification');

    sendNotificationCallable.call(<String, dynamic>{
      "type":"BASIC_NOTIFICATION",
      "notificationId": "",
      "notificationReminderId":"",
      "receiverId": receiverIsHelper? _helperId : _userId,
      "peerTemporaryId":"",
      "scheduledTime":"",
      "scheduledDay": "",
      "scheduledHour": "",
      "senderPseudo":"",
      "repeat":"",
      "title":"",
      "message":"Appel manqué. @$pseudo a essayé de te joindre",
    });
  }

  sendNotificationToHelper(String roomId) async {

    HttpsCallable sendNotificationCallable = await FirebaseFunctions
        .instanceFor(
        app: FirebaseFunctions.instance.app, region: "europe-west1")
        .httpsCallable('sendNotification');

    sendNotificationCallable.call(<String, dynamic>{
      "type": "LIVE_AUTO_SEARCH_CALL",
      "nameCaller": pseudo,
      "callerAvatar": callerAvatar,
      "whiteboardId": whiteboardId,
      "receiverId": receiverIsHelper? _helperId : _userId,
      "callerUid": _userManager.userId,
      "tokenCallId":roomId,
      "isCallerNewUser":isNewUser.toString(),
      "dest":serverDestination,
      "spotDest":fullSpotPathOption! + "|" + receiverIsHelper.toString(),
    });

  }

  void resetParameters({required String not_found_state, String p_level="", String p_class_level="", String p_subject = ""}){
    not_found = not_found_state;
  }

  static String? _getVideoId(String url) {
    try {
      var id = '';
      id = url.substring(url.indexOf('?v=') + '?v='.length);

      return 'https://www.youtube.com/get_video_info?video_id=${id}&el=embedded&ps=default&eurl=&gl=US&hl=en';
    } catch (e) {
      return null;
    }
  }

  /*static Future<List<String>> getVideoUrlFromYoutube(String youtubeUrl) async {
    // Extract the info url using the past method
    var link = _getVideoId(youtubeUrl);

    // Checker if the link is valid
    if (link == null) {
      print('Null Video Id from Link: $youtubeUrl');
      //Logger().error('Player Error', 'Null Video Id from Link: $youtubeUrl');
    }

    // Links Holder
    var links = <String>[]; // This could turn into a map if one desires it

    // Now make the request
    var networkClient = Dio();
    var response = await networkClient.get(link);

    // To make autocomplete easier
    var responseText = response.data.toString();

    // This sections the chuck of data into multiples so we can parse it
    var sections = Uri.decodeFull(responseText).split('&');

    // This is the response json we are looking for
    var playerResponse = <String, dynamic>{};

    // Optimized better
    for (int i = 0; i < sections.length; i++) {
      String s = sections[i];

      // We can have multiple '=' inside the json, we want to divide the chunk by only the first equal
      int firstEqual = s.indexOf('=');

      // Sanity Check
      if (firstEqual < 0) {
        continue;
      }

      // Here we create the key value of the chunk of data
      String key = s.substring(0, firstEqual);
      String value = s.substring(firstEqual + 1);

      // This is the key that holds the mp4 information
      if (key == 'player_response') {
        playerResponse = jsonDecode(value);
        break;
      }
    }

    // Now that we have the json we need, we can start pointing to the links that holds the mp4
    // The node we need
    Map data = playerResponse['streamingData'];

    // Aggregating the data
    if (data['formats'] != null) {
      var formatLinks = [];
      formatLinks = data['formats'];
      if (formatLinks != null) {
        formatLinks.forEach((element) {
          // you can read the map here to get additional video infomation
          // like quality width height and bitrate
          // For this example however I just want the url
          links.add(element['url']);
        });
      }
    }

    // And adaptive ones also
    if (data['adaptiveFormats'] is List) {
      var formatLinks = [];
      formatLinks = data['adaptiveFormats'];
      formatLinks.forEach((element) {
        // you can read the map here to get additional video infomation
        // like quality width height and bitrate
        // For this example however I just want the url
        links.add(element['url']);
      });
    }

    // Finally return the links for the player
    return links.isNotEmpty
        ? links
        : [
      '<Holder Video>' // This video Url will be the url we will use if there is an error with the method. Because we don't want to break do we? :)
    ];

  }*/

  Future<Timer> _delayed(Duration duration) async {
    final completer = Completer();
    final timer = Timer(duration, () {
      completer.complete();
    });
    await completer.future;
    return timer;
  }

  Future<bool> findHelper(List listOfHelpers, String nameCaller, String callerAvatar, String whiteboardId, String tokenCallId, String isNewUser, WhiteboardViewModel viewModel, int countryIndex, int maxCountries) async {

    bool helperFoundSuccess = false;
    bool exitResearch = false;

    List temporaryHelpers = List.from(listOfHelpers);
    int numOfHelpersContacted = 0;

    for (int i=0;i<listOfHelpers.length;i++){

      if((viewModel.startCall == '2') || (viewModel.startCall == '0') || (temporaryHelpers.isEmpty) || (numOfHelpersContacted >= maxSearch)){
        helperFoundSuccess = true;
        _helperId = viewModel.helperId;
        break;
      }

      Random random = new Random();
      int numOfHelpers = temporaryHelpers.length;
      int randomIndex = random.nextInt(numOfHelpers);
      List subListOfHelpers = [];
      int nextValue = randomIndex + intervalSearchStep;

      if (numOfHelpers > intervalSearchStep){
        if((nextValue) > numOfHelpers){
          int previousValue = randomIndex - intervalSearchStep;
          if(previousValue < 0){
            subListOfHelpers = List.from(temporaryHelpers.sublist(0,intervalSearchStep));
            temporaryHelpers.removeRange(0, intervalSearchStep);
          }else{
            subListOfHelpers = List.from(temporaryHelpers.sublist(previousValue,randomIndex));
            temporaryHelpers.removeRange(previousValue, randomIndex);
          }
        }else{
          subListOfHelpers = List.from(temporaryHelpers.sublist(randomIndex,nextValue));
          temporaryHelpers.removeRange(randomIndex, nextValue);
        }
      }else{
        subListOfHelpers = List.from(temporaryHelpers);
        temporaryHelpers.clear();
      }

      for (int i=0;i<subListOfHelpers.length;i++){
        var helperId = subListOfHelpers[i];
        if (helperId != _userManager.userId!){

          final helperPending = await FirebaseFirestore.instance.collection("allPendingHelpers").where("helperId", isEqualTo:helperId).get();

          if (helperPending.docs.isEmpty){

            final helper = await FirebaseFirestore.instance.collection("allHelpers").where("isUserActive", isEqualTo:true).where("live_status", isEqualTo:LiveStatus.AVAILABLE).where("live_button_id", isEqualTo:helperId).where("token_firebasemsg_id",isNotEqualTo: "BOT_GENERATED").get();

            if (helper.docs.isNotEmpty){

              var createdTime = DateTime.now().microsecondsSinceEpoch;

              HttpsCallable initPendingHelperCheckerCallable = await FirebaseFunctions
                  .instanceFor(
                  app: FirebaseFunctions.instance.app, region: "europe-west1")
                  .httpsCallable('initPendingHelperChecker');

              initPendingHelperCheckerCallable.call(<String, dynamic>{
                "helperId": helperId,
                "created": createdTime
              });

              HttpsCallable sendNotificationCallable = await FirebaseFunctions
                  .instanceFor(
                  app: FirebaseFunctions.instance.app, region: "europe-west1")
                  .httpsCallable('sendNotification');

              sendNotificationCallable.call(<String, dynamic>{
                "type": "LIVE_AUTO_SEARCH_CALL",
                "nameCaller": nameCaller,
                "callerAvatar": callerAvatar,
                "whiteboardId": whiteboardId,
                "receiverId": helperId,
                "callerUid": _userManager.userId,
                "tokenCallId":tokenCallId,
                "isCallerNewUser":isNewUser,
                "dest":serverDestination,
                "spotDest":fullSpotPathOption! + "|" + receiverIsHelper.toString()
              });

              numOfHelpersContacted = numOfHelpersContacted + 1;
            }

          }

        }
      }

      if((numOfHelpersContacted != 0) && (numOfHelpersContacted < maxSearch) && ((numOfHelpersContacted % intervalSearchStep) == 0)) {
        await Future.delayed(Duration(seconds: 30));
      }

      if((temporaryHelpers.isEmpty || (numOfHelpersContacted >= maxSearch)) && !exitResearch){
        exitResearch = true;
        timerAutoResearchCompleter = Completer();
        timerAutoResearch = Timer(const Duration(seconds: 30), () async {
          if (viewModel.startCall != "2"){
            //TODO: Just for testing purpose
            //bool foundHelper = await findAvailableRoom(["fPSuuVCvD7Mc2ubscl4bJ1uiR4u2"]);//fPSuuVCvD7Mc2ubscl4bJ1uiR4u2 ; rrirdIOkyqaCIvYahORFRkDkFNr2

            bool foundHelper = await findAvailableRoom(listOfHelpers);

            if(foundHelper){
              helperFoundSuccess = true;
              stopActivity = true;

              await endRtcLiveCall(true);
              deleteWhiteboardAndFiles();

              _localRenderer!.srcObject = null;
              _remoteRenderer!.srcObject = null;

              var currentWhiteboardId = foundAvailableRoom[1];
              await _userManager.updateMultipleValues(
                  "allUsers",
                  {
                    'whiteboard_id': currentWhiteboardId,
                    'live_status': LiveStatus.OCCUPIED,
                    'peer_temporary_id': foundAvailableRoom[0] + "|" +
                        isNewUser.toString().toLowerCase(),
                    'channel_name_call_id': '',
                    'last_duration_live':0,
                    'last_helper_temporary_id': foundAvailableRoom[0],
                    'last_role_live': 'consumer',
                    'calling_state': 'O',
                    'token_call_id':'',
                  });

              Navigator.pushReplacement(context, WhiteboardPageAdvancedRoute(
                  currentWhiteboardId,
                  currentWhiteboardId,
                  serverDestination: foundAvailableRoom[2],
                  userId: _userManager.userId!,
                  helperId: foundAvailableRoom[0],
                  callerAvatar: callerAvatar,
                  isNewUser: isNewUser.toString(),
                  pseudo: pseudo,
                  searchInput: "",
                  enableAutoResearch: false,
                  isMoreUser: true
              ));

            }else{
              if((countryIndex+1) == maxCountries){
                endCallNow("Aucune personne disponible pour le moment. Renouvelles ta demande.", viewModel);
              }
            }

          }else {
            helperFoundSuccess = true;
            _helperId = viewModel.helperId;
          }

          timerAutoResearchCompleter!.complete();

        });

        /*await timerAutoResearchCompleter!.future;
        break;*/
      }

      if(exitResearch){
        await timerAutoResearchCompleter!.future;
        break;
      }

    }

    return helperFoundSuccess;

  }

  Future<bool> findAvailableRoom(List listOfHelpers) async {
    List temporaryHelpers = List.from(listOfHelpers);
    bool foundHelper = false;

    for (int i=0;i<listOfHelpers.length;i++){
      if(foundHelper || temporaryHelpers.isEmpty){
        break;
      }

      Random random = new Random();
      int numOfHelpers = temporaryHelpers.length;
      int randomIndex = random.nextInt(numOfHelpers);
      List subListOfHelpers = [];
      int nextValue = randomIndex + 10;

      if (numOfHelpers > 10){
        if((nextValue) > numOfHelpers){
          int previousValue = randomIndex - 10;
          if(previousValue < 0){
            subListOfHelpers = List.from(temporaryHelpers.sublist(0,10));
            temporaryHelpers.removeRange(0, 10);
          }else{
            subListOfHelpers = List.from(temporaryHelpers.sublist(previousValue,randomIndex));
            temporaryHelpers.removeRange(previousValue, randomIndex);
          }
        }else{
          subListOfHelpers = List.from(temporaryHelpers.sublist(randomIndex,nextValue));
          temporaryHelpers.removeRange(randomIndex, nextValue);
        }
      }else{
        subListOfHelpers = List.from(temporaryHelpers) ;
        temporaryHelpers.clear();
      }

      for (int i=0;i<subListOfHelpers.length;i++){
        var helperId = subListOfHelpers[i];
        if (helperId != _userManager.userId!){
          final helper = await FirebaseFirestore.instance.collection("allHelpers").where("isUserActive", isEqualTo:true).where("live_status", isEqualTo:LiveStatus.OCCUPIED).where("live_button_id", isEqualTo:helperId).get();

          if (helper.docs.isNotEmpty){

            final activeCall = await FirebaseFirestore.instance.collection("temporaryUsersFilesLinks").where("helper_id", isEqualTo:helperId).get();

            if (activeCall.docs.isNotEmpty){
              List tmpMoreUsers = activeCall.docs[0].get("moreUsers");
              if (tmpMoreUsers.length < 2){
                foundAvailableRoom.addAll([helperId,activeCall.docs[0].id,activeCall.docs[0].get("dest")]);
                foundHelper = true;
                break;
              }
            }
          }
        }
      }

    }

    return foundHelper;

  }

  void endCallNow(String message, WhiteboardViewModel viewModel){
    if(progressTimer != null){
      progressTimer!.cancel();
      progressTimer = null;
    }

    resetParameters(not_found_state: message);

    viewModel.deleteCallActivity();

    WidgetsBinding.instance.addPostFrameCallback((_) {

      setState((){
        showCalling = false;
      });

      endCallTimer = Timer(const Duration(seconds: 5), (){
        Navigator.pop(context);
      });

      //showNoHelperFoundDialog("Aucune personne trouvée ou disponible. Essaies de modifier ta recherche.");
    });
  }

  void showNoHelperFoundDialog(String message){
    Timer t = Timer(const Duration(seconds: 5), (){
      Navigator.pop(context);
    });

    showDialog(
        barrierDismissible: true,
        context: context,
        builder: (context) {

          return AlertDialog(
            title: Text(
                message,
                style: GoogleFonts.inter(
                  color: Colors.grey,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                textAlign:TextAlign.center
            ),
          );
        }
    ).then((value) {
      t.cancel();
      Navigator.pop(context);
    });
  }

  Future<bool> searchAlgorithm(String whiteboardId, String tokenCallId, String nameCaller, String callerAvatar, String isNewUser, WhiteboardViewModel viewModel) async {

    bool algorithmSuccess = true;
    List localizations = g_countriesGeoLocalization[globalUserCountryCode];

    for(int countryIndex=0;countryIndex<localizations.length;countryIndex++){

      if(countryIndex == 1){
        setState(() {
          showSearchMore = true;
        });
      }

      if((viewModel.startCall == '2') || (viewModel.startCall == '0')){
        _helperId = viewModel.helperId;
        break;
      }

      debugPrint("DEBUG_LOG AUTO WORLD RESEARCH started with country="+localizations[countryIndex]);
      List listOfKeyWords = [];

      resetParameters(not_found_state: "");

      String selectedAllKeyWords = (localizations[countryIndex] == "FR") ? "allKeyWords" : ("allKeyWords" + localizations[countryIndex]);

      try{

        if (widget.searchInput.isNotEmpty){
          Query? queryKeyWords = FirebaseFirestore.instance.collection(selectedAllKeyWords);

          List listOfUsers = [];

          final userSearchRequest = widget.searchInput.trim().split(" ");
          List<int> skipWords = [];
          for(int i=0; i<userSearchRequest.length;i++)
          {
            var elementToSearch = removeDiacritics(userSearchRequest.elementAt(i).trim());

            if (!skipWords.contains(i)){
              if ((i+1) < userSearchRequest.length)
              {
                String currentElement = removeDiacritics(userSearchRequest.elementAt(i).trim()+"_"+userSearchRequest.elementAt(i+1).trim());
                var KeyWordValue = await queryKeyWords.where(FieldPath.documentId, isEqualTo: currentElement).limit(1).get();

                if (KeyWordValue.docs.length > 0)
                {
                  elementToSearch = currentElement;
                  skipWords.add(i+1);
                }
              }


              if ((i+2) < userSearchRequest.length) {
                String currentElement = removeDiacritics(userSearchRequest.elementAt(i).trim()+"_"+userSearchRequest.elementAt(i+1).trim()+"_"+userSearchRequest.elementAt(i+2).trim());
                var KeyWordValue = await queryKeyWords.where(FieldPath.documentId, isEqualTo: currentElement).limit(1).get();
                if (KeyWordValue.docs.length > 0)
                {
                  elementToSearch = currentElement;
                  skipWords.add(i+1);
                  skipWords.add(i+2);
                }
              }

              if ("but" == removeDiacritics(userSearchRequest.elementAt(i).trim())
                  || "dut" == removeDiacritics(userSearchRequest.elementAt(i).trim()))
              {
                elementToSearch = "but_dut";
              }
            }

            listOfKeyWords.add(elementToSearch);
          }

          skipWords.clear();

          try{

            listOfKeyWords.toSet().toList();

            if (listOfKeyWords.length > 10){
              listOfKeyWords = List.from(listOfKeyWords.sublist(0,10));
            }

            var tmpQuerySnapshot = await queryKeyWords.where(FieldPath.documentId, whereIn: listOfKeyWords).get();
            listOfKeyWords.clear();
            for (int i=0; i<tmpQuerySnapshot.docs.length; i++){
              listOfKeyWords.add(tmpQuerySnapshot.docs[i].id);
              if (i==0){
                listOfUsers = tmpQuerySnapshot.docs[i].get("listOfUsers");
              }else {
                listOfUsers = listOfUsers.toSet().intersection(tmpQuerySnapshot.docs[i].get("listOfUsers").toSet()).toList();
              }
            }
          }catch(error){
            resetParameters(not_found_state: "Aucun résultat trouvé");
          }

          //TODO:Comment this part for production (testing purpose only)
          //listOfUsers = ["fPSuuVCvD7Mc2ubscl4bJ1uiR4u2"];
          //listOfUsers = ((localizations[countryIndex] == "FR") || (localizations[countryIndex] == "NE")) ? ["fPSuuVCvD7Mc2ubscl4bJ1uiR4u2"] : []; //fPSuuVCvD7Mc2ubscl4bJ1uiR4u2 //rrirdIOkyqaCIvYahORFRkDkFNr2
          //listOfUsers.removeWhere((element) => element.contains("-"));

          if (listOfUsers.isNotEmpty){
            bool foundHelper =  await findHelper(listOfUsers,nameCaller, callerAvatar, whiteboardId, tokenCallId,isNewUser,viewModel,countryIndex,localizations.length);

            if(foundHelper){
              _helperId = viewModel.helperId;
              //TODO: ZAMBA find way to remove old route
              break;
            }

          }else {
            if ((countryIndex + 1) == localizations.length){
              endCallNow("Aucune personne disponible pour le moment. Renouvelles ta demande.", viewModel);
            }
          }

          //return true;
        }else{
          algorithmSuccess = false;
          endCallNow("Aucune personne disponible pour le moment. Renouvelles ta demande.", viewModel);
          break;
          //return false;
        }

      }catch(error){
        debugPrint("DEBUG_LOG 2 ALERT ERROR $error");
        algorithmSuccess = false;
        endCallNow("Il semblerait qu'il n'y ait personne pour le moment. Réessaies encore.", viewModel);
        break;
        //return false;
      }
    }

    return algorithmSuccess;

  }

  initVideoCall() async {

    signaling!.onAddRemoteStream = ((stream) {

      if (!signaling!.changeVideoMode){
        signaling!.switchVideoMode();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _userManager.updateValue("temporaryUsersFilesLinks", "change_video_mode", true, docId: whiteboardId!);
        });
      }

      _remoteRenderer!.srcObject = stream;

      if(!signaling!.localStream!.getAudioTracks()[0].enabled && (_userManager.userId != _helperId)) {
        isMicMuted = false;
        signaling!.localStream!.getAudioTracks()[0].enabled = true;
      }
      if(!signaling!.localStream!.getVideoTracks()[0].enabled && (_userManager.userId != _helperId)) {
        isVideoDisabled = false;
        signaling!.localStream!.getVideoTracks()[0].enabled = true;
      }

      setState(() {
        newUserAdded = true;
      });

    });

    signaling!.onConnectionState = ((state) {

      if(state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected){

        setState(() {
          newUserAdded = false;
        });

        if((_helperId != null) && (_helperId != _userManager.userId) && _helperId!.isNotEmpty){
          /*NotificationApi.createNormalNotificationBasicChannel(
              NotificationId.USER_LEFT,
              "La session a été suspendue",
              "Tu as quitté la session actuelle."
          );*/
        }
      }
    });



    signaling!.onSecondUserAddRemoteStream = ((stream) {
      _remoteRendererSecondUser!.srcObject = stream;
      setState(() {
        secondUserAdded = true;
      });
    });

    signaling!.onSecondUserConnectionState = ((state) {
      if(state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected){
        //signaling!.stopSession(_localRenderer!);
        setState(() {
          secondUserAdded = false;
        });
      }
    });



    await signaling!.openUserMedia(_localRenderer!, _remoteRenderer!, _remoteRendererSecondUser);

    if (((_userManager.userId != _helperId) && receiverIsHelper) || (!receiverIsHelper && (_userManager.userId == _helperId))){
      if(isBotChecker){
        await signaling!.addUsers(
            roomId!,
            //avatarUrl: callerAvatar!,
            //name: pseudo!,
            isBotChecker: isBotChecker,
            users: moreUsersAttending!
        );
      }else if (isMoreUser){
        await signaling!.updateRoom(
            roomId!,
            avatarUrl: callerAvatar!,
            name: pseudo!
        );
      }else{
        roomId = await signaling!.createRoom(whiteboardId!);

        if (!enableAutoResearch){
          sendNotificationToHelper(roomId!);
        }
      }

    }else{
      signaling!.joinRoom(
          roomId!,
          0
      );
    }
  }

  Widget videoRenderersSaloon(List usersAvatars, String mainHelperName, String mainCallerName, bool changeVideoMode){

    return changeVideoMode ?
    (
        usersAvatars.isNotEmpty ?
        Stack(
          children: [
            InkWell(
                onTap:(){
                  setState(() {
                    showButtons = true;
                    customTimer = Timer(const Duration(seconds: 3), (){
                      setState(() {
                        showButtons = false;
                      });
                    });
                  });
                },
                child:
                Stack(
                  children: [
                    Container(
                      color: Colors.black87,
                      child: RippleAnimation(
                        repeat: true,
                        color: Colors.white,
                        minRadius: 22,
                        ripplesCount: 12,
                        child: Container(
                          margin: EdgeInsets.all(100),
                          decoration: BoxDecoration(
                            color: Colors.pink,
                            shape: BoxShape.circle,
                            image: DecorationImage(
                                fit: BoxFit.contain,
                                image: NetworkImage(usersAvatars[1])
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10,top: 50),
                        child: Container(
                          width: mainHelperName.length > 9 ? 70 : null,
                          height: 20,
                          padding: const EdgeInsets.only(left: 5, right:  5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: Colors.black12,
                          ),
                          child: Text(
                            mainHelperName.toLowerCase(),
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,

                          ),
                        ),
                      ),
                    )
                  ],
                )
            ),
            if (usersAvatars.length > 1)
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  width: MediaQuery.of(context).size.width/5,
                  height: MediaQuery.of(context).size.height/10,
                  margin: EdgeInsets.fromLTRB(0, 0, 10.0, 10.0),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.blueAccent,
                      border: Border.all(color: Colors.blueAccent)
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Container(
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.blueAccent)
                        ),
                        child:
                        Stack(
                          children: [
                            Container(
                              color: Colors.black87,
                              child: RippleAnimation(
                                repeat: true,
                                color: Colors.white,
                                minRadius: 22,
                                ripplesCount: 8,
                                child: Container(
                                  margin: EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.pink,
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                        fit: BoxFit.contain,
                                        image: NetworkImage(usersAvatars[0])
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 2,bottom: 2),
                                child: Container(
                                  width: mainCallerName.length > 9 ? 70 : null,
                                  height: 15,
                                  padding: const EdgeInsets.only(left: 5, right:  5),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    color: Colors.black12,
                                  ),
                                  child: Text(
                                    mainCallerName.toLowerCase(),
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,

                                  ),
                                ),
                              ),
                            )
                          ],
                        )
                    ),
                  ),
                ),
              )
          ],
        )
            :
        Container()
    )

        :

    (
        usersAvatars.isNotEmpty ?
        Column(
          children: [
            if (usersAvatars.length > 0)
              Flexible(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(color: Colors.black),
                      child: RippleAnimation(
                        repeat: true,
                        color: Colors.white,
                        minRadius: 22,
                        ripplesCount: 10,
                        child: Container(
                          margin: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.pink,
                            shape: BoxShape.circle,
                            image: DecorationImage(
                                fit: BoxFit.cover,
                                image: NetworkImage(usersAvatars[0])
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 2,top: 2),
                        child: Container(
                          width: mainCallerName.length > 9 ? 70 : null,
                          height: 15,
                          padding: const EdgeInsets.only(left: 5, right:  5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: Colors.black12,
                          ),
                          child: Text(
                            mainCallerName.toLowerCase(),
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,

                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            if (usersAvatars.length > 1)
              Flexible(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(color: Colors.black),
                      child: RippleAnimation(
                        repeat: true,
                        color: Colors.white,
                        minRadius: 22,
                        ripplesCount: 10,
                        child: Container(
                          margin: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.pink,
                            shape: BoxShape.circle,
                            image: DecorationImage(
                                fit: BoxFit.cover,
                                image: NetworkImage(usersAvatars[1])
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 2,bottom: 2),
                        child: Container(
                          width: mainHelperName.length > 9 ? 70 : null,
                          height: 15,
                          padding: const EdgeInsets.only(left: 5, right:  5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: Colors.black12,
                          ),
                          child: Text(
                            mainHelperName.toLowerCase(),
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,

                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
          ],
        )
            :
        Container()
    );
  }

  Widget videoRenderers(bool changeVideoMode, bool consumerIsDoingSomething, bool helperIsDoingSomething, List usersAvatars, String mainUserId, String mainHelperName, String mainCallerName, String isSharing) => changeVideoMode ?

  (   _userManager.userId == _helperId ?
  Stack(
    children: [
      InkWell(
        onTap:(){
          setState(() {
            showButtons = true;
            customTimer = Timer(const Duration(seconds: 3), (){
              setState(() {
                showButtons = false;
              });
            });
          });
        },
        child: (helperIsDoingSomething && ("caller" != isSharing)) ?
        Container(
          color: Colors.black87,
          child: RippleAnimation(
            repeat: true,
            color: Colors.white,
            minRadius: 22,
            ripplesCount: 8,
            child: Container(
              margin: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.pink,
                shape: BoxShape.circle,
                image: DecorationImage(
                    fit: BoxFit.cover,
                    image: NetworkImage(usersAvatars[1])
                ),
              ),
            ),
          ),
        )
            :
        Container(
          key: Key('local'),
          //margin: EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
          decoration: BoxDecoration(color: Colors.black),
          child: RTCVideoView(("caller" == isSharing) ? _remoteRenderer! : _localRenderer!,objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
        ),
      ),
      if (newUserAdded)
        DraggableWidget(
          initialPosition: AnchoringPosition.bottomRight,
          bottomMargin:25,
          topMargin: 50,
          horizontalSpace:5,
          normalShadow: const BoxShadow(
            color: Colors.transparent,
            offset: Offset(0, 0),
            blurRadius: 0,
          ),
          child: Container(
            width: newUserAdded ? MediaQuery.of(context).size.width/5 : null,
            height: newUserAdded ? MediaQuery.of(context).size.height/10 : null,
            key: Key('remote'),
            margin: EdgeInsets.fromLTRB(0, 0, 10.0, 10.0),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.blueAccent,
                border: Border.all(color: Colors.blueAccent)
            ),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Container(
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.blueAccent)
                    ),
                    child:
                    Stack(
                      children: [
                        if (consumerIsDoingSomething && ("caller" != isSharing))
                          Container(
                            color: Colors.black87,
                            child: RippleAnimation(
                              repeat: true,
                              color: Colors.white,
                              minRadius: 22,
                              ripplesCount: 8,
                              child: Container(
                                margin: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.pink,
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                      fit: BoxFit.cover,
                                      image: NetworkImage(usersAvatars[0])
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (!consumerIsDoingSomething || ("caller" == isSharing))
                          RTCVideoView(("caller" == isSharing) ? _localRenderer! : _remoteRenderer! ,objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 2,bottom: 2),
                            child: Container(
                              width: (("caller" != isSharing) ? mainCallerName : mainHelperName).length > 9 ? 70 : null,
                              height: 15,
                              padding: const EdgeInsets.only(left: 5, right:  5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                color: Colors.black12,
                              ),
                              child: Text(
                                (("caller" != isSharing) ? mainCallerName : mainHelperName).toLowerCase(),
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,

                              ),
                            ),
                          ),
                        )
                      ],
                    )
                )
            ),
          ),
        ),
      Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 10,top: 50),
          child: Container(
            width: (("caller" != isSharing) ? mainHelperName : mainCallerName).length > 9 ? 70 : null,
            height: 20,
            padding: const EdgeInsets.only(left: 5, right:  5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: Colors.black12,
            ),
            child: Text(
              (("caller" != isSharing) ? mainHelperName : mainCallerName).toLowerCase(),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,

            ),
          ),
        ),
      )
    ],
  )
      :
  Stack(
    children: [
      if (newUserAdded)
        InkWell(
          onTap:(){
            setState(() {
              showButtons = true;
              customTimer = Timer(const Duration(seconds: 3), (){
                setState(() {
                  showButtons = false;
                });
              });
            });

          },
          child:
          helperIsDoingSomething ?
          Container(
            color: Colors.black87,
            child: RippleAnimation(
              repeat: true,
              color: Colors.white,
              minRadius: 22,
              ripplesCount: 8,
              child: Container(
                margin: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.pink,
                  shape: BoxShape.circle,
                  image: DecorationImage(
                      fit: BoxFit.cover,
                      image: NetworkImage(usersAvatars[1])
                  ),
                ),
              ),
            ),
          )
              :
          Container(
            key: Key('remote'),
            //margin: EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
            decoration: BoxDecoration(color: Colors.black),
            child: RTCVideoView(_remoteRenderer!,objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
          ),
        ),
      if (newUserAdded)
        DraggableWidget(
          initialPosition: AnchoringPosition.bottomRight,
          bottomMargin:25,
          topMargin: 50,
          horizontalSpace:5,
          normalShadow: const BoxShadow(
            color: Colors.transparent,
            offset: Offset(0, 0),
            blurRadius: 0,
          ),
          child: Container(
            width: newUserAdded ? MediaQuery.of(context).size.width/5 : null,
            height: newUserAdded ? MediaQuery.of(context).size.height/10 : null,
            key: Key('local'),
            margin: EdgeInsets.fromLTRB(0, 0, 10.0, 10.0),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.blueAccent,
                border: Border.all(color: Colors.blueAccent)
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Container(
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.blueAccent)
                  ),
                  child:Stack(
                    children: [
                      if (consumerIsDoingSomething)
                        Container(
                          color: Colors.black87,
                          child: RippleAnimation(
                            repeat: true,
                            color: Colors.white,
                            minRadius: 22,
                            ripplesCount: 8,
                            child: Container(
                              margin: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.pink,
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                    fit: BoxFit.cover,
                                    image: NetworkImage(usersAvatars[0])
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (!consumerIsDoingSomething)
                        RTCVideoView((isBotChecker ? _remoteRendererSecondUser! : _localRenderer!),objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 2,bottom: 2),
                          child: Container(
                            width: mainCallerName.length > 9 ? 70 : null,
                            height: 15,
                            padding: const EdgeInsets.only(left: 5, right:  5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: Colors.black12,
                            ),
                            child: Text(
                              mainCallerName.toLowerCase(),
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,

                            ),
                          ),
                        ),
                      )
                    ],
                  )
              ),
            ),
          ),
        ),
      Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 10,top: 50),
          child: Container(
            width: (newUserAdded ? mainHelperName.length : mainCallerName.length) > 9 ? 70 : null,
            height: 20,
            padding: const EdgeInsets.only(left: 5, right:  5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: Colors.black12,
            ),
            child: Text(
              (newUserAdded ? mainHelperName : mainCallerName).toLowerCase(),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,

            ),
          ),
        ),
      ),
      if (!newUserAdded)
        InkWell(
          onTap:(){
            setState(() {
              showButtons = true;
              customTimer = Timer(const Duration(seconds: 3), (){
                setState(() {
                  showButtons = false;
                });
              });
            });
          },
          child: Container(
            key: Key('local'),
            //margin: EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
            decoration: BoxDecoration(color: Colors.black),
            child:
            consumerIsDoingSomething ?
            Container(
              color: Colors.black87,
              child: RippleAnimation(
                repeat: true,
                color: Colors.white,
                minRadius: 22,
                ripplesCount: 8,
                child: Container(
                  margin: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.pink,
                    shape: BoxShape.circle,
                    image: DecorationImage(
                        fit: BoxFit.cover,
                        image: NetworkImage(usersAvatars[0])
                    ),
                  ),
                ),
              ),
            )
                :
            RTCVideoView(_localRenderer!,objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
          ),
        ),
    ],
  )
  )
      :
  (
      (_userManager.userId == _helperId) ?
      Stack(
        children: [
          Column(
              children: [
                Flexible(
                  child: Container(
                    key: Key('local'),
                    //margin: EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
                    decoration: BoxDecoration(color: Colors.black),
                    child:
                    helperIsDoingSomething ?
                    Container(
                      color: Colors.black87,
                      child: RippleAnimation(
                        repeat: true,
                        color: Colors.white,
                        minRadius: 22,
                        ripplesCount: 8,
                        child: Container(
                          margin: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.pink,
                            shape: BoxShape.circle,
                            image: DecorationImage(
                                fit: BoxFit.cover,
                                image: NetworkImage(usersAvatars[1])
                            ),
                          ),
                        ),
                      ),
                    )
                        :
                    RTCVideoView(_localRenderer!,objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                  ),
                ),
                //SizedBox(width: 5),
                if (newUserAdded)
                  Flexible(
                    child: Container(
                      key: Key('remote'),
                      //margin: EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
                      decoration: BoxDecoration(color: Colors.black),
                      child:
                      consumerIsDoingSomething ?
                      Container(
                        color: Colors.black87,
                        child: RippleAnimation(
                          repeat: true,
                          color: Colors.white,
                          minRadius: 22,
                          ripplesCount: 8,
                          child: Container(
                            margin: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.pink,
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: NetworkImage(usersAvatars[0])
                              ),
                            ),
                          ),
                        ),
                      )
                          :
                      RTCVideoView(_remoteRenderer!,objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                    ),
                  ),
              ]),
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 2,top: 2),
              child: Container(
                width: mainHelperName.length > 9 ? 70 : null,
                height: 15,
                padding: const EdgeInsets.only(left: 5, right:  5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.black12,
                ),
                child: Text(
                  mainHelperName.toLowerCase(),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,

                ),
              ),
            ),
          ),
          if (newUserAdded)
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 2,bottom: 2),
                child: Container(
                  width: mainCallerName.length > 9 ? 70 : null,
                  height: 15,
                  padding: const EdgeInsets.only(left: 5, right:  5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.black12,
                  ),
                  child: Text(
                    mainCallerName.toLowerCase(),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,

                  ),
                ),
              ),
            )
        ],
      )
          :
      Stack(
        children: [
          Column(
              children: [
                Flexible(
                  child: Container(
                    key: Key('local'),
                    //margin: EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
                    decoration: BoxDecoration(color: Colors.black),
                    child:
                    consumerIsDoingSomething ?
                    Container(
                      color: Colors.black87,
                      child: RippleAnimation(
                        repeat: true,
                        color: Colors.white,
                        minRadius: 25,
                        ripplesCount: 8,
                        child: Container(
                          margin: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.pink,
                            shape: BoxShape.circle,
                            image: DecorationImage(
                                fit: BoxFit.cover,
                                image: NetworkImage(usersAvatars[0])
                            ),
                          ),
                        ),
                      ),
                    )
                        :
                    RTCVideoView((isBotChecker ? _remoteRenderer! : _localRenderer!),objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                  ),
                ),
                //SizedBox(width: 5),
                if (newUserAdded)
                  Flexible(
                    child: Container(
                      key: Key('remote'),
                      //margin: EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
                      decoration: BoxDecoration(color: Colors.black),
                      child:
                      helperIsDoingSomething ?
                      Container(
                          color: Colors.black87,
                          child: RippleAnimation(
                              repeat: true,
                              color: Colors.white,
                              minRadius: 25,
                              ripplesCount: 8,
                              child:Container(
                                margin: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.pink,
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                      fit: BoxFit.cover,
                                      image: NetworkImage(usersAvatars[1])
                                  ),
                                ),
                              )
                          )
                      )
                          :
                      RTCVideoView((isBotChecker ? _remoteRendererSecondUser! : _remoteRenderer!),objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                    ),
                  ),
              ]),
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 2,top: 2),
              child: Container(
                width: mainCallerName.length > 9 ? 70 : null,
                height: 15,
                padding: const EdgeInsets.only(left: 5, right:  5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.black12,
                ),
                child: Text(
                  mainCallerName.toLowerCase(),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,

                ),
              ),
            ),
          ),
          if (newUserAdded)
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 2,bottom: 2),
                child: Container(
                  width: mainHelperName.length > 9 ? 70 : null,
                  height: 15,
                  padding: const EdgeInsets.only(left: 5, right:  5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.black12,
                  ),
                  child: Text(
                    mainHelperName.toLowerCase(),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,

                  ),
                ),
              ),
            )
        ],
      )

  );

  Future<void> setDefaultAvatar() async {
    defaultAvatarURL = await ref.child("default_images/default_avatar.png").getDownloadURL();
  }

  Future<void> clearActiveCalls() async {
    List listOfCalls = await FlutterCallkitIncoming.activeCalls();

    if (listOfCalls.isNotEmpty){
      await FlutterCallkitIncoming.endAllCalls();
    }
  }

  Future<void> saveAllDataAndStop(String userUID, bool isHelper) async {

    Map<String,dynamic> cleanUserStatus = {
      'calling_state': '0',
      'live_status': LiveStatus.AVAILABLE,
      'whiteboard_id':'',
      'token_call_id':'',
      'channel_name_call_id':'',
      'peer_temporary_id':'',
      'last_duration_live':0,
      'last_role_live':''
    };

    if (isHelper){
      _userManager.updateValue("allHelpers", "live_status", LiveStatus.AVAILABLE);
    }
    else
    {
      if (timerActivated && !isBotChecker){
        timerActivated = false;
        //displayTimeInHoursMinuteSeconds = await timerManagement!.cancelTimer();
      }

      final timeDecomposedTemporary = displayTimeInHoursMinuteSeconds!.split(":");
      current_duration_live = Duration(hours: int.parse(timeDecomposedTemporary.first), minutes: int.parse(timeDecomposedTemporary.elementAt(1)), seconds: int.parse(timeDecomposedTemporary.last)).inSeconds;
    }

    await _userManager.updateMultipleValues("allUsers", cleanUserStatus);

    if(Platform.isIOS){
      await signaling!.stopReplayKit();
    }

  }

  Future<String> getUserStatus () async {

    String result = "";
    String starterUser = "images/starter_transparent.png";
    String classicUser = "images/classic_transparent.png";

    String payload  =  await _userManager.getValue("allUsers", "peer_temporary_id");

    bool userIsNew = (payload.split("|").elementAt(1).toLowerCase() == 'true' ? true : false);

    userIsNew ? result = starterUser : result = classicUser;

    return result;
  }

  Future<void> prepareAlert () async {

    if(!stopActivity){
      stopActivity = true;
      await Future.delayed(Duration(seconds: 2));

      _userManager.updateMultipleValues(
          "allUsers",
          {
            'calling_state': '0',
            'live_status': LiveStatus.AVAILABLE,
            'whiteboard_id':'',
            'token_call_id':'',
            'channel_name_call_id':'',
            'peer_temporary_id':'',
            'last_duration_live':0,
            'last_role_live':''
          }
      );

      await endRtcLiveCall(true);
      sendMissedCallNotification();
      //navigatorKey.currentState!.pop();
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    /*timerManagement = NotificationApi(
        onForceQuit: (_onForceQuit){
          setState(() {
            forceQuitChannel = _onForceQuit;
          });
        }
    );*/

    _localRenderer!.initialize();
    _remoteRenderer!.initialize();
    _remoteRendererSecondUser!.initialize();

    if (false == stopActivity){
      _controllerOne.addListener(() {
        setState(() {
          controllerOneScrollOffset = _controllerOne.offset;
        });
      });

      initVideoCall();
      setDefaultAvatar();
      clearActiveCalls();

    }
    WidgetsBinding.instance.addObserver(this);
    //subscription = Connectivity().onConnectivityChanged.listen(NotificationApi.showConnectivityNotification);

  }

  @override
  void dispose() async {
    super.dispose();
    leaveWhiteboard();
  }

  leaveWhiteboard() async {
    WidgetsBinding.instance.removeObserver(this);
    subscription!.cancel();
    customTimer?.cancel();
    endCallTimer?.cancel();
    _controller.dispose();

    if (progressTimer != null){
      progressTimer!.cancel();
    }

    if (timerAutoResearch != null){
      timerAutoResearch!.cancel();
    }

    if (!stopActivity){
      (forceQuitChannel || isBotChecker) ? await endRtcLiveCall(false) : await endRtcLiveCall(true);
      if (!forceQuitChannel && !isBotChecker) deleteWhiteboardAndFiles();
      _userManager.updateMultipleValues(
          "allUsers",
          {
            'calling_state': '0',
            'live_status': LiveStatus.AVAILABLE,
            'whiteboard_id':'',
            'token_call_id':'',
            'channel_name_call_id':'',
            'peer_temporary_id':'',
            'last_duration_live':0,
            'last_role_live':''
          }
      );

      if(!enableAutoResearch && !isBotChecker){
        sendMissedCallNotification();
      }

      if(Platform.isIOS){
        await signaling!.stopReplayKit();
      }

    }

    _localRenderer!.srcObject = null;
    _remoteRenderer!.srcObject = null;

    if (_remoteRendererSecondUser != null){
      _remoteRendererSecondUser!.srcObject = null;
      _remoteRendererSecondUser!.dispose();
    }

    _localRenderer!.dispose();
    _remoteRenderer!.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {

    //String helperId = await _userManager.getValue("temporaryUsersFilesLinks", "helper_id", docId: whiteboardId!);

    if(!stopActivity){
      List listOfNeededParams = ["helper_id","caller_id","isSharing"];
      Map tmpValues = await _userManager.getMultipleValues("temporaryUsersFilesLinks", listOfNeededParams, docId: whiteboardId!);
      String helperId = tmpValues[listOfNeededParams[0]];
      String callerId = tmpValues[listOfNeededParams[1]];
      String isSharing = tmpValues[listOfNeededParams[2]];

      if (state == AppLifecycleState.paused) {

        if (whiteboardId!.isNotEmpty) {

          if (pictureTakenFromCamera){
            if(_userManager.userId == helperId) {
              await _userManager.updateValue("temporaryUsersFilesLinks", "helper_is_doing_something",true, docId: whiteboardId!);
            }else if(_userManager.userId == callerId){
              await _userManager.updateValue("temporaryUsersFilesLinks", "consumer_is_doing_something",true, docId: whiteboardId!);
            }
            //TODO:Uncomment below
            //endRtcLiveCall(false);
          }

        }

      } else if (state == AppLifecycleState.resumed) {

        if (pictureTakenFromCamera){

          if (whiteboardId!.isNotEmpty){
            if(_userManager.userId == helperId) {
              await _userManager.updateValue("temporaryUsersFilesLinks", "helper_is_doing_something",false, docId: whiteboardId!);

            }else if(_userManager.userId == callerId) {
              await _userManager.updateValue("temporaryUsersFilesLinks", "consumer_is_doing_something",false, docId: whiteboardId!);
            }
          }
          pictureTakenFromCamera = false;
        } else{

          if(isSharing.isNotEmpty){
            if((("helper" == isSharing) && (_userManager.userId == helperId)) || (("caller" == isSharing) && (_userManager.userId == callerId))){
              if (isSharingScreen){
                showScreenSharingDialog(false, "");
              }
            }
          }
        }
      }
    }

  }


  Future<bool> onLikeButtonTapped(bool isLiked) async{

    int thresholdLikes = 1;
    likedButtonTapped = likedButtonTapped + 1;

    if ((current_duration_live >= 900) && (current_duration_live < 3600)){
      thresholdLikes = 20;
    }
    else if (current_duration_live >= 3600){
      thresholdLikes = 100;
    }

    if (likedButtonTapped > thresholdLikes ){
      likedButtonTapped = likedButtonTapped - 1;
    }
    return true;
  }

  Future<List<String>> prepareNeededParameters () async {
    int status = 0;

    String last_helper_temporary_id = await _userManager.getValue("allUsers", "last_helper_temporary_id");
    Map neededParams = {
      "first_name":"",
    };

    Map parameters = {
      "advancedMode":false,
      "docId":last_helper_temporary_id,
      "collectionName":"allHelpers",
      "neededParams": json.encode(neededParams),
    };

    var result = await _userManager.callCloudFunction("getUserInfo", parameters);

    String helper_first_name = result.data["first_name"];

    Map otherNeededParams = {
      "live_status":"",
    };

    Map otherParameters = {
      "advancedMode":false,
      "docId":last_helper_temporary_id,
      "collectionName":"allUsers",
      "neededParams": json.encode(otherNeededParams),
    };

    var otherResult = await _userManager.callCloudFunction("getUserInfo", otherParameters);
    status = otherResult.data["live_status"];

    return [helper_first_name,status.toString()];
  }

  Future<int> resetHelperStatus (String helperId) async {

    Map neededParams = {
      "live_status":"",
    };

    Map parameters = {
      "advancedMode":false,
      "docId":helperId,
      "collectionName":"allUsers",
      "neededParams": json.encode(neededParams),
    };

    var result = await _userManager.callCloudFunction("getUserInfo", parameters);

    int helper_live_status = result.data["live_status"];

    if(LiveStatus.AVAILABLE == helper_live_status){

      Map paramsToBeUpdated = {
        "live_status":LiveStatus.AVAILABLE,
      };

      Map parametersUpdated = {
        "advancedMode":false,
        "docId":helperId,
        "collectionName":"allHelpers",
        "paramsToBeUpdated": json.encode(paramsToBeUpdated),
      };

      await _userManager.callCloudFunction("updateUserInfo", parametersUpdated);

      Map otherParamsToBeUpdated = {
        'calling_state': '0',
        'live_status': LiveStatus.AVAILABLE,
        'whiteboard_id':'',
        'token_call_id':'',
        'channel_name_call_id':'',
        'peer_temporary_id':'',
        'last_role_live':''
      };

      Map otherParametersUpdated = {
        "advancedMode":false,
        "docId":helperId,
        "collectionName":"allUsers",
        "paramsToBeUpdated": json.encode(otherParamsToBeUpdated),
      };

      await _userManager.callCloudFunction("updateUserInfo", otherParametersUpdated);

    }

    return helper_live_status;
  }

  Future<bool> checkSubscriptionBefore() async {

    bool isCurrentUserSubscribed = false;
    String helperId = await _userManager.getValue("allUsers", "last_helper_temporary_id");

    List listOfSubscriptions = await _userManager.getValue("allSubscriptionsAndSubscribers", "subscriptions");

    listOfSubscriptions.forEach((element) {
      if (helperId == element){
        isCurrentUserSubscribed = true;
      }
    });
    return isCurrentUserSubscribed;
  }

  deleteWhiteboardAndFiles(){
    final CollectionReference allWhiteBoards = FirebaseFirestore.instance.collection("whiteboards");
    final CollectionReference allTemporaryFiles = FirebaseFirestore.instance.collection("temporaryUsersFilesLinks");
    final CollectionReference status = FirebaseFirestore.instance.collection("status");
    allWhiteBoards.doc(whiteboardId).delete();
    allTemporaryFiles.doc(whiteboardId).delete();
    status.doc(whiteboardId).delete();
  }

  void _animateToIndex(int index) {
    _controller.animateTo(
      index * MediaQuery.of(context).size.width /4,
      duration: Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
    );
  }


  Future<void> downloadImage(Image imageContent) async {


    var statusStorage= await Permission.storage.request();

    if (statusStorage.isGranted){

      var completer = Completer<ImageInfo>();

      imageContent.image.resolve(const ImageConfiguration()).addListener(ImageStreamListener((info, _) {
        completer.complete(info);
      }));

      ImageInfo imageInfo = await completer.future;

      var tmpImage= await imageInfo.image.toByteData(format: ui.ImageByteFormat.png);

      final tempDir = await getTemporaryDirectory();

      var fileName = DateTime.now().microsecondsSinceEpoch.toString();
      File file = await File('${tempDir.path}/${fileName}.png').create();
      await file.writeAsBytes(tmpImage!.buffer.asUint8List());

      await GallerySaver.saveImage(file.path);
      await file.delete();

    }else {
      //AlertDialogManager.shortDialog(context, "L'application a besoin d'accéder aux fichiers de l'appareil",permissions: [statusStorage.isDenied], forceAction: false);
    }

  }

  void showScreenSharingDialog(bool activate, String mode){
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            titlePadding: EdgeInsets.all(10),
            actionsPadding: EdgeInsets.only(bottom: 10.0,),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Flexible(
                  child:
                  activate ?
                  Text(
                    'Partager l\'écran de ton appareil ?',
                    style: GoogleFonts.inter(
                      color: Colors.grey,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                  :
                  RichText(
                  text: TextSpan(
                    text: 'Partage d\'écran: ',
                    style: GoogleFonts.inter(
                      color: Colors.grey,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    children: <TextSpan>[
                        TextSpan(
                            text: 'ACTIVÉ',
                            style: GoogleFonts.inter(
                              color: Colors.green,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                        )
                      ],
                    ),
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
            content: activate ? null :
            Center(
              widthFactor: 1,
              heightFactor: 1,
              child:Text(
                "Arrêter le partage d\'écran ?",
                style: GoogleFonts.inter(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                      onPressed:()async {

                        if(activate){
                          bool result = await signaling!.shareScreen(true);

                          if (result){
                            await _userManager.updateValue("temporaryUsersFilesLinks", "isSharing", mode, docId: whiteboardId!);
                            setState(() {
                              isSharingScreen = true;
                            });
                            Navigator.pop(context);
                          }


                        }else{
                          bool result = await signaling!.shareScreen(false);
                          if(result){

                            if(Platform.isIOS){
                              await signaling!.stopReplayKit();
                            }

                            await _userManager.updateValue("temporaryUsersFilesLinks", "isSharing", mode, docId: whiteboardId!);
                            setState(() {
                              isSharingScreen = false;
                            });
                          }
                          Navigator.pop(context);
                        }

                        },
                      child: Text(
                        "Oui",
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                  ),
                  ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        },
                      child: Text("Non",
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),)
                  ),
                ],
              ),
            ],
          );
        });
  }

  void displayAllImages(WhiteboardViewModel viewmodel){

    List errorsFound = [];
    int internalIndex = 0;
    showDialog(
        context: context,
        builder: (contextDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0)
            ),
            title: Text(
                "Classeur",
                textAlign: TextAlign.center
            ),
            content: Center(
              widthFactor: 1,
              heightFactor: 1,
              child:Container(
                width: MediaQuery.of(context).size.width / 2,
                //height: 50,
                //color: Colors.green,
                child: Scrollbar(
                  controller: _controller,
                  thumbVisibility:true,
                  thickness: 10,
                  radius:Radius.circular(20),
                  child: ListView.separated(
                      controller:_controller,
                      //padding: const EdgeInsets.all(10),
                      scrollDirection: Axis.vertical,
                      itemCount: viewmodel.sharedFiles.length,
                      padding: EdgeInsets.only(right: 50),
                      separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 5),
                      itemBuilder: (BuildContext context, int index) {

                        Image? imageContent;

                        if(viewmodel.sharedFiles.isNotEmpty){
                          imageContent = Image.network(

                            viewmodel.sharedFiles.elementAt(index),
                            fit: BoxFit.contain,
                            errorBuilder: (context,error,trace){
                              errorsFound.add(index);
                              debugPrint("DEBUG_LOG 4, errorsFound.length="+errorsFound.length.toString() + " index="+index.toString() + "internalIndex="+internalIndex.toString());

                              if(errorsFound.isNotEmpty && (internalIndex == viewmodel.sharedFiles.length)) {
                                debugPrint("DEBUG_LOG 5");
                                for(int errorIndex=0; errorIndex<errorsFound.length;errorIndex++){
                                  debugPrint("DEBUG_LOG 6");

                                  viewmodel.sharedFiles.removeAt(errorsFound[errorIndex] - errorIndex);
                                }
                                Navigator.pop(contextDialog);
                              }
                              return Container(
                                child: Center(
                                    child: Text(
                                        "Image dupliquée")
                                ),
                              );
                            },
                          );
                        }

                        internalIndex++;

                        return Container(
                          width: MediaQuery.of(context).size.width / 2,
                          height: MediaQuery.of(context).size.height /6,

                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            border: Border.all(color: Colors.black, width: 2),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: viewmodel.sharedFiles.isEmpty ?

                          Text('Aucune image sélectionnée.',
                            style: GoogleFonts.inter(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center
                            ,)
                              :
                          InkWell(
                              onTap: (){
                                bool downloadedImage = false;
                                bool isDownloading = false;

                                Navigator.of(context).push(
                                    PageRouteBuilder(
                                        opaque: false, // set to false
                                        pageBuilder: (_, __, ___) => Container(
                                          color: Colors.black.withOpacity(0.5),
                                          child:  GestureDetector(
                                            onTap: () {
                                              Navigator.pop(context);
                                            },
                                            child: Stack(
                                              children: [
                                                InteractiveViewer(
                                                  clipBehavior: Clip.none,
                                                  child: Center(
                                                      child: imageContent
                                                  ),
                                                ),
                                                SafeArea(
                                                  child: Padding(
                                                    padding: const EdgeInsets.only(top:10, right:10),
                                                    child: Align(
                                                      alignment: Alignment.topRight,
                                                      child: StatefulBuilder(
                                                          builder: (context, customState) {
                                                            return RawMaterialButton(
                                                              onPressed: () async {
                                                                customState((){
                                                                  isDownloading = true;
                                                                });

                                                                if((viewmodel.mainUserId == _userManager.userId) || (_helperId == _userManager.userId)){

                                                                  if (!downloadedImage){
                                                                    await downloadImage(imageContent!);
                                                                    customState((){
                                                                      downloadedImage = true;
                                                                    });
                                                                  }

                                                                }else{
                                                                  //AlertDialogManager.shortDialog(context, "C'est bientôt ton tour ! ${viewmodel.mainHelperName.isNotEmpty ? CommonFunctionsManager.capitalize(viewmodel.mainHelperName) : "Ton interlocuteur"} termine actuellement ƒ avec un élève et poursuivra ensuite avec toi dans quelques instants.",titleColor: Colors.grey);
                                                                }

                                                                customState((){
                                                                  isDownloading = false;
                                                                });

                                                              },
                                                              child: Container(
                                                                width: 110,
                                                                child:
                                                                !isDownloading ?
                                                                Row(
                                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                                  children: [
                                                                    Icon(
                                                                      downloadedImage ? Icons.download_done : Icons.download,
                                                                      color: Colors.white,
                                                                      size: 20.0,
                                                                    ),
                                                                    Flexible(
                                                                        child: Text(
                                                                          downloadedImage ? "Téléchargé" : "Télécharger",
                                                                          style: GoogleFonts.inter(
                                                                            color: downloadedImage ? Colors.white : Colors.black,
                                                                            fontSize: 13,
                                                                            fontWeight: FontWeight.w500,
                                                                          ),
                                                                        )
                                                                    )
                                                                  ],
                                                                )
                                                                    :
                                                                Row(
                                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                                  children: [
                                                                    //TwoFlyingDots(dotsSize: 12, firstColor: Colors.blue, secondColor: Colors.yellow),
                                                                  ],
                                                                ),


                                                              ),
                                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
                                                              elevation: 2.0,
                                                              fillColor: downloadedImage ? Colors.greenAccent : Colors.orangeAccent,
                                                              padding: const EdgeInsets.all(12.0),
                                                            );
                                                          }
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                    )
                                );
                              },
                              child: imageContent
                          ),
                        );
                      }
                  ),
                ),
              ),
            ),
          );
        }
    ).then((value) async {
      if(errorsFound.isNotEmpty){
        await _userManager.updateValue("temporaryUsersFilesLinks", "sharedfiles", viewmodel.sharedFiles, docId: whiteboardId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WhiteboardViewModel>(
        builder: (context, viewmodel, _) {

          if(!progressTimerStarted){
            initCallingTimer(viewmodel);
          }

          if(enableAutoResearch && !algorithmStarted){
            algorithmStarted = true;
            searchAlgorithm(whiteboardId!, roomId!,pseudo!, callerAvatar!, isNewUser!,viewmodel);
          }

          if (viewmodel.swapUserId != _userManager.userId){
            if (_userManager.userId != viewmodel.helperId){
              currentSwapUserId = "";
              currentSwapUserIdUpdated = false;
            }
          }else{
            currentSwapUserId = viewmodel.swapUserId;
          }

          if((_userManager.userId! != viewmodel.mainUserId) && (!isBotChecker)){
            if (_userManager.userId != viewmodel.helperId){
              if(timerActivated){
                //timerManagement!.cancelTimer();
              }
              timerActivated = false;
            }
          }

          if (('2' == viewmodel.startCall) && !timerActivated && (_userManager.userId != viewmodel.helperId) && (_userManager.userId! == viewmodel.mainUserId) && !isBotChecker && !stopActivity){
            timerActivated = true;
            if(enableAutoResearch){
              _helperId = viewmodel.helperId;
            }

            var createdTime = DateTime.now().microsecondsSinceEpoch;

            //timerManagement!.launchTimer(whiteboardId!, (isMoreUser ? "" : _helperId!), fullSpotPathOption!,viewmodel.mainHelperName,viewmodel.mainCallerName);

            _userManager.updateValue("whiteboards", "lastUpdated", createdTime,docId: whiteboardId!);
          }

          if (viewmodel.moreUsers.isEmpty){
            previousAddedNewCallerLength = 0;
          }

          if(viewmodel.isBotChecker.isNotEmpty && (viewmodel.isBotChecker == _userManager.userId) && !isBotCheckerDone){
            isBotCheckerDone = true;
            signaling?.refreshBotSession(_localRenderer!);
          }

          if(viewmodel.moreUsers.isNotEmpty && (viewmodel.moreUsers.length - 1 < 2) && (previousAddedNewCallerLength != viewmodel.moreUsers.length) && viewmodel.swapUserId.isEmpty){
            if(_userManager.userId == viewmodel.helperId){

              int keepVal = previousAddedNewCallerLength;
              previousAddedNewCallerLength = viewmodel.moreUsers.length;
              if(keepVal < viewmodel.moreUsers.length){
                signaling?.refreshSession(_localRenderer!, viewModel: viewmodel);
              }
            }
          }

          if((_userManager.userId != viewmodel.helperId) && (currentSwapUserId.isNotEmpty) && !currentSwapUserIdUpdated && !isBotChecker){
            currentSwapUserIdUpdated = true;
            signaling?.refreshSession(_localRenderer!);
          }


          //String? helper_first_name = snapshot?.data?.first;

          if((viewmodel.callStatus) || (viewmodel.appIsInMaintenance) || (forceQuitChannel)){
            if(!stopActivity){
              stopActivity = true;
              forceQuitChannel ? endRtcLiveCall(false) : endRtcLiveCall(true);

              if (!forceQuitChannel){
                if (whiteboardId!.isNotEmpty){
                  deleteWhiteboardAndFiles();
                }
              }


              if ((_userManager.userId != viewmodel.helperId)){

                if(!isBotChecker){
                  saveAllDataAndStop(_userManager.userId!,false);
                }

                if(!isBotChecker){
                  if((viewmodel.moreUsers.length >0) && (!viewmodel.callStatus)){
                    for(int moreUserIndex =0; moreUserIndex<viewmodel.moreUsers.length; moreUserIndex++){
                      if(viewmodel.moreUsers[moreUserIndex]["userId"] == _userManager.userId){
                        _userManager.updateValue("temporaryUsersFilesLinks", "moreUsers", FieldValue.arrayRemove([viewmodel.moreUsers[moreUserIndex]]),docId: whiteboardId!);
                      }
                    }
                  }
                }

              }else{
                saveAllDataAndStop(_userManager.userId!,true);
              }
            }

            _helperName = viewmodel.mainHelperName;


            return viewmodel.appIsInMaintenance ?
            WillPopScope(
                onWillPop: () async => false,
                child: MaintenancePage()
            ) :

            (
                ((_userManager.userId == viewmodel.helperId) ?
                WillPopScope(
                  onWillPop: () async => false,
                  child: Scaffold(
                    backgroundColor: Colors.lightBlueAccent,
                    body: AlertDialog(
                      titlePadding: EdgeInsets.all(10),
                      actionsPadding: EdgeInsets.only(bottom: 10.0,),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(
                            'Merci de ton aide 💓',
                            style: GoogleFonts.inter(
                              color: Colors.grey,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          /*ElevatedButton(
                            onPressed: () async {
                              Navigator.pushReplacement(
                                  context, MaterialPageRoute(builder: (context) => HomePage(),
                              ));
                            },
                            child: Icon(Icons.exit_to_app),
                            style: ElevatedButton.styleFrom(
                              shape: CircleBorder(),
                              primary: Colors.green,
                            ),
                          ),*/
                        ],
                      ),
                    ),
                  ),
                )

                    :

                WillPopScope(
                  onWillPop: () async => false,
                  child: Scaffold(
                    backgroundColor: Colors.lightBlueAccent,
                    body: StatefulBuilder(
                        builder: (BuildContext context, StateSetter changeState) {
                          if ((current_duration_live >= 1800) && (current_duration_live < 3600)){
                            thresholdLikes = 20;
                          }
                          else if (current_duration_live >= 3600){
                            thresholdLikes = 100;
                          }
                          return AlertDialog(
                            titlePadding: EdgeInsets.all(10),
                            actionsPadding: EdgeInsets.only(top: 10,bottom: 10.0,),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Expanded(
                                    child:
                                    RichText(
                                      text: TextSpan(
                                        text: "C\'était cool avec " + _helperName + " ? Tapotes sur l\'écran pour envoyer des coeurs à $_helperName (",
                                        style: GoogleFonts.inter(
                                          color: Colors.grey,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        children: <TextSpan>[
                                          TextSpan(
                                              text: "+" + thresholdLikes.toString(),
                                              style: GoogleFonts.inter(
                                                color: Colors.pink,
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              )
                                          ),
                                          TextSpan(
                                              text: ' ❤ max.)',
                                              style: GoogleFonts.inter(
                                                color: Colors.grey,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                              )
                                          ),
                                        ],
                                      ),
                                    )
                                ),
                                ElevatedButton(
                                  onPressed: () async {

                                    if (!buttonQuit){
                                      buttonQuit = true;
                                      if((likedButtonTapped > 0) && (buttonPressed != 2) && (buttonVipPressed != 2)){
                                        List listOfNeededParams = ["last_helper_temporary_id","pseudo"];
                                        Map tmpValues = await _userManager.getMultipleValues("allUsers", listOfNeededParams);
                                        String helperId = tmpValues[listOfNeededParams[0]];
                                        String pseudo = tmpValues[listOfNeededParams[1]];

                                        Map paramsToBeUpdated = {
                                          "likes": {
                                            "mode": "increment",
                                            "value": likedButtonTapped
                                          }
                                        };

                                        Map parametersUpdated = {
                                          "advancedMode":true,
                                          "docId":helperId,
                                          "collectionName":"allHelpers",
                                          "paramsToBeUpdated": json.encode(paramsToBeUpdated),
                                        };

                                        _userManager.callCloudFunction("updateUserInfo", parametersUpdated);

                                        HttpsCallable sendNotificationCallable = await FirebaseFunctions.instanceFor(app: FirebaseFunctions.instance.app, region: "europe-west1").httpsCallable('sendNotification');

                                        sendNotificationCallable.call(<String, dynamic>{
                                          "type":"BASIC_NOTIFICATION",
                                          "notificationId": "",
                                          "notificationReminderId":"",
                                          "receiverId":helperId,
                                          "peerTemporaryId":"",
                                          "scheduledTime":"",
                                          "scheduledDay": "",
                                          "scheduledHour": "",
                                          "senderPseudo":"",
                                          "repeat":"",
                                          "title":"",
                                          "message":"@$pseudo a aimé LIVE avec toi (+" + likedButtonTapped.toString() + " j\'aime)",
                                        });
                                      }
                                    }

                                    /*navigatorKey.currentState!.pushReplacement(MaterialPageRoute(builder: (context) => HomePage(),
                                    ));*/

                                  },
                                  child: Icon(Icons.exit_to_app),
                                  style: ElevatedButton.styleFrom(
                                    shape: CircleBorder(),
                                    primary: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            content: InkWell(
                              onTap: () async {
                                likedButtonTapped = likedButtonTapped + 1;

                                if (likedButtonTapped > thresholdLikes ){
                                  likedButtonTapped = likedButtonTapped - 1;
                                }

                                changeState(() {
                                  isLiked = true;
                                });
                              },
                              child: Container(
                                  width: 200,
                                  height: 200,
                                  color: Colors.purple[200],
                                  child: Center(
                                    child: Stack(
                                      children: [
                                        Align(
                                          alignment: Alignment.center,
                                          child: Icon(
                                            Icons.favorite,
                                            color: isLiked ? Colors.red : Colors.grey[200],
                                            size: 200,
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.center,
                                          child: Text("+" +likedButtonTapped.toString(),
                                              style: GoogleFonts.inter(
                                                color: isLiked ? Colors.white : Colors.grey[500],
                                                fontSize: 50,
                                                fontWeight: FontWeight.w500,
                                              )
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                              ),
                            ),
                            actions: [
                              FutureBuilder<bool>(
                                  future: checkSubscriptionBefore(),
                                  builder: (context, AsyncSnapshot<bool>? snapshotAction) {

                                    if ((snapshotAction != null) && snapshotAction.hasData) {
                                      bool subscriptionExists =  snapshotAction.data!;
                                      return Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                                            children: [
                                              StatefulBuilder(
                                                  builder: (BuildContext context, StateSetter changeState) {

                                                    return Flexible(
                                                      child: ElevatedButton(
                                                          onPressed: () async {

                                                            if (buttonVipPressed != 2){
                                                              changeState((){
                                                                buttonVipPressed = 1;
                                                              });

                                                              List listOfNeededParams = ["last_helper_temporary_id","pseudo"];
                                                              Map tmpValues = await _userManager.getMultipleValues("allUsers", listOfNeededParams);
                                                              String helperId = tmpValues[listOfNeededParams[0]];

                                                              String resultState = "basic"; //await CommonFunctionsManager.isVipHelperValid(helperId,"real_user");
                                                              //AlertDialogManager.customDialog(resultState, _helperName, context);

                                                              if (resultState == "success"){
                                                                if (buttonPressed != 2){

                                                                  if(likedButtonTapped > 0){
                                                                    String pseudo = tmpValues[listOfNeededParams[1]];

                                                                    Map paramsToBeUpdated = {
                                                                      "likes": {
                                                                        "mode": "increment",
                                                                        "value": likedButtonTapped
                                                                      }
                                                                    };

                                                                    Map parametersUpdated = {
                                                                      "advancedMode":true,
                                                                      "docId":helperId,
                                                                      "collectionName":"allHelpers",
                                                                      "paramsToBeUpdated": json.encode(paramsToBeUpdated),
                                                                    };

                                                                    _userManager.callCloudFunction("updateUserInfo", parametersUpdated);


                                                                    HttpsCallable sendNotificationCallable = await FirebaseFunctions.instanceFor(app: FirebaseFunctions.instance.app, region: "europe-west1").httpsCallable('sendNotification');

                                                                    sendNotificationCallable.call(<String, dynamic>{
                                                                      "type":"BASIC_NOTIFICATION",
                                                                      "notificationId": "",
                                                                      "notificationReminderId":"",
                                                                      "receiverId":helperId,
                                                                      "peerTemporaryId":"",
                                                                      "scheduledTime":"",
                                                                      "scheduledDay": "",
                                                                      "scheduledHour": "",
                                                                      "senderPseudo":"",
                                                                      "repeat":"",
                                                                      "title":"",
                                                                      "message": likedButtonTapped > 0 ? "@$pseudo s\'est abonné(e) à toi" + " (+" + likedButtonTapped.toString() + " j\'aime)" : "$pseudo s\'est abonné(e) à toi",
                                                                    });
                                                                  }
                                                                }

                                                                changeState((){
                                                                  buttonVipPressed = 2;
                                                                });
                                                              }else{
                                                                changeState((){
                                                                  buttonVipPressed = 0;
                                                                });
                                                              }

                                                            }
                                                          },
                                                          style: ElevatedButton.styleFrom(
                                                            primary: (2 == buttonVipPressed) ? Colors.grey[300] : Colors.purple,
                                                          ),
                                                          child:
                                                          1 == buttonVipPressed ?
                                                          TwoFlyingDots(dotsSize: 12, firstColor: Colors.blue, secondColor: Colors.yellow)
                                                              :
                                                          Text(
                                                            2 == buttonVipPressed ? "Déjà chouchou" : "🥰 Devenir le chouchou de $_helperName",
                                                            style: GoogleFonts.inter(
                                                              color: 2 == buttonVipPressed ? Colors.grey[600] : Colors.white,
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w500,
                                                            ),)
                                                      ),
                                                    );
                                                  }
                                              ),
                                            ],
                                          ),
                                          !subscriptionExists ?
                                          (
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                children: [
                                                  StatefulBuilder(
                                                      builder: (BuildContext context, StateSetter changeState) {

                                                        return Flexible(
                                                          child: ElevatedButton(
                                                              onPressed: () async {

                                                                if (buttonPressed != 2){
                                                                  changeState((){
                                                                    buttonPressed = 1;
                                                                  });

                                                                  List listOfNeededParams = ["last_helper_temporary_id","pseudo"];
                                                                  Map tmpValues = await _userManager.getMultipleValues("allUsers", listOfNeededParams);
                                                                  String helperId = tmpValues[listOfNeededParams[0]];

                                                                  //CommonFunctionsManager.subscribeToUser(helperId, _helperName!);

                                                                  if (buttonVipPressed != 2){

                                                                    if(likedButtonTapped > 0){
                                                                      Map paramsToBeUpdated = {
                                                                        "likes": {
                                                                          "mode": "increment",
                                                                          "value": likedButtonTapped
                                                                        }
                                                                      };

                                                                      Map parametersUpdated = {
                                                                        "advancedMode":true,
                                                                        "docId":helperId,
                                                                        "collectionName":"allHelpers",
                                                                        "paramsToBeUpdated": json.encode(paramsToBeUpdated),
                                                                      };

                                                                      _userManager.callCloudFunction("updateUserInfo", parametersUpdated);

                                                                      String pseudo = tmpValues[listOfNeededParams[1]];
                                                                      HttpsCallable sendNotificationCallable = await FirebaseFunctions.instanceFor(app: FirebaseFunctions.instance.app, region: "europe-west1").httpsCallable('sendNotification');

                                                                      sendNotificationCallable.call(<String, dynamic>{
                                                                        "type":"BASIC_NOTIFICATION",
                                                                        "notificationId": "",
                                                                        "notificationReminderId":"",
                                                                        "receiverId":helperId,
                                                                        "peerTemporaryId":"",
                                                                        "scheduledTime":"",
                                                                        "scheduledDay": "",
                                                                        "scheduledHour": "",
                                                                        "senderPseudo":"",
                                                                        "repeat":"",
                                                                        "title":"",
                                                                        "message": likedButtonTapped > 0 ? "@$pseudo s\'est abonné(e) à toi" + " (+" + likedButtonTapped.toString() + " j\'aime)" : "$pseudo s\'est abonné(e) à toi",
                                                                      });

                                                                      changeState((){
                                                                        buttonPressed = 2;
                                                                      });
                                                                    }
                                                                  }
                                                                }
                                                              },
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor: (2 == buttonPressed) ? Colors.grey[300] : Colors.blue,
                                                              ),
                                                              child:
                                                              1 == buttonPressed ?
                                                              TwoFlyingDots(dotsSize: 12, firstColor: Colors.blue, secondColor: Colors.yellow)
                                                                  :
                                                              Column(
                                                                children: [
                                                                  Text(
                                                                    2 == buttonPressed ? "Abonné" : "✨ S'abonner à $_helperName",
                                                                    style: GoogleFonts.inter(
                                                                      color: 2 == buttonPressed ? Colors.grey[600] : Colors.white,
                                                                      fontSize: 12,
                                                                      fontWeight: FontWeight.w500,
                                                                    ),
                                                                  ),
                                                                ],
                                                              )
                                                          ),
                                                        );
                                                      }
                                                  ),
                                                ],
                                              )
                                          )
                                              :
                                          (
                                              Container()
                                          )

                                        ],
                                      );
                                    }
                                    else{
                                      //debugPrint("DEBUG_LOG SUBCRIPTION IS NULL");
                                      return Container();
                                    }

                                  }
                              ),
                            ],
                          );
                        }
                    ),
                  ),
                )
                ));

          }
          else {
            if(viewmodel.changeVideoMode){
              if (!hasSwitchedDisplay){
                hasSwitchedDisplay = true;
                customTimer = Timer(const Duration(seconds: 3), (){
                  setState(() {
                    showButtons = false;
                  });
                });
              }
            }else{
              showButtons = true;
              hasSwitchedDisplay = false;
            }

            return WillPopScope(
              onWillPop: () async => ((viewmodel.startCall == "2") && !isBotChecker) ? false : true,
              child: Scaffold(
                backgroundColor: Color(0xff6cdbfb),
                body: SafeArea(
                  top: viewmodel.changeVideoMode ? false : true,
                  bottom: false,
                  right: false,
                  left: false,
                  child: viewmodel.changeVideoMode ?
                  //DISPLAYMODE: full screen
                  Stack(
                    children: [
                      Column(
                        children: [
                          Expanded(
                            child:
                            ((viewmodel.mainUserId == _userManager.userId) || (_helperId == _userManager.userId) || isBotChecker) ?
                            videoRenderers(viewmodel.changeVideoMode,viewmodel.consumerAction,viewmodel.helperAction,viewmodel.usersAvatars, viewmodel.mainUserId,viewmodel.mainHelperName, viewmodel.mainCallerName, viewmodel.isSharing)
                                :
                            videoRenderersSaloon(viewmodel.usersAvatars, viewmodel.mainHelperName, viewmodel.mainCallerName,viewmodel.changeVideoMode),
                          ),
                        ],
                      ),
                      if(viewmodel.moreUsers.isNotEmpty)
                        DraggableWidget(
                          initialPosition: AnchoringPosition.bottomRight,
                          bottomMargin:25,
                          topMargin: 50,
                          horizontalSpace:0,
                          normalShadow: const BoxShadow(
                            color: Colors.transparent,
                            offset: Offset(0, 0),
                            blurRadius: 0,
                          ),
                          child: Container(
                            width: (MediaQuery.of(context).size.width/5) * 4,
                            height: MediaQuery.of(context).size.height/10,
                            //color:Colors.red,
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      reverse : true,
                                      //dragStartBehavior: DragStartBehavior.down,
                                      child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          textDirection: TextDirection.rtl,
                                          children: viewmodel.moreUsers.map((element) =>
                                              Row(
                                                children: [
                                                  InkWell(
                                                    onTap:() async {
                                                      if (_userManager.userId == _helperId){

                                                        await signaling!.swapUser(_localRenderer!,viewmodel.moreUsers.indexOf(element), viewModel: viewmodel, mainUserHasLeft: !newUserAdded);
                                                      }
                                                    },
                                                    child: Container(
                                                      height: MediaQuery.of(context).size.height/10 - 20 ,
                                                      width: MediaQuery.of(context).size.width /5 -13,
                                                      decoration: BoxDecoration(
                                                        color: Colors.black,
                                                        border: Border.all(color: Colors.purpleAccent),
                                                        borderRadius: BorderRadius.circular(10.0),
                                                      ),
                                                      child: Stack(
                                                        children: [
                                                          Padding(
                                                            padding: const EdgeInsets.all(10.0),
                                                            child: Container(
                                                              decoration: BoxDecoration(
                                                                borderRadius: BorderRadius.circular(30.0),
                                                                image: DecorationImage(
                                                                  fit: BoxFit.contain,
                                                                  image: NetworkImage(element["avatarUrl"]),//NetworkImage("https://firebasestorage.googleapis.com/v0/b/hamadoo-3c55c.appspot.com/o/default_images%2Fdefault_avatar.png?alt=media&token=82413a1e-5d4a-496f-971e-b494da78d86c&_gl=1*1d1qxu8*_ga*MzI1NDQ4MDY4LjE2ODY2NzUzNDk.*_ga_CW55HF8NVT*MTY4NjY3NTM0OS4xLjEuMTY4NjY3NTM4Mi4wLjAuMA..")
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          Padding(
                                                            padding: const EdgeInsets.only(left: 15.0, right: 15.0, top: 0, bottom: 25.0),
                                                            child: ElevatedButton(
                                                                onPressed: () async {

                                                                  if (_userManager.userId == _helperId){
                                                                    await signaling!.swapUser(_localRenderer!,viewmodel.moreUsers.indexOf(element), viewModel: viewmodel,mainUserHasLeft: !newUserAdded);
                                                                  }
                                                                },
                                                                style: ElevatedButton.styleFrom(
                                                                    shape: CircleBorder(),
                                                                    primary: Colors.pink,
                                                                    alignment: Alignment.center,
                                                                    padding: EdgeInsets.zero
                                                                  //minimumSize: Size(1,1)
                                                                ),
                                                                child: Icon(Icons.add,color: Colors.white, size: 15,)
                                                            ),
                                                          ),
                                                          Align(
                                                            alignment: Alignment.bottomLeft,
                                                            child: Padding(
                                                              padding: const EdgeInsets.only(left: 5),
                                                              child: Text(
                                                                element["name"].toLowerCase(),
                                                                style: GoogleFonts.inter(
                                                                  color: Colors.white,
                                                                  fontSize: 8,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                                overflow: TextOverflow.ellipsis,

                                                              ),
                                                            ),
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: 10),
                                                ],
                                              )
                                          ).toList()
                                    ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        height: 20,
                                        width: (MediaQuery.of(context).size.width/5) + 10,
                                        //color: Colors.green,
                                      ),
                                    ],
                                  )
                                ],
                            ),
                          ),
                        ),

                      DraggableWidget(
                        initialPosition: AnchoringPosition.bottomLeft,
                        bottomMargin:25,
                        topMargin: 50,
                        horizontalSpace:5,
                        normalShadow: const BoxShadow(
                          color: Colors.transparent,
                          offset: Offset(0, 0),
                          blurRadius: 0,
                        ),
                        child: InkWell(
                          onTap: (){
                            displayAllImages(viewmodel);
                          },
                          child: Container(
                              margin: EdgeInsets.fromLTRB(10.0, 0,0,10.0),
                              width: MediaQuery.of(context).size.width /5,//200,
                              height: MediaQuery.of(context).size.height /10,//160,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Color(0xffA0E7E5),
                              ),
                              child: Stack(
                                children: [
                                  if(isBotChecker)
                                    Center(
                                      child: Stack(
                                        children: [
                                          Container(
                                            width: 5,
                                            height: 5,
                                            //margin: EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
                                            decoration: BoxDecoration(color: Colors.black),
                                            child: RTCVideoView(_localRenderer!,objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                                          ),
                                          Container(
                                            width: 5,
                                            height: 5,
                                            color:Color(0xffA0E7E5)
                                          ),
                                        ],
                                      ),
                                    ),
                                  Container(
                                    //color:Colors.green,
                                    child: viewmodel.sharedFiles.isEmpty ?
                                    Align(
                                      alignment: Alignment.center,
                                      child: Icon(Icons.file_present),
                                    )
                                        :
                                    Align(
                                      alignment: Alignment.center,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Container(
                                          //color:Colors.red,
                                          child: Image.network(
                                              viewmodel.sharedFiles.last,
                                            loadingBuilder: (BuildContext context, Widget child,
                                                ImageChunkEvent? loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Center(
                                                child: Padding(
                                                  padding: const EdgeInsets.all(20.0),
                                                  child: CircularProgressIndicator(
                                                    value: loadingProgress.expectedTotalBytes != null
                                                        ? loadingProgress.cumulativeBytesLoaded /
                                                        loadingProgress.expectedTotalBytes!
                                                        : null,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      )
                                    ),
                                  ),
                                  if(viewmodel.sharedFiles.isEmpty)
                                    Align(
                                      alignment: Alignment.topCenter,
                                      child: Container(
                                        child: Text(
                                          "Classeur\nd\'images",
                                          style: GoogleFonts.inter(
                                            color: Colors.black,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  if(viewmodel.sharedFiles.isNotEmpty)
                                    Align(
                                      alignment: Alignment.topRight,
                                      child: Container(
                                        height: 20,
                                        width:20,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(30),
                                          color: Colors.red,
                                        ),
                                        child: Center(
                                          child: Text(
                                              viewmodel.sharedFiles.length.toString(),
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    )
                                ],
                              )
                          ),
                        ),
                      ),
                      if ('1' == viewmodel.startCall)
                        Center(
                          child: ShakeWidget(
                            curve: Curves.easeInOutSine,
                            deltaX: 4,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 50,right: 50),
                              child: Container(
                              width: MediaQuery.of(context).size.width,
                              height: MediaQuery.of(context).size.height/4,
                              decoration: BoxDecoration(
                                color:Colors.white,
                                //border: Border.all(color: Colors.purpleAccent),
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                                child: Stack(
                                  children: [
                                    SquarePercentIndicator(
                                      width: MediaQuery.of(context).size.width,
                                      height: MediaQuery.of(context).size.height/4,
                                      startAngle: StartAngle.topLeft,
                                      //reverse: true,
                                      borderRadius: 20,
                                      shadowWidth: 1.5,
                                      progressWidth: 15,
                                      shadowColor: Colors.grey,
                                      progressColor: showCalling ? Colors.greenAccent : Colors.redAccent,
                                      progress: _progress,
                                      child: Container(
                                        child:Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              //color: Colors.red,
                                              height: (MediaQuery.of(context).size.height/4) - (MediaQuery.of(context).size.height/6),
                                              child: Container(
                                                child: Center(
                                                  child: Text(
                                                      showCalling ? "Demande en cours..." : "Aucune réponse...",
                                                      textAlign: TextAlign.center,
                                                      style: GoogleFonts.poppins(
                                                          color: Colors.black,
                                                          fontSize: 15,
                                                          //fontWeight: FontWeight.bold
                                                      )

                                                  ),
                                                ),
                                              ),
                                            ),
                                            showCalling ?
                                            Container(
                                              child: Image.asset(
                                                "images/searching.gif",
                                                height: MediaQuery.of(context).size.height/6,
                                                fit: BoxFit.contain,
                                              ),
                                            )
                                                :
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Container(
                                                  child: Text(
                                                      not_found,
                                                      textAlign: TextAlign.justify,
                                                      style: GoogleFonts.poppins(
                                                        color: Colors.grey,
                                                        fontSize: 15,
                                                        //fontWeight: FontWeight.bold
                                                      )
                                                  ),
                                              ),
                                            )
                                          ],
                                        )
                                      ),
                                    ),
                                  ],
                                )
                              ),
                            ),
                          ),
                        ),
                      if (('2' == viewmodel.startCall) && (viewmodel.liveNearlyClosed == _userManager.userId) && !showAlertMessage)
                        AlertDialog(
                          backgroundColor: Colors.orange,
                          title:
                          Text("Le LIVE se termine bientôt",
                              style: GoogleFonts.poppins(
                                  color: Colors.yellow,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold
                              )),
                          content: (_userManager.userId == viewmodel.helperId) ?
                          null
                              :
                          Text("Oups ! Ton forfait est bientôt épuisé. La session en cours s'arrêtera dans 1 minute."),
                          actions: [
                            Container(
                              height: 40,
                              width: 80,
                              color: Colors.blue,
                              child: TextButton(
                                  onPressed: () async {
                                    setState(() {
                                      showAlertMessage = true;
                                    });
                                  },
                                  child: Text("Fermer",style: TextStyle(
                                      color: Colors.white
                                  ),)),
                            ),
                          ],
                        ),
                      if ('0' == viewmodel.startCall)
                        FutureBuilder<void>(
                            future: prepareAlert(),
                            builder:(context, AsyncSnapshot<void>? snapshot) {
                              viewmodel.deleteAllFiles();
                              deleteWhiteboardAndFiles();
                              return Scaffold(
                                backgroundColor: Colors.transparent,
                                body: AlertDialog(
                                  title: Text( (_helperName.isNotEmpty ? _helperName : "L'interlocuter") + " ne répond pas pour le moment..."),
                                  content: Text("Réessaies plus tard 😌"),
                                ),
                              );
                            }),
                      if((viewmodel.mainUserId != _userManager.userId) && (_helperId != _userManager.userId) && (viewmodel.swapUserId.isEmpty) && !isBotChecker && viewmodel.mainHelperName.isNotEmpty)
                        ShakeWidget(
                          curve: Curves.easeInOutSine,
                          deltaX: 4,
                          child: AlertDialog(
                            title: Text(
                                "${/*viewmodel.mainHelperName.isNotEmpty ? CommonFunctionsManager.capitalize(viewmodel.mainHelperName) :*/ "Ton interlocuteur"} termine actuellement une explication avec un élève et poursuivra ensuite avec toi dans quelques instants. Ne bouges pas !",
                                textAlign: TextAlign.center
                            ),
                            content: Center(
                                widthFactor: 1,
                                heightFactor: 1,
                                child:
                                Container(
                                  height: 150,
                                  padding: const EdgeInsets.all(20.0),
                                  child: Image.asset(
                                    "images/teaching_official.gif",
                                    fit: BoxFit.contain,
                                  ),
                                )
                              //TwoFlyingDots(dotsSize: 18, firstColor: Colors.blue, secondColor: Colors.yellow),
                            ),
                          ),
                        ),
                      if (viewmodel.swapUserId.isNotEmpty)
                        ShakeWidget(
                          curve: Curves.easeInOutSine,
                          deltaX: 4,
                          child: AlertDialog(
                            title: Text(
                                "Changement d'utilisateur...",
                                textAlign: TextAlign.center
                            ),
                            content: Center(
                                widthFactor: 1,
                                heightFactor: 1,
                                child:
                                Container(
                                  height: 150,
                                  padding: const EdgeInsets.all(20.0),
                                  child: Image.asset(
                                    "images/waiting_transparent.gif",
                                    fit: BoxFit.contain,
                                  ),
                                )
                              //TwoFlyingDots(dotsSize: 18, firstColor: Colors.blue, secondColor: Colors.yellow),
                            ),
                          ),
                        ),
                      Visibility(
                        visible: showButtons,
                        child: Align(
                          alignment: Alignment.center,
                          child: Container(
                              height: 400,
                              padding: EdgeInsets.only(right: 22),
                              child:Container(
                                height: MediaQuery.of(context).size.width,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    RawMaterialButton(
                                      onPressed: (){

                                        if (viewmodel.isSharing.isEmpty){

                                          String sharingMode = "";
                                          if(_helperId == _userManager.userId){
                                            sharingMode = "helper";
                                          }else if (viewmodel.mainUserId == _userManager.userId){
                                            sharingMode = "caller";
                                          }

                                          if (sharingMode.isNotEmpty){
                                            if ("2" == viewmodel.startCall){
                                              showScreenSharingDialog(true, sharingMode);
                                            }else {
                                              //AlertDialogManager.shortDialog(context, "Partage d'écran impossible ! Tu ne peux pas partager ton écran lorsqu'il n'y a personne avec toi.",titleColor: Colors.grey);
                                            }

                                          }else{
                                            //AlertDialogManager.shortDialog(context, "C'est bientôt ton tour ! ${viewmodel.mainHelperName.isNotEmpty ? CommonFunctionsManager.capitalize(viewmodel.mainHelperName) : "Ton interlocuteur"} termine actuellement une explication avec un élève et poursuivra ensuite avec toi dans quelques instants.",titleColor: Colors.grey);
                                          }

                                        }else{

                                          if(("helper" == viewmodel.isSharing) && (_helperId == _userManager.userId)){
                                            showScreenSharingDialog(false, "");
                                          }else if (("caller" == viewmodel.isSharing) && (viewmodel.mainUserId == _userManager.userId)){
                                            showScreenSharingDialog(false, "");
                                          }else{
                                            if(_helperId == _userManager.userId){
                                              //AlertDialogManager.shortDialog(context, "Partage d'écran impossible ! ${viewmodel.mainCallerName.isNotEmpty ? CommonFunctionsManager.capitalize(viewmodel.mainCallerName) : "Ton interlocuteur"} doit d'abord arrêter son partage d'écran afin que tu puisses le faire à ton tour.",titleColor: Colors.grey);
                                            }else if(viewmodel.mainUserId == _userManager.userId){
                                              //AlertDialogManager.shortDialog(context, "Partage d'écran impossible ! ${viewmodel.mainHelperName.isNotEmpty ? CommonFunctionsManager.capitalize(viewmodel.mainHelperName) : "Ton interlocuteur"} doit d'abord arrêter son partage d'écran afin que tu puisses le faire à ton tour.",titleColor: Colors.grey);
                                            }else{
                                              //AlertDialogManager.shortDialog(context, "C'est bientôt ton tour ! ${viewmodel.mainHelperName.isNotEmpty ? CommonFunctionsManager.capitalize(viewmodel.mainHelperName) : "Ton interlocuteur"} termine actuellement une explication avec un élève et poursuivra ensuite avec toi dans quelques instants.",titleColor: Colors.grey);
                                            }
                                          }
                                        }
                                      },
                                      child: Icon(
                                        isSharingScreen ? Icons.stop_screen_share_outlined : Icons.screen_share_outlined,
                                        color: isSharingScreen ? Colors.white : Colors.blueAccent,
                                        size: 30.0,
                                      ),
                                      shape: CircleBorder(),
                                      elevation: 2.0,
                                      fillColor: isSharingScreen ? Colors.blueAccent : Colors.white,
                                      padding: const EdgeInsets.all(8.0),
                                    ),
                                    RawMaterialButton(
                                      onPressed: (){
                                        if('2' == viewmodel.startCall){

                                          if((viewmodel.mainUserId == _userManager.userId) || (_helperId == _userManager.userId)){
                                            viewmodel.setButtonIndicator("shareImage");
                                            viewmodel.disableDrawing(false);
                                            viewmodel.enableEraser(false);
                                            showDialog(
                                                context: context,
                                                builder: (contextDialog) {
                                                  return AlertDialog(
                                                    titlePadding: EdgeInsets.all(10),
                                                    actionsPadding: EdgeInsets.only(bottom: 10.0,),
                                                    title: Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                      children: [
                                                        Flexible(
                                                          child: Text(
                                                            'Ajouter une image dans le classeur depuis :',
                                                            style: GoogleFonts.inter(
                                                              color: Colors.grey,
                                                              fontSize: 15,
                                                              fontWeight: FontWeight.w500,
                                                            ),
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
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                        children: [
                                                          ElevatedButton(
                                                              onPressed:(){
                                                                Navigator.pop(contextDialog);
                                                                viewmodel.setImageUrl(false);
                                                                },
                                                              child: Text(
                                                                "Ma galerie",
                                                                style: GoogleFonts.inter(
                                                                  color: Colors.white,
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w500,
                                                                ),
                                                              )
                                                          ),
                                                          ElevatedButton(
                                                              onPressed: () async {
                                                                pictureTakenFromCamera = true;
                                                                await Future.delayed(Duration(seconds: 1));
                                                                Navigator.pop(contextDialog);
                                                                viewmodel.setImageUrl(true);
                                                                },
                                                              child: Text("Mon appareil photo",
                                                                style: GoogleFonts.inter(
                                                                  color: Colors.white,
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w500,
                                                                ),)
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  );
                                                });
                                          }else{
                                            //AlertDialogManager.shortDialog(context, "C'est bientôt ton tour ! ${viewmodel.mainHelperName.isNotEmpty ? CommonFunctionsManager.capitalize(viewmodel.mainHelperName) : "Ton interlocuteur"} termine actuellement une explication avec un élève et poursuivra ensuite avec toi dans quelques instants.",titleColor: Colors.grey);
                                          }

                                        }else{
                                          //AlertDialogManager.shortDialog(context, "Tu dois attendre qu'une personne te réponde avant de pouvoir utiliser cette fonctionnalité.");
                                        }
                                      },
                                      child: Icon(
                                        Icons.file_present,
                                        color: Colors.blueAccent,
                                        size: 20.0,
                                      ),
                                      shape: CircleBorder(),
                                      elevation: 2.0,
                                      fillColor: Colors.white,
                                      padding: const EdgeInsets.all(12.0),
                                    ),
                                    //Switch custom whiteboard
                                    RawMaterialButton(
                                      onPressed: () async {
                                        if((viewmodel.mainUserId == _userManager.userId) || (_helperId == _userManager.userId) || isBotChecker){
                                          await _userManager.updateValue("temporaryUsersFilesLinks", "change_video_mode", false, docId: whiteboardId!);
                                        }else{
                                          //AlertDialogManager.shortDialog(context, "C'est bientôt ton tour ! ${viewmodel.mainHelperName.isNotEmpty ? CommonFunctionsManager.capitalize(viewmodel.mainHelperName) : "Ton interlocuteur"} termine actuellement une explication avec un élève et poursuivra ensuite avec toi dans quelques instants.",titleColor: Colors.grey);
                                        }
                                      },
                                      shape: CircleBorder(),
                                      elevation: 2.0,
                                      fillColor: Colors.white,
                                      padding: const EdgeInsets.all(12.0),
                                      child: Icon(
                                          Icons.open_in_full ,
                                        color: Colors.blueAccent,
                                        size: 20.0,
                                      ),//open_in_full,open_with_outlined
                                    ),
                                    RawMaterialButton(
                                      onPressed: (){

                                        if((viewmodel.mainUserId == _userManager.userId) || (_helperId == _userManager.userId) || isBotChecker){
                                          setState((){
                                            signaling!.muteMic(isMicMuted);
                                            isMicMuted = !isMicMuted;
                                          });
                                        }else{
                                          //AlertDialogManager.shortDialog(context, "C'est bientôt ton tour ! ${viewmodel.mainHelperName.isNotEmpty ? CommonFunctionsManager.capitalize(viewmodel.mainHelperName) : "Ton interlocuteur"} termine actuellement une explication avec un élève et poursuivra ensuite avec toi dans quelques instants.",titleColor: Colors.grey);
                                        }

                                      },
                                      child: Icon(
                                        Icons.mic,
                                        color: isMicMuted ? Colors.white : Colors.blueAccent,
                                        size: 20.0,
                                      ),
                                      shape: CircleBorder(),
                                      elevation: 2.0,
                                      fillColor: isMicMuted ? Colors.blueAccent : Colors.white,
                                      padding: const EdgeInsets.all(12.0),
                                    ),
                                    RawMaterialButton(
                                      onPressed: () {

                                        if((viewmodel.mainUserId == _userManager.userId) || (_helperId == _userManager.userId) || isBotChecker){
                                          setState((){
                                            isCameraSwitched = !isCameraSwitched;
                                            signaling!.switchCamera(isCameraSwitched);
                                          });
                                        }else{
                                          //AlertDialogManager.shortDialog(context, "C'est bientôt ton tour ! ${viewmodel.mainHelperName.isNotEmpty ? CommonFunctionsManager.capitalize(viewmodel.mainHelperName) : "Ton interlocuteur"} termine actuellement une explication avec un élève et poursuivra ensuite avec toi dans quelques instants.",titleColor: Colors.grey);
                                        }


                                      },
                                      child: Icon(
                                        Icons.switch_camera,
                                        color: isCameraSwitched ? Colors.white : Colors.blueAccent,
                                        size: 20.0,
                                      ),
                                      shape: CircleBorder(),
                                      elevation: 2.0,
                                      fillColor: isCameraSwitched ? Colors.blueAccent : Colors.white,
                                      padding: const EdgeInsets.all(12.0),
                                    ),
                                    RawMaterialButton(
                                      onPressed: (){

                                        if((viewmodel.mainUserId == _userManager.userId) || (_helperId == _userManager.userId) || isBotChecker){
                                          setState((){
                                            signaling!.disableCamera(isVideoDisabled);
                                            isVideoDisabled = !isVideoDisabled;
                                          });

                                          if(_userManager.userId == _helperId) {
                                            _userManager.updateValue("temporaryUsersFilesLinks", "helper_is_doing_something",isVideoDisabled, docId: whiteboardId!);
                                          }else if (!isBotChecker) {
                                            _userManager.updateValue("temporaryUsersFilesLinks", "consumer_is_doing_something",isVideoDisabled, docId: whiteboardId!);
                                          }
                                        }else{
                                          //AlertDialogManager.shortDialog(context, "C'est bientôt ton tour ! ${viewmodel.mainHelperName.isNotEmpty ? CommonFunctionsManager.capitalize(viewmodel.mainHelperName) : "Ton interlocuteur"} termine actuellement une explication avec un élève et poursuivra ensuite avec toi dans quelques instants.",titleColor: Colors.grey);
                                        }


                                      },
                                      child: Icon(
                                        Icons.videocam,
                                        color: isVideoDisabled ? Colors.white : Colors.blueAccent,
                                        size: 20.0,
                                      ),
                                      shape: CircleBorder(),
                                      elevation: 2.0,
                                      fillColor: isVideoDisabled ? Colors.blueAccent : Colors.white,
                                      padding: const EdgeInsets.all(12.0),
                                    ),
                                    RawMaterialButton(
                                      onPressed: () async {
                                        if ("2"== viewmodel.startCall){
                                          if((viewmodel.moreUsers.isEmpty || (_userManager.userId! == _helperId)) && !isBotChecker){
                                            lastHelperTemporaryId = await _userManager.getValue("allUsers", "last_helper_temporary_id");
                                            viewmodel.deleteAllFiles();
                                            viewmodel.deleteCallActivity();
                                            viewmodel.endCall(true, lastHelperTemporaryId);
                                          }else{
                                            if(!isBotChecker){
                                              setState(() {
                                                forceQuitChannel = true;
                                              });
                                            }else{
                                              Navigator.pop(context);
                                            }
                                          }
                                        }else{
                                          viewmodel.deleteCallActivity();
                                          Navigator.pop(context);
                                        }
                                      },
                                      child: Icon(Icons.call_end, color: Colors.white),
                                      shape: CircleBorder(),
                                      elevation: 2.0,
                                      fillColor:Colors.red,
                                      padding: const EdgeInsets.all(20),
                                    ),
                                  ],
                                ),
                              )
                          ),
                        ),
                      ),
                    ],

                  )
                      :
                      //DISPLAYMODE: whiteboard screen
                  Stack(
                      children:[
                        if(isBotChecker)
                          Container(
                            width: 5,
                            height: 5,
                            key: Key('local'),
                            //margin: EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
                            decoration: BoxDecoration(color: Colors.black),
                            child: RTCVideoView(_localRenderer!,objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                          ),
                        Column(
                          children: <Widget>[
                            Container(
                              color: Color(0xffABEA7C),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Column(
                                          children: [
                                            ToolButtons(viewmodel: viewmodel, currentUserId: _userManager.userId!),
                                            Container(
                                              decoration: "shareImage" == viewmodel.buttonIndicator ? BoxDecoration(
                                                  border: Border.all(
                                                    color: Colors.green,
                                                    width: 3, //                   <--- border width here
                                                  ),
                                                  color: Color(0xff00E091)
                                              ) : BoxDecoration(),
                                              child: IconButton(
                                                icon: Image.asset("images/camera_add.png"),//Icon(Icons.add_a_photo_outlined  ),
                                                onPressed: () {
                                                  if('2' == viewmodel.startCall){

                                                    if((viewmodel.mainUserId == _userManager.userId) || (_helperId == _userManager.userId)){
                                                      viewmodel.setButtonIndicator("shareImage");
                                                      viewmodel.disableDrawing(false);
                                                      viewmodel.enableEraser(false);
                                                      showDialog(
                                                          context: context,
                                                          builder: (contextDialog) {
                                                            return AlertDialog(
                                                              titlePadding: EdgeInsets.all(10),
                                                              actionsPadding: EdgeInsets.only(bottom: 10.0,),
                                                              title: Row(
                                                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                                children: [
                                                                  Flexible(
                                                                    child: Text(
                                                                      'Insérer une image depuis:',
                                                                      style: GoogleFonts.inter(
                                                                        color: Colors.grey,
                                                                        fontSize: 15,
                                                                        fontWeight: FontWeight.w500,
                                                                      ),
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
                                                                Row(
                                                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                                  children: [
                                                                    ElevatedButton(
                                                                        onPressed:(){

                                                                          Navigator.pop(contextDialog);
                                                                          viewmodel.setImageUrl(false);
                                                                          },
                                                                        child: Text(
                                                                          "Ma galerie",
                                                                          style: GoogleFonts.inter(
                                                                            color: Colors.white,
                                                                            fontSize: 12,
                                                                            fontWeight: FontWeight.w500,
                                                                          ),
                                                                        )
                                                                    ),
                                                                    ElevatedButton(
                                                                        onPressed: () async {
                                                                          pictureTakenFromCamera = true;
                                                                          await Future.delayed(Duration(seconds: 1));

                                                                          Navigator.pop(contextDialog);
                                                                          viewmodel.setImageUrl(true);

                                                                          },
                                                                        child: Text("Mon appareil photo",
                                                                          style: GoogleFonts.inter(
                                                                            color: Colors.white,
                                                                            fontSize: 12,
                                                                            fontWeight: FontWeight.w500,
                                                                          ),)
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            );
                                                          });
                                                    }else{
                                                      //AlertDialogManager.shortDialog(context, "C'est bientôt ton tour ! ${viewmodel.mainHelperName.isNotEmpty ? CommonFunctionsManager.capitalize(viewmodel.mainHelperName) : "Ton interlocuteur"} termine actuellement une explication avec un élève et poursuivra ensuite avec toi dans quelques instants.",titleColor: Colors.grey);
                                                    }

                                                  }else{
                                                    //AlertDialogManager.shortDialog(context, "Tu dois attendre qu'une personne te réponde avant de pouvoir utiliser cette fonctionnalité.");
                                                  }
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        Expanded(
                                          child:Container(
                                            width: 250,
                                            height: 200,
                                            color: Color(0xffA0E7E5),
                                            child:
                                            viewmodel.sharedFiles.isEmpty ?
                                            Align(
                                              alignment: Alignment.center,
                                              child: Icon(Icons.file_present ),
                                            )
                                                :
                                            ListView.separated(
                                                padding: const EdgeInsets.all(10),
                                                scrollDirection: Axis.horizontal,
                                                itemCount: viewmodel.sharedFiles.length,
                                                separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 5),
                                                itemBuilder: (BuildContext context, int index) {
                                                  return Container(
                                                    width: 150,
                                                    height: 50,
                                                    color: Colors.redAccent,
                                                    child:viewmodel.sharedFiles.isEmpty ? Text('Aucune image sélectionnée.',
                                                      style: GoogleFonts.inter(
                                                        color: Colors.black,
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                      textAlign: TextAlign.center
                                                      ,)
                                                        :
                                                    InkWell(
                                                        onTap: (){
                                                          Navigator.of(context).push(
                                                              PageRouteBuilder(
                                                                  opaque: false, // set to false
                                                                  pageBuilder: (_, __, ___) => Container(
                                                                    color: Colors.black.withOpacity(0.5),
                                                                    child:  GestureDetector(
                                                                      onTap: () {Navigator.pop(context);},
                                                                      child: InteractiveViewer(
                                                                        clipBehavior: Clip.none,
                                                                        child: Image.network(viewmodel.sharedFiles.elementAt(index)),
                                                                      ),
                                                                    ),
                                                                  )
                                                              )
                                                          );
                                                        },
                                                        child: Image.network(viewmodel.sharedFiles.elementAt(index))
                                                    ),
                                                  );
                                                }
                                            ),

                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      Container(
                                        width: 130,
                                        height: 200,
                                        child: Stack(
                                          children: [
                                            Container(
                                              width: 130,
                                              height: 200,
                                              child:
                                              ((viewmodel.mainUserId == _userManager.userId) || (_helperId == _userManager.userId) || isBotChecker) ?
                                              videoRenderers(viewmodel.changeVideoMode,viewmodel.consumerAction,viewmodel.helperAction,viewmodel.usersAvatars,viewmodel.mainUserId, viewmodel.mainHelperName, viewmodel.mainCallerName, viewmodel.isSharing)
                                                  :
                                              videoRenderersSaloon(viewmodel.usersAvatars, viewmodel.mainHelperName, viewmodel.mainCallerName,viewmodel.changeVideoMode),
                                            ),
                                            if ((_userManager.userId == viewmodel.helperId) && (newUserAdded))
                                              FutureBuilder<String>(
                                                  future: getUserStatus(),
                                                  builder:(context, AsyncSnapshot<String>? snapshot) {

                                                    if (snapshot!= null && snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty){
                                                      String userLogoStatus = snapshot.data!;
                                                      return Align(
                                                        alignment: Alignment.bottomCenter,
                                                        child: Container(
                                                          width: 130,
                                                          height: 100,
                                                          //color: Colors.green,
                                                          child: Align(

                                                            alignment: Alignment.topRight,
                                                            child: Container(
                                                              height: 30,
                                                              width: 30,
                                                              decoration: BoxDecoration(
                                                                  color: ("images/starter_transparent.png" == userLogoStatus) ? Colors.red : Colors.blue ,
                                                                  //shape: BoxShape.circle,
                                                                  image: DecorationImage(
                                                                      fit: BoxFit.cover,
                                                                      image: AssetImage(userLogoStatus)
                                                                  )
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    }else{
                                                      return Container();
                                                    }
                                                  }
                                              ),
                                            InkWell(
                                              onTap: () async {
                                                if((viewmodel.mainUserId == _userManager.userId) || (_helperId == _userManager.userId) || isBotChecker){
                                                  await _userManager.updateValue("temporaryUsersFilesLinks", "change_video_mode", true, docId: whiteboardId!);
                                                }else{
                                                  //AlertDialogManager.shortDialog(context, "C'est bientôt ton tour ! ${viewmodel.mainHelperName.isNotEmpty ? CommonFunctionsManager.capitalize(viewmodel.mainHelperName) : "Ton interlocuteur"} termine actuellement une explication avec un élève et poursuivra ensuite avec toi dans quelques instants.",titleColor: Colors.grey);
                                                }

                                              },
                                              child: Container(
                                                width: 130,
                                                height: 200,
                                                child: Center(
                                                  child:
                                                  ElevatedButton(
                                                    onPressed: () async {
                                                      if((viewmodel.mainUserId == _userManager.userId) || (_helperId == _userManager.userId) || isBotChecker){
                                                        await _userManager.updateValue("temporaryUsersFilesLinks", "change_video_mode", true, docId: whiteboardId!);
                                                      }else{
                                                        //AlertDialogManager.shortDialog(context, "C'est bientôt ton tour ! ${viewmodel.mainHelperName.isNotEmpty ? CommonFunctionsManager.capitalize(viewmodel.mainHelperName) : "Ton interlocuteur"} termine actuellement une explication avec un élève et poursuivra ensuite avec toi dans quelques instants.",titleColor: Colors.grey);
                                                      }
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                        shape: CircleBorder(),
                                                        primary: Colors.blueAccent,
                                                        minimumSize: Size(30,30),
                                                        padding: EdgeInsets.zero
                                                    ),
                                                    child: Icon(Icons.open_in_full ,color: Colors.white),//open_in_full,open_with_outlined
                                                  ),
                                                ),
                                              ),
                                            ),

                                          ],
                                        ),

                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                                child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.pinkAccent,
                                        width: 3, //                   <--- border width here
                                      ),
                                    ),
                                    child:
                                    Stack(
                                      children: [
                                        Zoom(
                                          maxZoomWidth: 20000,
                                          maxZoomHeight: 20000,
                                          initZoom: 0.5,
                                          colorScrollBars: Colors.pink,
                                          scrollWeight: 20,
                                          zoomSensibility: 1.0,
                                          enableScaleAndPan: viewmodel.drawingIsBlocked,
                                          doubleTapZoom: viewmodel.drawingIsBlocked ? true : false,
                                          child: AbsorbPointer(
                                            absorbing: viewmodel.drawingIsBlocked,
                                            child: EraserDisplay(
                                              forceInReleaseMode: true,
                                              enabled: viewmodel.eraserStatus ? true : false,
                                              scrollOffset:controllerOneScrollOffset,
                                              child: WhiteboardView(
                                                lines: viewmodel.lines,
                                                onGestureStart: viewmodel.onGestureStart,
                                                onGestureUpdate: viewmodel.onGestureUpdate,
                                                onGestureEnd: viewmodel.onGestureEnd,
                                                drawingIsBlocked: viewmodel.drawingIsBlocked,
                                              ),
                                            ),
                                          ),
                                        ),
                                        if(viewmodel.eraserStatus)
                                          Align(
                                            alignment: Alignment.bottomLeft,
                                            child: Container(
                                              child: Row(
                                                children: [

                                                  Container(
                                                    height: 50,
                                                    width: 50,
                                                    decoration: BoxDecoration(
                                                        border: "singleEraser" == viewmodel.eraserType ? Border.all(
                                                          color: Colors.yellow,
                                                          width: 3, //                   <--- border width here
                                                        ) : null,
                                                        borderRadius: BorderRadius.circular(10.0),
                                                        color: Colors.blue[300]
                                                    ),
                                                    child: IconButton(
                                                      icon: Icon(Icons.gesture_outlined),
                                                      onPressed: () {
                                                        viewmodel.setEraserType("singleEraser");
                                                        viewmodel.setButtonIndicator("erase");
                                                        viewmodel.disableDrawing(false);
                                                        viewmodel.enableEraser(true);
                                                        viewmodel.selectTool(Tool.eraser);
                                                      },
                                                    ),
                                                  ),
                                                  SizedBox(width: 10),
                                                  Container(
                                                    height: 50,
                                                    width: 50,
                                                    decoration: BoxDecoration(
                                                        border: "previousEraser" == viewmodel.eraserType ? Border.all(
                                                          color: Colors.yellow,
                                                          width: 3, //                   <--- border width here
                                                        ) : null,
                                                        borderRadius: BorderRadius.circular(10.0),
                                                        color: Colors.pink[300]
                                                    ),
                                                    child: IconButton(
                                                      icon: Icon(Icons.reply_outlined),
                                                      onPressed: () {
                                                        viewmodel.selectTool(Tool.previousEraser);
                                                        viewmodel.setEraserType("previousEraser");
                                                        viewmodel.removeLastLine();
                                                      },
                                                    ),
                                                  ),
                                                  SizedBox(width: 10),
                                                  Container(
                                                    height: 50,
                                                    width: 50,
                                                    decoration: BoxDecoration(
                                                        border: "totalEraser" == viewmodel.eraserType ? Border.all(
                                                          color: Colors.yellow,
                                                          width: 3, //                   <--- border width here
                                                        ) : null,
                                                        borderRadius: BorderRadius.circular(10.0),
                                                        color: Colors.purple[300]
                                                    ),
                                                    child:IconButton(
                                                      icon: Icon(Icons.delete_outline),
                                                      onPressed: () {
                                                        viewmodel.selectTool(Tool.totalEraser);
                                                        viewmodel.setEraserType("totalEraser");
                                                        showDialog(
                                                            context: context,
                                                            builder: (context) {

                                                              return AlertDialog(
                                                                  shape: RoundedRectangleBorder(
                                                                      borderRadius: BorderRadius.circular(20.0)
                                                                  ),
                                                                  title: Text("Effacer le tableau",
                                                                    style: GoogleFonts.inter(
                                                                      color: Colors.red,
                                                                      fontSize: 15,
                                                                      fontWeight: FontWeight.w700,
                                                                    ),
                                                                  ),
                                                                  content:
                                                                  Column(
                                                                    mainAxisSize: MainAxisSize.min,
                                                                    children: [
                                                                      Center(
                                                                          child: Text(
                                                                              "Es-tu sûr de vouloir effacer tout le tableau ?",
                                                                              style: GoogleFonts.inter(
                                                                                color: Colors.black,
                                                                                fontSize: 15,
                                                                                fontWeight: FontWeight.w500,
                                                                              )
                                                                          )
                                                                      ),

                                                                    ],
                                                                  ),
                                                                  actions: [

                                                                    Row(
                                                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                                      children: [
                                                                        ElevatedButton(
                                                                            onPressed:(){
                                                                              viewmodel.clearWhiteboard();
                                                                              Navigator.pop(context);
                                                                            },
                                                                            child: Text(
                                                                              "Oui",
                                                                              style: GoogleFonts.inter(
                                                                                color: Colors.white,
                                                                                fontSize: 12,
                                                                                fontWeight: FontWeight.w500,
                                                                              ),
                                                                            )
                                                                        ),
                                                                        ElevatedButton(
                                                                            onPressed: () async {
                                                                              Navigator.pop(context);
                                                                            },
                                                                            child: Text("Non",
                                                                              style: GoogleFonts.inter(
                                                                                color: Colors.white,
                                                                                fontSize: 12,
                                                                                fontWeight: FontWeight.w500,
                                                                              ),)
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ]
                                                              );
                                                            }
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        if(viewmodel.moreUsers.isNotEmpty)
                                          Align(
                                            alignment: Alignment.bottomRight,
                                            child: Container(
                                              padding: EdgeInsets.only(bottom: 5),
                                              child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  children: viewmodel.moreUsers.map((element) =>
                                                      Row(
                                                        children: [
                                                          InkWell(
                                                            onTap:() async {
                                                              if (_userManager.userId == _helperId){

                                                                await signaling!.swapUser(_localRenderer!,viewmodel.moreUsers.indexOf(element), viewModel: viewmodel, mainUserHasLeft: !newUserAdded);
                                                              }
                                                            },
                                                            child: Container(
                                                              height: 50,
                                                              width: 50,
                                                              decoration: BoxDecoration(
                                                                color: Colors.black,
                                                                border: Border.all(color: Colors.purpleAccent),
                                                                borderRadius: BorderRadius.circular(10.0),
                                                              ),
                                                              child: Stack(
                                                                children: [
                                                                  Padding(
                                                                    padding: const EdgeInsets.all(10.0),
                                                                    child: Container(
                                                                      decoration: BoxDecoration(
                                                                        borderRadius: BorderRadius.circular(30.0),
                                                                        image: DecorationImage(
                                                                          fit: BoxFit.contain,
                                                                          image: NetworkImage(element["avatarUrl"]),//NetworkImage("https://firebasestorage.googleapis.com/v0/b/hamadoo-3c55c.appspot.com/o/default_images%2Fdefault_avatar.png?alt=media&token=82413a1e-5d4a-496f-971e-b494da78d86c&_gl=1*1d1qxu8*_ga*MzI1NDQ4MDY4LjE2ODY2NzUzNDk.*_ga_CW55HF8NVT*MTY4NjY3NTM0OS4xLjEuMTY4NjY3NTM4Mi4wLjAuMA..")
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Padding(
                                                                    padding: const EdgeInsets.only(left: 15.0, right: 15.0, top: 0, bottom: 25.0),
                                                                    child: ElevatedButton(
                                                                        onPressed: () async {
                                                                          if (_userManager.userId == _helperId){
                                                                            await signaling!.swapUser(_localRenderer!,viewmodel.moreUsers.indexOf(element), viewModel: viewmodel,mainUserHasLeft: !newUserAdded);
                                                                          }
                                                                        },
                                                                        style: ElevatedButton.styleFrom(
                                                                            shape: CircleBorder(),
                                                                            primary: Colors.pink,
                                                                            alignment: Alignment.center,
                                                                            padding: EdgeInsets.zero
                                                                          //minimumSize: Size(1,1)
                                                                        ),
                                                                        child: Icon(Icons.add,color: Colors.white, size: 15,)
                                                                    ),
                                                                  ),
                                                                  Align(
                                                                    alignment: Alignment.bottomLeft,
                                                                    child: Padding(
                                                                      padding: const EdgeInsets.only(left: 5),
                                                                      child: Text(
                                                                        element["name"].toLowerCase(),
                                                                        style: GoogleFonts.inter(
                                                                          color: Colors.white,
                                                                          fontSize: 8,
                                                                          fontWeight: FontWeight.bold,
                                                                        ),
                                                                        overflow: TextOverflow.ellipsis,

                                                                      ),
                                                                    ),
                                                                  )
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(width: 10)
                                                        ],
                                                      )
                                                  ).toList()
                                              ),
                                            ),
                                          ),
                                        if(viewmodel.zoomUtility)
                                          AlertDialog(
                                            backgroundColor: Colors.grey[50],
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(20.0)
                                            ),
                                            title: Text("Le tableau est de taille infini. Zoom et déplaces-toi à l'infini !",
                                              style: GoogleFonts.inter(
                                                color: Colors.blue,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            content:
                                            Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  child: Image.asset(
                                                    "images/zoom_fingers.gif",
                                                    //height: 70,
                                                    fit: BoxFit.contain,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            actions: [
                                              Center(
                                                child: Container(
                                                  child: TextButton(
                                                      onPressed: () {
                                                        viewmodel.setZoomUtility(false);
                                                      },
                                                      child: Text(
                                                          "OK, j'ai compris",
                                                          style: GoogleFonts.inter(
                                                            color: Colors.green,
                                                            fontSize: 15,
                                                          ))
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                      ],
                                    )
                                )
                            ),
                            //DISPLAYMODE: whiteboard screen bottom buttons
                            Container(
                              height: 90,
                              color: Colors.transparent,
                              padding: EdgeInsets.only(right: 22.0),
                              child:Container(
                                height: MediaQuery.of(context).size.width,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    RawMaterialButton(
                                      onPressed: (){

                                        if((viewmodel.mainUserId == _userManager.userId) || (_helperId == _userManager.userId) || isBotChecker){
                                          setState((){
                                            signaling!.muteMic(isMicMuted);
                                            isMicMuted = !isMicMuted;
                                          });
                                        }else{
                                          //AlertDialogManager.shortDialog(context, "C'est bientôt ton tour ! ${viewmodel.mainHelperName.isNotEmpty ? CommonFunctionsManager.capitalize(viewmodel.mainHelperName) : "Ton interlocuteur"} termine actuellement une explication avec un élève et poursuivra ensuite avec toi dans quelques instants.",titleColor: Colors.grey);
                                        }

                                      },
                                      child: Icon(
                                        Icons.mic,
                                        color: isMicMuted ? Colors.white : Colors.blueAccent,
                                        size: 20.0,
                                      ),
                                      shape: CircleBorder(),
                                      elevation: 2.0,
                                      fillColor: isMicMuted ? Colors.blueAccent : Colors.white,
                                      padding: const EdgeInsets.all(12.0),
                                    ),
                                    RawMaterialButton(
                                      onPressed: () {
                                        if((viewmodel.mainUserId == _userManager.userId) || (_helperId == _userManager.userId) || isBotChecker){
                                          setState((){
                                            isCameraSwitched = !isCameraSwitched;
                                            signaling!.switchCamera(isCameraSwitched);
                                          });
                                        }else{
                                          //AlertDialogManager.shortDialog(context, "C'est bientôt ton tour ! ${viewmodel.mainHelperName.isNotEmpty ? CommonFunctionsManager.capitalize(viewmodel.mainHelperName) : "Ton interlocuteur"} termine actuellement une explication avec un élève et poursuivra ensuite avec toi dans quelques instants.",titleColor: Colors.grey);
                                        }
                                      },
                                      child: Icon(
                                        Icons.switch_camera,
                                        color: isCameraSwitched ? Colors.white : Colors.blueAccent,
                                        size: 20.0,
                                      ),
                                      shape: CircleBorder(),
                                      elevation: 2.0,
                                      fillColor: isCameraSwitched ? Colors.blueAccent : Colors.white,
                                      padding: const EdgeInsets.all(12.0),
                                    ),
                                    RawMaterialButton(
                                      onPressed: (){

                                        if((viewmodel.mainUserId == _userManager.userId) || (_helperId == _userManager.userId) || isBotChecker){
                                          setState((){
                                            signaling!.disableCamera(isVideoDisabled);
                                            isVideoDisabled = !isVideoDisabled;
                                          });

                                          if(_userManager.userId == _helperId) {
                                            _userManager.updateValue("temporaryUsersFilesLinks", "helper_is_doing_something",isVideoDisabled, docId: whiteboardId!);
                                          }else if (!isBotChecker) {
                                            _userManager.updateValue("temporaryUsersFilesLinks", "consumer_is_doing_something",isVideoDisabled, docId: whiteboardId!);
                                          }
                                        }else{
                                          //AlertDialogManager.shortDialog(context, "C'est bientôt ton tour ! ${viewmodel.mainHelperName.isNotEmpty ? CommonFunctionsManager.capitalize(viewmodel.mainHelperName) : "Ton interlocuteur"} termine actuellement une explication avec un élève et poursuivra ensuite avec toi dans quelques instants.",titleColor: Colors.grey);
                                        }


                                      },
                                      child: Icon(
                                        Icons.videocam,
                                        color: isVideoDisabled ? Colors.white : Colors.blueAccent,
                                        size: 20.0,
                                      ),
                                      shape: CircleBorder(),
                                      elevation: 2.0,
                                      fillColor: isVideoDisabled ? Colors.blueAccent : Colors.white,
                                      padding: const EdgeInsets.all(12.0),
                                    ),
                                    RawMaterialButton(
                                      onPressed: () async {
                                        if ("2"== viewmodel.startCall){
                                          if((viewmodel.moreUsers.isEmpty || (_userManager.userId! == _helperId)) && !isBotChecker){
                                            lastHelperTemporaryId = await _userManager.getValue("allUsers", "last_helper_temporary_id");
                                            viewmodel.deleteAllFiles();
                                            viewmodel.deleteCallActivity();
                                            viewmodel.endCall(true, lastHelperTemporaryId);
                                          }else{
                                            if(!isBotChecker){
                                              setState(() {
                                                forceQuitChannel = true;
                                              });
                                            }else{
                                              Navigator.pop(context);
                                            }

                                          }
                                        }else{
                                          viewmodel.deleteCallActivity();
                                          Navigator.pop(context);
                                        }
                                      },
                                      child: Icon(Icons.call_end, color: Colors.white),
                                      shape: CircleBorder(),
                                      elevation: 2.0,
                                      fillColor:Colors.red,
                                      padding: const EdgeInsets.all(20),
                                    ),
                                  ],
                                ),
                              ),

                            ),
                          ],
                        ),
                        if ('1' == viewmodel.startCall)
                          Center(
                            child: ShakeWidget(
                              curve: Curves.easeInOutSine,
                              deltaX: 4,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 50,right: 50),
                                child: Container(
                                    width: MediaQuery.of(context).size.width,
                                    height: MediaQuery.of(context).size.height/4,
                                    decoration: BoxDecoration(
                                      color:Colors.white,
                                      //border: Border.all(color: Colors.purpleAccent),
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    child: Stack(
                                      children: [
                                        SquarePercentIndicator(
                                          width: MediaQuery.of(context).size.width,
                                          height: MediaQuery.of(context).size.height/4,
                                          startAngle: StartAngle.topLeft,
                                          //reverse: true,
                                          borderRadius: 20,
                                          shadowWidth: 1.5,
                                          progressWidth: 15,
                                          shadowColor: Colors.grey,
                                          progressColor: showCalling ? Colors.greenAccent : Colors.redAccent,
                                          progress: _progress,
                                          child: Container(
                                              child:Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    //color: Colors.red,
                                                    height: (MediaQuery.of(context).size.height/4) - (MediaQuery.of(context).size.height/6),
                                                    child: Container(
                                                      child: Center(
                                                        child: Text(
                                                            showCalling ? (showSearchMore ? "Élargissement de la zone\nde recherche..." : "Demande en cours...") : "Aucune réponse...",
                                                            textAlign: TextAlign.center,
                                                            style: GoogleFonts.poppins(
                                                              color: Colors.black,
                                                              fontSize: 15,
                                                              //fontWeight: FontWeight.bold
                                                            )

                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  showCalling ?
                                                  Container(
                                                    child: Image.asset(
                                                      "images/searching.gif",
                                                      height: MediaQuery.of(context).size.height/6,
                                                      fit: BoxFit.contain,
                                                    ),
                                                  )
                                                      :
                                                  Padding(
                                                    padding: const EdgeInsets.all(8.0),
                                                    child: Container(
                                                      child: Text(
                                                          not_found,
                                                          textAlign: TextAlign.justify,
                                                          style: GoogleFonts.poppins(
                                                            color: Colors.grey,
                                                            fontSize: 15,
                                                            //fontWeight: FontWeight.bold
                                                          )
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              )
                                          ),
                                        ),
                                      ],
                                    )
                                ),
                              ),
                            ),
                          ),
                        if (('2' == viewmodel.startCall) && (viewmodel.liveNearlyClosed == _userManager.userId!) && !showAlertMessage)
                          AlertDialog(
                            backgroundColor: Colors.orange,
                            title:
                            Text("Le LIVE se termine bientôt",
                                style: GoogleFonts.poppins(
                                    color: Colors.yellow,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold
                                )),
                            content: (_userManager.userId == viewmodel.helperId) ?
                            null
                                :
                            Text("Oups ! Ton forfait est bientôt épuisé. La session en cours s'arrêtera dans 1 minute."),
                            actions: [
                              Container(
                                height: 40,
                                width: 80,
                                color: Colors.blue,
                                child: TextButton(
                                    onPressed: () async {
                                      setState(() {
                                        showAlertMessage = true;
                                      });
                                    },
                                    child: Text("OK",style: TextStyle(
                                        color: Colors.white
                                    ),)),
                              ),
                            ],
                          ),
                        if ('0' == viewmodel.startCall)
                          FutureBuilder<void>(
                              future: prepareAlert(),
                              builder:(context, AsyncSnapshot<void>? snapshot) {
                                viewmodel.deleteAllFiles();
                                deleteWhiteboardAndFiles();
                                return Scaffold(
                                  backgroundColor: Colors.transparent,
                                  body: AlertDialog(
                                    title: Text((_helperName.isNotEmpty ? _helperName : "L'interlocuter") + " ne répond pas pour le moment..."),
                                    content: Text("Réessaies plus tard 😌"),
                                  ),
                                );
                              }),
                        if(!isBotChecker && (viewmodel.mainUserId != _userManager.userId) && (_helperId != _userManager.userId) && (viewmodel.swapUserId.isEmpty) && viewmodel.mainHelperName.isNotEmpty)
                          ShakeWidget(
                            curve: Curves.easeInOutSine,
                            deltaX: 4,
                            child: AlertDialog(
                              title: Text(
                                  "${/*viewmodel.mainHelperName.isNotEmpty ? CommonFunctionsManager.capitalize(viewmodel.mainHelperName) :*/ "Ton interlocuteur"} termine actuellement une explication avec un élève et poursuivra ensuite avec toi dans quelques instants. Ne bouges pas !",
                                  textAlign: TextAlign.center
                              ),
                              content: Center(
                                  widthFactor: 1,
                                  heightFactor: 1,
                                  child:
                                  Container(
                                    height: 150,
                                    padding: const EdgeInsets.all(20.0),
                                    child: Image.asset(
                                      "images/teaching_official.gif",
                                      fit: BoxFit.contain,
                                    ),
                                  )
                                //TwoFlyingDots(dotsSize: 18, firstColor: Colors.blue, secondColor: Colors.yellow),
                              ),
                            ),
                          ),
                        if (viewmodel.swapUserId.isNotEmpty)
                          ShakeWidget(
                            curve: Curves.easeInOutSine,
                            deltaX: 4,
                            child: AlertDialog(
                              title: Text(
                                  "Changement d'utilisateur...",
                                  textAlign: TextAlign.center
                              ),
                              content: Center(
                                  widthFactor: 1,
                                  heightFactor: 1,
                                  child:
                                  Container(
                                    height: 150,
                                    padding: const EdgeInsets.all(20.0),
                                    child: Image.asset(
                                      "images/waiting_transparent.gif",
                                      fit: BoxFit.contain,
                                    ),
                                  )
                                //TwoFlyingDots(dotsSize: 18, firstColor: Colors.blue, secondColor: Colors.yellow),
                              ),
                            ),
                          ),
                      ]
                  ),
                ),
              ),
            );
          }
        }
    );
  }
}

class WhiteboardPageAdvancedRoute extends MaterialPageRoute<void> {

  WhiteboardPageAdvancedRoute(String id, String token_call, {
    required String userId,
    required String helperId,
    required String serverDestination,
    String? callerAvatar = null,
    String? isNewUser = null,
    String? pseudo = null,
    int fromPreviousTime = 0,
    var signaling = null, //Signaling? signaling = null,
    RTCVideoRenderer? localRenderer = null,
    RTCVideoRenderer? remoteRenderer = null,
    bool enableAutoResearch = false,
    String searchInput = "",
    bool isMoreUser = false,
    String taskId = "",
    bool isBotChecker = false,
    List? moreUsersAttending = null,
    String fullSpotPathOption = "",
    bool receiverIsHelper = true,
    String globalUserCountryCode = ""
  })
      : super(
    builder: (context) => ChangeNotifierProvider<WhiteboardViewModel>(
      create: (context) {
        final firestore = Provider.of<FirebaseFirestore>(context, listen: false);
        return WhiteboardViewModel(firestore, id, userId, helperId, taskId);
      },
      child: WithForegroundTask(
          child: WhiteboardPageAdvanced(id, token_call, fromPreviousTime, helperId, signaling,localRenderer,remoteRenderer, callerAvatar,isNewUser,pseudo, searchInput, enableAutoResearch, serverDestination, isMoreUser, isBotChecker, userId,moreUsersAttending: moreUsersAttending, fullSpotPathOption:fullSpotPathOption,receiverIsHelper:receiverIsHelper, globalUserCountryCode:globalUserCountryCode)),
    ),
  );
}