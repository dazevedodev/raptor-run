import 'package:flutter/material.dart';

enum GroundObstacleKind { cactus, rock }

enum FlyerKind { cuteBird, pterodactyl }

/// Tudo que muda visualmente o cenário conforme a distância percorrida na
/// corrida atual (dia ensolarado, depois a cidade de noite, depois a era
/// da extinção com vulcões e destruição).
class WorldStyle {
  const WorldStyle({
    required this.skyTop,
    required this.skyBottom,
    required this.groundColor,
    required this.groundObstacleKind,
    required this.groundObstacleColors,
    required this.flyerKind,
    required this.showVolcanoes,
    required this.showClouds,
    required this.showSkyline,
    required this.isNight,
    required this.showDestruction,
  });

  final Color skyTop;
  final Color skyBottom;
  final Color groundColor;
  final GroundObstacleKind groundObstacleKind;
  final List<Color> groundObstacleColors;
  final FlyerKind flyerKind;
  final bool showVolcanoes;
  final bool showClouds;
  final bool showSkyline;
  final bool isNight;
  final bool showDestruction;
}

/// Pontuação em que a fase muda: dia até `nightScore`, depois vira noite na
/// cidade até `extinctionScore`, e a partir daí vira a era da extinção — e
/// fica assim pro resto da corrida.
const int nightScore = 1500;
const int extinctionScore = 3000;

const _cactusColors = [
  Color(0xFFEF476F),
  Color(0xFF06D6A0),
  Color(0xFFFFD166),
  Color(0xFF118AB2),
  Color(0xFF8338EC),
];

const _rockColors = [
  Color(0xFF8D8D8D),
  Color(0xFF7A6A5D),
  Color(0xFF6B6B6B),
  Color(0xFF9C8570),
];

const _sunnyDay = WorldStyle(
  skyTop: Color(0xFF6C8CFF),
  skyBottom: Color(0xFFB9C6FF),
  groundColor: Color(0xFF4FAE7C),
  groundObstacleKind: GroundObstacleKind.cactus,
  groundObstacleColors: _cactusColors,
  flyerKind: FlyerKind.cuteBird,
  showVolcanoes: false,
  showClouds: true,
  showSkyline: true,
  isNight: false,
  showDestruction: false,
);

const _night = WorldStyle(
  skyTop: Color(0xFF0B1220),
  skyBottom: Color(0xFF223159),
  groundColor: Color(0xFF2E5138),
  groundObstacleKind: GroundObstacleKind.cactus,
  groundObstacleColors: _cactusColors,
  flyerKind: FlyerKind.cuteBird,
  showVolcanoes: false,
  showClouds: false,
  showSkyline: true,
  isNight: true,
  showDestruction: false,
);

const _extinction = WorldStyle(
  skyTop: Color(0xFF3A1712),
  skyBottom: Color(0xFF8A3A1F),
  groundColor: Color(0xFF5C3A2A),
  groundObstacleKind: GroundObstacleKind.rock,
  groundObstacleColors: _rockColors,
  flyerKind: FlyerKind.pterodactyl,
  showVolcanoes: true,
  showClouds: false,
  showSkyline: false,
  isNight: false,
  showDestruction: true,
);

WorldStyle resolveWorldStyle({required int score}) {
  if (score > extinctionScore) return _extinction;
  if (score > nightScore) return _night;
  return _sunnyDay;
}
