import 'package:collectgame/data/ability/ability.dart';
import 'package:collectgame/data/move/move.dart';
import 'package:collectgame/data/move/move_effect.dart';
import 'package:collectgame/data/species/species.dart';
import 'package:flutter/cupertino.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MoveEffect.initialize();
  Ability.initialize();
  print('effects: ${MoveEffect.effects.toMap()}');
  Move.readMoves();
  Species.readSpecies();
}