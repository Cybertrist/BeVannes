import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Le format des photos : 3:4 en portrait, comme BeReal. L'appareil photo
/// rend ce qu'il veut (4:3, 16:9, carré) ; on recadre au centre pour que
/// tout le monde voie le même cadre, du mur du jour à l'historique.
const formatPhoto = 3 / 4;

// 900 × 1200 : net sur un téléphone, et assez léger pour tenir dans un
// document Firestore (moins de 1 Mo, en pratique 100 à 250 Ko).
const _largeur = 900;
const _hauteur = 1200;
const _poidsMax = 700 * 1024;

/// Recadre la photo en 3:4 et la réduit à 900 × 1200. Renvoie le chemin
/// du nouveau fichier JPEG.
Future<String> recadrerPhoto(String chemin) async {
  final octets = await File(chemin).readAsBytes();
  final sortie = await compute(_recadrer, octets);
  final dossier = await getTemporaryDirectory();
  final fichier = File('${dossier.path}/bevannes_${DateTime.now().millisecondsSinceEpoch}.jpg');
  await fichier.writeAsBytes(sortie);
  return fichier.path;
}

/// Hors du fil principal : décoder et encoder un JPEG prend une seconde.
Uint8List _recadrer(Uint8List octets) {
  // bakeOrientation : un portrait pris téléphone vertical arrive souvent
  // couché, avec l'orientation dans l'EXIF.
  final source = img.bakeOrientation(img.decodeImage(octets)!);
  final ratio = source.width / source.height;
  final int l, h;
  if (ratio > formatPhoto) {
    h = source.height;
    l = (h * formatPhoto).round();
  } else {
    l = source.width;
    h = (l / formatPhoto).round();
  }
  final cadre = img.copyCrop(source, x: (source.width - l) ~/ 2, y: (source.height - h) ~/ 2, width: l, height: h);
  final reduite = l > _largeur ? img.copyResize(cadre, width: _largeur, height: _hauteur) : cadre;
  // La qualité baisse tant que la photo pèse trop, ce qui n'arrive qu'avec
  // des scènes très détaillées.
  for (var q = 80; q > 40; q -= 10) {
    final jpeg = img.encodeJpg(reduite, quality: q);
    if (jpeg.length <= _poidsMax) return jpeg;
  }
  return img.encodeJpg(reduite, quality: 40);
}
