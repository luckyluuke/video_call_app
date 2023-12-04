import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:video_call_app/UserManager.dart';
import 'package:video_call_app/enums.dart';
import 'package:video_call_app/whiteboard_features/whiteboard_view_model.dart';

typedef void StreamStateCallback(MediaStream stream);
typedef void StreamConnectionStateCallback(RTCPeerConnectionState state);

class Signaling {

  Signaling(String serverDestination){
    this.ipAddress = serverDestination.split("/").elementAt(0);
    this.port = serverDestination.split("/").elementAt(1);
  }

  Map<String, dynamic> getConfig() => {
    'iceTransportPolicy': "relay",
    'iceServers': [
      {
        'urls': [
          "turn:" + this.ipAddress! + ":" + this.port! + "?transport=tcp",
          "turn:" + this.ipAddress! + ":" + this.port! + "?transport=udp",
        ],
        'username':'generic',
        'credential':'genericpassword'
      }
    ]
  };

  UserManager _userManager = UserManager();
  StreamSubscription? _subscriptionCaller;
  StreamSubscription? _subscriptionCallee;
  StreamSubscription? _subscriptionRoomRefUpdate;
  RTCPeerConnection? peerConnection;
  RTCPeerConnection? peerConnectionSecondUser;
  MediaStream? localStream;
  MediaStream? remoteStream;
  MediaStream? secondUserRemoteStream;
  String? roomId;
  String? currentRoomText;
  StreamStateCallback? onAddRemoteStream;
  StreamConnectionStateCallback? onConnectionState;
  StreamStateCallback? onSecondUserAddRemoteStream;
  StreamConnectionStateCallback? onSecondUserConnectionState;
  String? ipAddress;
  String? port;
  bool changeVideoMode = false;

  Future<String> createRoom(String whiteboardId) async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference roomRef = db.collection('rooms').doc(whiteboardId);

    debugPrint("Create PeerConnection with configuration: " + getConfig().toString());

    peerConnection = await createPeerConnection(getConfig());

