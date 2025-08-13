import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trinetraflutter/back/posePointer_superman.dart';
import 'package:trinetraflutter/camera_view_timer.dart';
import 'package:trinetraflutter/routine_value.dart';
import 'package:trinetraflutter/values_timer.dart';

class Superman extends StatefulWidget {
  const Superman({super.key});

  @override
  State<Superman> createState() => _SupermanState();
}

class _SupermanState extends State<Superman> {
  PoseDetector poseDetector = GoogleMlKit.vision.poseDetector();
  PoseLandmarkType pos1 = PoseLandmarkType.leftEar;
  PoseLandmarkType pos2 = PoseLandmarkType.leftHip;
  PoseLandmarkType pos3 = PoseLandmarkType.leftAnkle;

  bool isBusy = false;
  CustomPaint? customPaint;

  Future<void> storeCalories() async {
    print("Calories Counted");
    final prefs = await SharedPreferences.getInstance();
    var cal = (timer * 0.2).ceilToDouble();
    var userDetails = FirebaseAuth.instance.currentUser;

    if (prefs.getString('date') != null) {
      if (prefs.getString('date') ==
          "${DateTime.now().day} - ${DateTime.now().month} - ${DateTime.now().year}") {
        var calories = prefs.getDouble('back') ?? 0;
        routine[6] = routine[6] + cal;
        cal = calories + cal;
        prefs.setDouble('back', cal);
        await FirebaseFirestore.instance
            .collection('userInfo')
            .doc(userDetails!.uid)
            .update(
          {
            "routine": routine,
          },
        );
      } else {
        prefs.setString('date',
            "${DateTime.now().day} - ${DateTime.now().month} - ${DateTime.now().year}");
        prefs.setDouble('back', cal);
        double abs = prefs.getDouble('abs') ?? 0;
        double quads = prefs.getDouble('quads') ?? 0;
        double glutes = prefs.getDouble('glutes') ?? 0;
        double chest = prefs.getDouble('chest') ?? 0;
        prefs.setDouble('abs', abs);
        prefs.setDouble('quads', quads);
        prefs.setDouble('glutes', glutes);
        prefs.setDouble('chest', chest);

        routine.removeAt(0);
        routine.add(cal);
        await FirebaseFirestore.instance
            .collection('userInfo')
            .doc(userDetails!.uid)
            .update(
          {
            "routine": routine,
          },
        );
      }
    } else {
      prefs.setString('date',
          "${DateTime.now().day} - ${DateTime.now().month} - ${DateTime.now().year}");
      prefs.setDouble('back', cal);
      routine.removeAt(0);
      routine.add(cal);
      await FirebaseFirestore.instance
          .collection('userInfo')
          .doc(userDetails!.uid)
          .update(
        {
          "routine": routine,
        },
      );
    }
    print("Counter: $timer \n Calories: $cal");
  }

  @override
  void initState() {
    ResetTimerValue();
    super.initState();
  }

  @override
  void dispose() async {
    super.dispose();
    await storeCalories();
    await poseDetector.close();
  }

  @override
  Widget build(BuildContext context) {
    return CameraViewTimer(
      customPaint: customPaint,
      onImage: (inputImage) {
        processImage(inputImage);
      },
    );
  }

  Future<void> processImage(InputImage inputImage) async {
    if (isBusy) return;
    isBusy = true;
    final poses = await poseDetector.processImage(inputImage);

    if (inputImage.inputImageData?.size != null &&
        inputImage.inputImageData?.imageRotation != null) {
      final painter = PosePointer_Superman(
        poses,
        inputImage.inputImageData!.size,
        inputImage.inputImageData!.imageRotation,
        110,
        125,
        75,
        95,
        pos1,
        pos2,
        pos3,
      );
      customPaint = CustomPaint(painter: painter);
    } else {
      customPaint = null;
    }
    isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }
}
