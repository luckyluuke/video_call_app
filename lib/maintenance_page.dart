import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_call_app/main.dart';

class MaintenancePage extends StatefulWidget {
  MaintenancePage();
  @override
  _MaintenancePageState createState() => _MaintenancePageState();
}


class _MaintenancePageState extends State<MaintenancePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Maintenance',
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.yellow,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                  "L'application est actuellement en maintenance ! Elle sera de nouveau accessible dans quelques instants."),
            ),
          ],
        ),
      ),
    );
  }

}