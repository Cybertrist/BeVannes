import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/jour.dart';
import '../domain/lieu.dart';

/// Le rappel quotidien, à une heure qui change chaque jour mais reste la
/// même pour tous les joueurs (domain/jour.dart). Tout est local : aucune
/// notification ne passe par un serveur.
class Rappels {
  Rappels();

  final _plugin = FlutterLocalNotificationsPlugin();
  static const _cle = 'rappels_actifs';
  static const _joursAvance = 7;

  bool _pret = false;

  Future<void> _preparer() async {
    if (_pret) return;
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Paris'));
    await _plugin.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings('@drawable/ic_notification')),
    );
    _pret = true;
  }

  Future<bool> actifs() async => (await SharedPreferences.getInstance()).getBool(_cle) ?? true;

  /// Active ou coupe les rappels. Renvoie l'état obtenu : l'activation échoue
  /// si le système refuse les notifications.
  Future<bool> regler(bool actif, List<Lieu> lieux) async {
    final prefs = await SharedPreferences.getInstance();
    if (actif) {
      await _preparer();
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final accorde = await android?.requestNotificationsPermission() ?? true;
      if (!accorde) {
        await prefs.setBool(_cle, false);
        await _plugin.cancelAll();
        return false;
      }
    }
    await prefs.setBool(_cle, actif);
    await planifier(lieux);
    return actif;
  }

  /// Programme les rappels des prochains jours. À relancer à chaque
  /// ouverture : la fenêtre glisse avec le temps.
  Future<void> planifier(List<Lieu> lieux, {int? dejaValide}) async {
    try {
      await _preparer();
      await _plugin.cancelAll();
      if (!await actifs() || lieux.isEmpty) return;
      final maintenant = tz.TZDateTime.now(tz.local);
      final aujourdhui = numeroDuJour(maintenant);
      for (var ecart = 0; ecart < _joursAvance; ecart++) {
        final jour = aujourdhui + ecart;
        if (jour == dejaValide) continue;
        final (:heure, :minute) = heureDuRappel(jour);
        final date = dateDuJour(jour);
        final quand = tz.TZDateTime(tz.local, date.year, date.month, date.day, heure, minute);
        if (quand.isBefore(maintenant)) continue;
        final lieu = lieux[indexDuLieu(jour, lieux.length)];
        await _plugin.zonedSchedule(
          id: jour % 100000,
          title: "C'est l'heure de BeVannes",
          body: 'Le lieu du jour : ${lieu.nom}. Sois-y avant minuit.',
          scheduledDate: quand,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'lieu_du_jour',
              'Lieu du jour',
              channelDescription: 'Le rappel quotidien, à une heure différente chaque jour',
              importance: Importance.high,
              priority: Priority.high,
              color: Color(0xFF39D2C0),
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (e) {
      // Un rappel manqué ne doit jamais empêcher de jouer.
      debugPrint('Rappels : $e');
    }
  }
}
