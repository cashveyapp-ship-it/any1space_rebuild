import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'app/app.dart';
import 'firebase_options.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/fcm_token_service.dart';
//import 'package:firebase_app_check/firebase_app_check.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

 // await FirebaseAppCheck.instance.activate(
  //  androidProvider: AndroidProvider.debug,
  //);


  Stripe.publishableKey = const String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: 'pk_live_51RhI8YBNqt2g5DVTojqUxrpiqfFUpErPcwtZrbZYdiVd5N1s04QeE66vxShtCtAZsqFRhue6zrCFZjik6llUGGhY00k7ZEc71G',
  );

  await Stripe.instance.applySettings();

  try {
    await PushNotificationService.initialize();
  } catch (_) {}

  try {
    await FcmTokenService.saveToken();
  } catch (_) {}

  runApp(const Any1SpaceApp());
}