    registerPeerConnectionListeners();

    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });

    // Code for collecting ICE candidates below
    var callerCandidatesCollection = roomRef.collection('callerCandidates');

    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      print('Got candidate: ${candidate.toMap()}');
      callerCandidatesCollection.add(candidate.toMap());
    };
    // Finish Code for collecting ICE candidate

    // Add code for creating a room
    RTCSessionDescription offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);
    print('Created offer: $offer');

    var createdTime = DateTime.now().microsecondsSinceEpoch;

    Map<String, dynamic> roomWithOffer = {
      'created': createdTime,
      'offer': offer.toMap()
    };

    await roomRef.set(roomWithOffer);
    roomId = roomRef.id;
    print('New room created with SDK offer. Room ID: $roomId');
    currentRoomText = 'Current room is $roomId - You are the caller!';
    // Created a Room

    peerConnection?.onTrack = (RTCTrackEvent event) {
      print('Got remote track: ${event.streams[0]}');

      event.streams[0].getTracks().forEach((track) {
        print('Add a track to the remoteStream $track');
        remoteStream?.addTrack(track);
      });
    };

    // Listening for remote session description below
    _subscriptionRoomRefUpdate = roomRef.snapshots().listen((snapshot) async {

      print('Got updated room 1: ${snapshot.data()}');

      if(snapshot.data() != null){

        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        if (peerConnection?.getRemoteDescription() != null && data['answer'] != null && data['isBotChecker'] == null) {
          var answer = RTCSessionDescription(
            data['answer']['sdp'],
            data['answer']['type'],
          );

          print("Someone tried to connect");

          try{
            await peerConnection?.setRemoteDescription(answer); //TODO: Error when user calls + shares screen with helper interruption

            await roomRef.update({
              "answer":FieldValue.delete(),
              "offer":FieldValue.delete()
            });
          }catch(error){
            print("Warning: Someone tried to connect but couldn't set remote description.");
          }

        }
      }

    });
    // Listening for remote session description above

    // Listen for remote Ice candidates below
    _subscriptionCallee = roomRef.collection('calleeCandidates').snapshots().listen((snapshot) {
      snapshot.docChanges.forEach((change) {
        if (change.type == DocumentChangeType.added) {
          if (peerConnection != null && (peerConnection!.connectionState != RTCPeerConnectionState.RTCPeerConnectionStateClosed)){
            Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
            print('Got new remote ICE candidate: ${jsonEncode(data)}');
            peerConnection!.addCandidate(
              RTCIceCandidate(
                data['candidate'],
                data['sdpMid'],
                data['sdpMLineIndex'],
              ),
            );
          }

        }
      });
    });
    // Listen for remote ICE candidates above

    return roomId!;
  }

  Future<void> joinRoom(String _roomId, int streamId,{int numOfUsersDone = 0}) async {
    roomId = _roomId;
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference roomRef = db.collection('rooms').doc('$roomId');
    var roomSnapshot = await roomRef.get();
    print('Got room ${roomSnapshot.exists}');

    if (roomSnapshot.exists) {
      debugPrint('Create PeerConnection with configuration: ' + getConfig().toString());

      if(numOfUsersDone < 1){
        peerConnection = await createPeerConnection(getConfig());
      }else{
        peerConnectionSecondUser = await createPeerConnection(getConfig());
      }


      (numOfUsersDone < 1) ? registerPeerConnectionListeners() : registerPeerConnectionSecondUserListeners();
      localStream?.getTracks().forEach((track) {
        ((numOfUsersDone < 1) ? peerConnection : peerConnectionSecondUser)?.addTrack(track, localStream!);
      });

      // Code for collecting ICE candidates below
      var calleeCandidatesCollection = roomRef.collection('calleeCandidates');
      ((numOfUsersDone < 1) ? peerConnection : peerConnectionSecondUser)!.onIceCandidate = (RTCIceCandidate candidate) {
        if (candidate == null) {
          print('onIceCandidate: complete!');
          return;
        }
        print('onIceCandidate: ${candidate.toMap()}');
        calleeCandidatesCollection.add(candidate.toMap());
      };
      // Code for collecting ICE candidate above

      ((numOfUsersDone < 1) ? peerConnection : peerConnectionSecondUser)?.onTrack = (RTCTrackEvent event) {
        print('Got remote track: ${event.streams[streamId]}');
        event.streams[streamId].getTracks().forEach((track) {
          print('Add a track to the remoteStream: $track');
          ((numOfUsersDone <1) ? remoteStream : secondUserRemoteStream)?.addTrack(track);
        });
      };

      // Code for creating SDP answer below
      var data = roomSnapshot.data() as Map<String, dynamic>;
      print('Got offer $data');
      var offer = data['offer'];
      await ((numOfUsersDone < 1) ? peerConnection : peerConnectionSecondUser)?.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']),
      );

      //TODO:Uncomment below
      var answer = await ((numOfUsersDone < 1) ? peerConnection : peerConnectionSecondUser)!.createAnswer();
      print('Created Answer $answer');
      await ((numOfUsersDone < 1) ? peerConnection : peerConnectionSecondUser)!.setLocalDescription(answer);

      //TODO:Uncomment below
      Map<String, dynamic> roomWithAnswer = {
        'answer': {'type': answer.type, 'sdp': answer.sdp}
      };

      await roomRef.update(roomWithAnswer);
      // Finished creating SDP answer

      // Listening for remote ICE candidates below
      _subscriptionCaller = roomRef.collection('callerCandidates').snapshots().listen((snapshot) {

        //TODO:Uncomment below
        snapshot.docChanges.forEach((document) {

          if (((peerConnection != null) && (peerConnection!.connectionState != RTCPeerConnectionState.RTCPeerConnectionStateClosed)) || ((peerConnectionSecondUser != null) && (peerConnectionSecondUser!.connectionState != RTCPeerConnectionState.RTCPeerConnectionStateClosed))) {
            var data = document.doc.data() as Map<String, dynamic>;
            print(data);
            print('Got new remote ICE candidate: $data');
            ((numOfUsersDone < 1) ? peerConnection : peerConnectionSecondUser)!.addCandidate(
              RTCIceCandidate(
                data['candidate'],
                data['sdpMid'],
                data['sdpMLineIndex'],
              ),
            );

            /*NotificationApi.createNormalNotificationBasicChannel(
                NotificationId.USER_ADDED,
                "Un nouvel utilisateur a rejoint la session",
                "Revenez sur l'application."
            );*/
          }


        });

      });

    }
  }

  Future<void> updateRoom(String _roomId, {String avatarUrl = "", String name = "", bool triggeredFromHelper = false}) async {


    if (remoteStream != null) {
      remoteStream!.getTracks().forEach((track) => track.stop());
      remoteStream = null;
    }

    if (peerConnection != null){
      await peerConnection!.close();
      peerConnection = null;
    }

    if(_subscriptionRoomRefUpdate != null){
      await _subscriptionRoomRefUpdate!.cancel();
      _subscriptionRoomRefUpdate = null;
    }

    if(_subscriptionCallee != null){
      await _subscriptionCallee!.cancel();
      _subscriptionCallee = null;
    }




    roomId = _roomId;
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference roomRef = db.collection('rooms').doc('$roomId');
    var roomSnapshot = await roomRef.get();
    print('Got room ${roomSnapshot.exists}');

    if (roomSnapshot.exists) {

      debugPrint('Create PeerConnection with configuration: ' + getConfig().toString());
      peerConnection = await createPeerConnection(getConfig());
      registerPeerConnectionListeners();
      localStream?.getTracks().forEach((track) {
        peerConnection?.addTrack(track, localStream!);
      });


      var callerCandidatesCollection = roomRef.collection('callerCandidates');

      peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
        print('Got candidate: ${candidate.toMap()}');
        callerCandidatesCollection.add(candidate.toMap());
      };
      // Finish Code for collecting ICE candidate

      // Add code for creating a room
      RTCSessionDescription offer = await peerConnection!.createOffer();
      await peerConnection!.setLocalDescription(offer);
      print('Created offer: $offer');

      var createdTime = DateTime.now().microsecondsSinceEpoch;

      Map<String, dynamic> roomWithOffer = {
        'created': createdTime,
        'offer': offer.toMap()
      };

      await roomRef.update(roomWithOffer);
      roomId = roomRef.id;
      print('New room created with SDK offer. Room ID: $roomId');
      currentRoomText = 'Current room is $roomId - You are the caller!';
      // Created a Room

      peerConnection?.onTrack = (RTCTrackEvent event) {
        print('Got remote track: ${event.streams[0]}');
        event.streams[0].getTracks().forEach((track) {
          print('Add a track to the remoteStream $track');
          remoteStream?.addTrack(track);
        });
      };

      // Listening for remote session description below
      _subscriptionRoomRefUpdate = roomRef.snapshots().listen((snapshot) async {

        print('Got updated room 2: ${snapshot.data()}');

        if(snapshot.data() != null){
          /*NotificationApi.createNormalNotificationBasicChannel(
              NotificationId.USER_ADDED,
              "Un nouvel utilisateur a rejoint la session",
              "Revenez sur l'application."
          );*/
        }


        if(snapshot.data() != null){
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          if (peerConnection?.getRemoteDescription() != null &&
              data['answer'] != null && data['isBotChecker'] == null) {

            var answer = RTCSessionDescription(
              data['answer']['sdp'],
              data['answer']['type'],
            );

            print("Someone tried to connect with state=${peerConnection?.signalingState.toString()}");

            try{
              await peerConnection?.setRemoteDescription(answer); //TODO: Error when user calls + shares screen with helper interruption

              await roomRef.update({
                "answer":FieldValue.delete(),
                "offer":FieldValue.delete()
              });

              _userManager.updateMultipleValues(
                  "temporaryUsersFilesLinks",
                  {
                    "swapUserId": "",
                    "isSharing":"",
                    "consumer_is_doing_something":false
                  },
                  docId: roomId!
              );


              if (triggeredFromHelper){
                if (remoteStream != null){
                  if(!remoteStream!.getAudioTracks()[0].enabled) remoteStream!.getAudioTracks()[0].enabled = true;
                  if(!remoteStream!.getVideoTracks()[0].enabled) remoteStream!.getVideoTracks()[0].enabled = true;

                }
              }

            }catch(error){
              print("Warning: Someone tried to connect but something went wrong.");
            }


            stopForegroundTask();

          }
        }

      });
      // Listening for remote session description above

      // Listen for remote Ice candidates below
      _subscriptionCallee = roomRef.collection('calleeCandidates').snapshots().listen((snapshot) {
        snapshot.docChanges.forEach((change) {
          if (change.type == DocumentChangeType.added) {

            if (peerConnection != null && (peerConnection!.connectionState != RTCPeerConnectionState.RTCPeerConnectionStateClosed)){
              Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
              print('Got new remote ICE candidate: ${jsonEncode(data)}');
              peerConnection!.addCandidate(
                RTCIceCandidate(
                  data['candidate'],
                  data['sdpMid'],
                  data['sdpMLineIndex'],
                ),
              );
            }

          }
        });
      });

      if (avatarUrl.isNotEmpty){

        await _userManager.updateMultipleValues(
            "status",
            {
              _userManager.userId!: 0
            },
            docId: roomId!
        );

        await _userManager.updateMultipleValues(
            "temporaryUsersFilesLinks",
            {
              'moreUsers':FieldValue.arrayUnion([
                {
                  'name':name,
                  'userId': _userManager.userId,
                  'avatarUrl': avatarUrl,
                  'lastUpdatedServer':0,
                }
              ]),
            },
            docId: roomId!
        );

      }

    }
  }

  Future<void> addUsers(String _roomId, {String avatarUrl = "", String name = "", bool isBotChecker = false, int numOfUsersDone = 0, List? users = null}) async {

    if(_subscriptionRoomRefUpdate != null){
      await _subscriptionRoomRefUpdate!.cancel();
      _subscriptionRoomRefUpdate = null;
    }

    if(_subscriptionCallee != null){
      await _subscriptionCallee!.cancel();
      _subscriptionCallee = null;
    }



    roomId = _roomId;
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference roomRef = db.collection('rooms').doc('$roomId');
    var roomSnapshot = await roomRef.get();
    print('Got room ${roomSnapshot.exists}');


    if (roomSnapshot.exists) {

      debugPrint('Create PeerConnection with configuration: ' + getConfig().toString());

      try{
        roomSnapshot.get("isBotChecker");
      }catch(error){
        await roomRef.set({
          "isBotChecker":true,
        },
            SetOptions(merge: true)
        );
      }

      if(numOfUsersDone < 1){
        peerConnection = await createPeerConnection(getConfig());
      }else{
        peerConnectionSecondUser = await createPeerConnection(getConfig());
      }

      (numOfUsersDone < 1) ? registerPeerConnectionListeners() : registerPeerConnectionSecondUserListeners();
      localStream?.getTracks().forEach((track) {
        ((numOfUsersDone < 1) ? peerConnection : peerConnectionSecondUser)?.addTrack(track, localStream!);
      });


      var callerCandidatesCollection = roomRef.collection('callerCandidates');

      ((numOfUsersDone < 1) ? peerConnection : peerConnectionSecondUser)?.onIceCandidate = (RTCIceCandidate candidate) {
        print('Got candidate: ${candidate.toMap()}');
        callerCandidatesCollection.add(candidate.toMap());
      };
      // Finish Code for collecting ICE candidate

      // Add code for creating a room
      RTCSessionDescription offer = await ((numOfUsersDone < 1) ? peerConnection : peerConnectionSecondUser)!.createOffer();
      await ((numOfUsersDone <1) ? peerConnection : peerConnectionSecondUser)!.setLocalDescription(offer);
      print('Created offer: $offer');

      var createdTime = DateTime.now().microsecondsSinceEpoch;

      Map<String, dynamic> roomWithOffer = {
        'created': createdTime,
        'offer': offer.toMap()
      };

      await roomRef.update(roomWithOffer);
      roomId = roomRef.id;
      print('New room created with SDK offer. Room ID: $roomId');
      currentRoomText = 'Current room is $roomId - You are the caller!';
      // Created a Room

      ((numOfUsersDone <1) ? peerConnection : peerConnectionSecondUser)?.onTrack = (RTCTrackEvent event) {
        print('Got remote track: ${event.streams[0]}');
        event.streams[0].getTracks().forEach((track) {
          print('Add a track to the remoteStream $track');
          ((numOfUsersDone <1) ? remoteStream : secondUserRemoteStream)?.addTrack(track);
        });
      };

      // Listening for remote session description below
      _subscriptionRoomRefUpdate = roomRef.snapshots().listen((snapshot) async {

        print('Got updated room 3: ${snapshot.data()}');

        if(snapshot.data() != null){
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          if (((numOfUsersDone < 1) ? peerConnection : peerConnectionSecondUser)?.getRemoteDescription() != null &&
              data['answer'] != null && data['isBotChecker'] != null) {

            var answer = RTCSessionDescription(
              data['answer']['sdp'],
              data['answer']['type'],
            );

            print("Someone tried to connect with state=${((numOfUsersDone < 1) ? peerConnection : peerConnectionSecondUser)?.signalingState.toString()}");

            try{
              await ((numOfUsersDone < 1) ? peerConnection : peerConnectionSecondUser)?.setRemoteDescription(answer);

              await roomRef.update({
                "answer":FieldValue.delete(),
                "offer":FieldValue.delete(),
              });

              await Future.delayed(Duration(seconds: 2));

              if (!isBotChecker){

                _userManager.updateMultipleValues(
                    "temporaryUsersFilesLinks",
                    {
                      "swapUserId": "",
                      "isSharing": ""
                    },
                    docId: roomId!
                );

              }else {
                if (numOfUsersDone < 1){
                  await addUsers(
                      roomId!,
                      //avatarUrl: avatarUrl,
                      //name: name,
                      isBotChecker: isBotChecker,
                      numOfUsersDone : 1,
                      users: users
                  );
                }else {
                  _userManager.updateValue("temporaryUsersFilesLinks", "isBotChecker", "",docId: roomId!);
                  await roomRef.update({
                    "isBotChecker":FieldValue.delete(),
                  });
                }
              }
            }catch(error){
              print("Warning: Someone tried to connect but error found.");
            }

            if (!isBotChecker){
              stopForegroundTask();
            }

          }
        }

      });
      // Listening for remote session description above

      // Listen for remote Ice candidates below
      _subscriptionCallee = roomRef.collection('calleeCandidates').snapshots().listen((snapshot) {
        snapshot.docChanges.forEach((change) {
          if (change.type == DocumentChangeType.added) {

            if (((peerConnection != null) && (peerConnection!.connectionState != RTCPeerConnectionState.RTCPeerConnectionStateClosed)) || ((peerConnectionSecondUser != null) && (peerConnectionSecondUser!.connectionState != RTCPeerConnectionState.RTCPeerConnectionStateClosed))) {
              Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
              print('Got new remote ICE candidate: ${jsonEncode(data)}');
              ((numOfUsersDone < 1) ? peerConnection : peerConnectionSecondUser)!.addCandidate(
                RTCIceCandidate(
                  data['candidate'],
                  data['sdpMid'],
                  data['sdpMLineIndex'],
                ),
              );
            }

          }
        });
      });

      await _userManager.updateMultipleValues(
          "temporaryUsersFilesLinks",
          {
            'isBotChecker': (numOfUsersDone < 1) ? users![0] : users![1]
          },
          docId: roomId!
      );

    }
  }

  Future<void> openUserMedia(
      RTCVideoRenderer localVideo,
      RTCVideoRenderer remoteVideo,
      RTCVideoRenderer? remoteVideoSecondUser,
      ) async {

    var stream = await navigator.mediaDevices.getUserMedia(
        {
          'video': {
            'facingMode':'user'
          },
          'audio': true
        }
    );
    localVideo.srcObject = stream;
    localStream = stream;

    remoteVideo.srcObject = await createLocalMediaStream('key');
    if(remoteVideoSecondUser != null){
      remoteVideoSecondUser.srcObject = await createLocalMediaStream('keySecond');
    }
  }

  Future<void> hangUp(RTCVideoRenderer localVideo,{bool canDelete = true}) async {

    if (localVideo.srcObject != null){
      List<MediaStreamTrack> tracks = localVideo.srcObject!.getTracks();
      tracks.forEach((track) {
        track.stop();
      });
    }


    if (remoteStream != null) {
      remoteStream!.getTracks().forEach((track) => track.stop());
    }
    if (peerConnection != null) peerConnection!.close();

    if (secondUserRemoteStream != null) {
      secondUserRemoteStream!.getTracks().forEach((track) => track.stop());
    }
    if (peerConnectionSecondUser != null) peerConnectionSecondUser!.close();

    if(canDelete){
      if (roomId != null) {
        var db = FirebaseFirestore.instance;
        var roomRef = db.collection('rooms').doc(roomId);
        var calleeCandidates = await roomRef.collection('calleeCandidates').get();
        calleeCandidates.docs.forEach((document) => document.reference.delete());

        var callerCandidates = await roomRef.collection('callerCandidates').get();
        callerCandidates.docs.forEach((document) => document.reference.delete());

        await roomRef.delete();
      }
    }

    //if(Platform.isAndroid){
      stopForegroundTask();
    //}

    localStream?.dispose();
    remoteStream?.dispose();
    secondUserRemoteStream?.dispose();
  }

  Future<void> refreshSession(RTCVideoRenderer localVideo, { WhiteboardViewModel? viewModel = null}) async {

      if (remoteStream != null) {
        remoteStream!.getTracks().forEach((track) => track.stop());
        remoteStream = null;
      }

      if (peerConnection != null) {
        await peerConnection!.close();
        peerConnection = null;
      }


      if (_subscriptionCaller != null){
        await _subscriptionCaller!.cancel();
        _subscriptionCaller = null;
      }

      if(_subscriptionRoomRefUpdate != null){
        await _subscriptionRoomRefUpdate!.cancel();
        _subscriptionRoomRefUpdate = null;
      }

      if(_subscriptionCallee != null){
        await _subscriptionCallee!.cancel();
        _subscriptionCallee = null;
      }

      if(viewModel != null){
        await viewModel.updateMoreUsers(true);
      }

      await Future.delayed(Duration(seconds: 2));

      await joinRoom(roomId!,0);

  }

  Future<void> refreshBotSession(RTCVideoRenderer localVideo, { WhiteboardViewModel? viewModel = null}) async {


    if (_subscriptionCaller != null){
      await _subscriptionCaller!.cancel();
      _subscriptionCaller = null;
    }

    if(_subscriptionRoomRefUpdate != null){
      await _subscriptionRoomRefUpdate!.cancel();
      _subscriptionRoomRefUpdate = null;
    }

    if(_subscriptionCallee != null){
      await _subscriptionCallee!.cancel();
      _subscriptionCallee = null;
    }

    await joinRoom(roomId!,0, numOfUsersDone: 1);

  }

  Future<void> swapUser(RTCVideoRenderer localVideo, int index, {WhiteboardViewModel? viewModel = null, bool mainUserHasLeft = false}) async {

    if (remoteStream != null) {
      remoteStream!.getTracks().forEach((track) => track.stop());
      remoteStream = null;
    }

    if (peerConnection != null) {
      await peerConnection!.close();
      peerConnection = null;
    }


    if (_subscriptionCaller != null){
      await _subscriptionCaller!.cancel();
      _subscriptionCaller = null;
    }

    if(_subscriptionRoomRefUpdate != null){
      await _subscriptionRoomRefUpdate!.cancel();
      _subscriptionRoomRefUpdate = null;
    }

    if(_subscriptionCallee != null){
      await _subscriptionCallee!.cancel();
      _subscriptionCallee = null;
    }



    if(viewModel != null){
      await viewModel.updateMoreUsers(false, index: index, mainUserHasLeft:mainUserHasLeft);
    }

    //await Future.delayed(Duration(seconds: 1));

    await updateRoom(roomId!, triggeredFromHelper: true);

  }

  void muteMic(bool enable) {
    if (localStream != null) {
      localStream!.getAudioTracks()[0].enabled = enable;
    }
  }

  void disableCamera(bool enable) {
    if (localStream != null) {
      localStream!.getVideoTracks()[0].enabled = enable;
    }
  }

  void switchCamera(bool enable) {
    if (localStream != null) {
      Helper.switchCamera(localStream!.getVideoTracks()[0]);
    }
  }

  Future<bool> shareScreen(bool enable) async {
    if (localStream != null) {

      if (enable){

        Map<String,dynamic> constraintsAndroid = {};
        Map<String,dynamic> constraintsIOS = {
          'video': {
            'deviceId': 'broadcast',
          },
        };

        //if(Platform.isAndroid){
          await _startForegroundTask();
        //}

        MediaStream? newStream;
        try{
          newStream = await navigator.mediaDevices.getDisplayMedia(
              Platform.isAndroid ? constraintsAndroid : constraintsIOS
          );
        }catch(error){
          //if(Platform.isAndroid){
            await stopForegroundTask();
          //}

          return false;
        }

        var newTrack = newStream.getVideoTracks()[0];
        var allSenders = await peerConnection!.getSenders();

        for(int senderIndex = 0; senderIndex<allSenders.length; senderIndex++){
          if((allSenders[senderIndex].track != null) && (allSenders[senderIndex].track!.kind == 'video')){
            await allSenders[senderIndex].replaceTrack(newTrack);
          }
        }

      }else {


        //if(Platform.isAndroid){
          await stopForegroundTask();
        //}


        var previousSenders = await peerConnection!.getSenders();
        for(int previousSenderIndex = 0; previousSenderIndex<previousSenders.length; previousSenderIndex++){
          if((previousSenders[previousSenderIndex].track != null) && (previousSenders[previousSenderIndex].track!.kind == 'video')){
            await previousSenders[previousSenderIndex].replaceTrack(localStream!.getVideoTracks()[0]);
          }
        }

      }
    }

    return true;
  }

  Future<bool> stopReplayKit() async {
    const MethodChannel _channel = const MethodChannel('my_first_app.stopReplayKitNotification');
    final bool status = await _channel.invokeMethod('stopReplayKitNotification');
    return status;
  }

  Future<void> _startForegroundTask() async {

    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.restartService();
    } else {
      await FlutterForegroundTask.startService(
        notificationTitle: 'Partage d\'écran en cours...',
        notificationText: 'Tapes ici pour revenir sur l\'appli',
      );
    }
  }

  Future<void> stopForegroundTask() async {

    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }


  void registerPeerConnectionListeners() {
    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      print('ICE gathering state changed: $state');
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      print('Connection state change: $state');
      onConnectionState?.call(state);
    };

    peerConnection?.onSignalingState = (RTCSignalingState state) {
      print('Signaling state change: $state');
    };

    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      print('ICE connection state change: $state');
    };

    peerConnection?.onAddStream = (MediaStream stream) {
      print("Add remote stream");
      onAddRemoteStream?.call(stream);
      remoteStream = stream;
    };

  }

  void switchVideoMode(){
    changeVideoMode = true;
  }

  void registerPeerConnectionSecondUserListeners() {

    peerConnectionSecondUser?.onConnectionState = (RTCPeerConnectionState state) {
      print('PeerConnectionSecondUser Connection state change: $state');
      onSecondUserConnectionState?.call(state);
    };

    peerConnectionSecondUser?.onAddStream = (MediaStream stream) {
      print("PeerConnectionSecondUser Add remote stream");
      onSecondUserAddRemoteStream?.call(stream);
      secondUserRemoteStream = stream;
    };
  }

}