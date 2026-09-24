/// L'application : thème, langue et routes.
///
/// Le routeur écoute la session. Tant qu'elle se charge, on reste sur
/// l'écran d'ouverture ; ensuite, un visiteur va vers la connexion et un
/// joueur connecté vers le jeu.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'config/theme.dart';
import 'domain/modeles.dart';
import 'providers.dart';
import 'ui/screens/connexion.dart';
import 'ui/screens/coquille.dart';
import 'ui/screens/ouverture.dart';
import 'ui/screens/photo.dart';

final routeurProvider = Provider<GoRouter>((ref) {
  // Un compteur que le routeur écoute : chaque changement de session le
  // fait réévaluer ses redirections.
  final rafraichir = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (_, _) => rafraichir.value++);
  ref.listen(ouvertureFinieProvider, (_, _) => rafraichir.value++);
  ref.onDispose(rafraichir.dispose);

  return GoRouter(
    initialLocation: '/ouverture',
    refreshListenable: rafraichir,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final ici = state.matchedLocation;
      if (session.isLoading || !ref.read(ouvertureFinieProvider)) return ici == '/ouverture' ? null : '/ouverture';

      final connecte = session.value != null;
      final surAccueil = ici == '/connexion' || ici == '/inscription' || ici == '/oubli';
      if (!connecte) return surAccueil ? null : '/connexion';
      if (surAccueil || ici == '/ouverture') return '/jeu';
      return null;
    },
    routes: [
      GoRoute(
        path: '/ouverture',
        pageBuilder: (_, _) => const NoTransitionPage(child: EcranOuverture()),
      ),
      GoRoute(path: '/connexion', pageBuilder: (_, s) => _fondu(s, const EcranConnexion())),
      GoRoute(path: '/inscription', pageBuilder: (_, s) => _fondu(s, const EcranInscription())),
      GoRoute(path: '/oubli', pageBuilder: (_, s) => _fondu(s, const EcranOubli())),
      GoRoute(path: '/jeu', pageBuilder: (_, s) => _fondu(s, const Coquille())),
      GoRoute(
        path: '/photo',
        pageBuilder: (_, s) => _fondu(s, EcranPhoto(chemin: s.extra! as String)),
      ),
      GoRoute(
        path: '/bravo',
        pageBuilder: (_, s) => _fondu(s, EcranBravo(validation: s.extra! as Validation)),
      ),
    ],
  );
});

CustomTransitionPage<void> _fondu(GoRouterState state, Widget child) => CustomTransitionPage(
  key: state.pageKey,
  transitionDuration: K.slow,
  child: child,
  transitionsBuilder: (context, animation, _, child) => FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: K.ease),
    child: child,
  ),
);

class BeVannesApp extends ConsumerWidget {
  const BeVannesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'BeVannes',
      debugShowCheckedModeBanner: false,
      theme: construireTheme(),
      routerConfig: ref.watch(routeurProvider),
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
