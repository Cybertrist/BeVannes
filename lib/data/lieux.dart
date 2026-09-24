import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/lieu.dart';

/// Les lieux du jeu, embarqués dans l'application (assets/lieux.json).
///
/// L'ordre du fichier compte : le tirage du jour en dépend. Ajouter un lieu
/// à la fin rebat les cartes du cycle en cours, c'est sans conséquence ;
/// en retirer un aussi. Mais tous les joueurs doivent avoir la même version
/// pour voir le même lieu.
Future<List<Lieu>> chargerLieux() async {
  final texte = await rootBundle.loadString('assets/lieux.json');
  final json = jsonDecode(texte) as Map<String, dynamic>;
  return [for (final l in json['lieux'] as List) Lieu.depuisJson(l as Map<String, dynamic>)];
}
