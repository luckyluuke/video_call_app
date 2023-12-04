import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'whiteboard_features/whiteboard_advanced_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Video Call App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: InkWell(
          onTap: (){
            Navigator.push(
                context,
                WhiteboardPageAdvancedRoute(
                    "whiteboardId",
                    "whiteboardId",
                    serverDestination: "192.1.56.10",
                    userId: "user",
                    helperId: "user13",
                    callerAvatar: "/avatar_real.png",
                    isNewUser: "false",
                    pseudo: "user1",
                    searchInput: "",
                    enableAutoResearch: false,
                    globalUserCountryCode: "FR",
                    taskId: "task10",
                    fullSpotPathOption:"2022.09.23",
                    receiverIsHelper:  false
                )
            );
          },
          child: Text(
              "Start a new call",
              style: GoogleFonts.inter(
                color: Colors.grey,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              textAlign:TextAlign.center
          ),
        )
    );
  }
}
