import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'config/env.dart';
import 'data/demo_depot.dart';
import 'data/depot.dart';
import 'data/firebase_depot.dart';
import 'data/lieux.dart';
import 'providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Noms des jours et des mois en français.
  await initializeDateFormatting('fr_FR');
  // Barres système transparentes : le fond va jusqu'aux bords.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final lieux = await chargerLieux();
  final Depot depot;
  final config = configFirebase;
  if (modeDemo || config == null) {
    depot = DemoDepot(lieux);
  } else {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: config.apiKey,
        appId: config.appId,
        messagingSenderId: config.senderId,
        projectId: config.projectId,
        storageBucket: config.storageBucket,
      ),
    );
    depot = FirebaseDepot();
  }

  runApp(
    ProviderScope(
      overrides: [depotProvider.overrideWithValue(depot), lieuxProvider.overrideWithValue(lieux)],
      child: const BeVannesApp(),
    ),
  );
}
