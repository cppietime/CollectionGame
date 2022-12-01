import 'package:collectgame/battle/battle_ai.dart';
import 'package:collectgame/battle/battle_player.dart';
import 'package:collectgame/battle/battle_state.dart';
import 'package:collectgame/battle/battler.dart';
import 'package:collectgame/data/ability/ability.dart';
import 'package:collectgame/data/move/move.dart';
import 'package:collectgame/data/move/move_effect.dart';
import 'package:collectgame/data/species/species.dart';
import 'package:flutter/cupertino.dart';

void main() async {
  print('Enter main');
  WidgetsFlutterBinding.ensureInitialized();
  print('Init whatever');
  Ability.initialize();
  print('Init abilities');
  MoveEffect.initialize();
  print('Init effects');
  await Move.readMoves();
  await Species.readSpecies();
  print(Move.moves.toMap());
  print(Species.species.toMap());
  final myBulba = Battler(Individual(Species.species['bulbasaur'], exp: 500))..isPlayers = true;
  final yourBulba = Battler(Individual(Species.species['bulbasaur'], exp: 500))..isPlayers = false;
  myBulba.individual.movePP[0] = 40;
  myBulba.individual.defaultMoves();
  print(myBulba.individual.currentMoves);
  final battle = BattleState();
  battle.sendOut(myBulba);
  battle.sendOut(yourBulba);
  final ai = RandomBattleAi();
  final player = BattlePlayer();
  print('Initialized');

  while (myBulba.individual.hp > 0 && yourBulba.individual.hp > 0) {
    print("You're at ${myBulba.individual.hp}, they're at ${yourBulba.individual.hp}");
    myBulba.queuedAction = ai.decide(battle, myBulba, player);
    yourBulba.queuedAction = ai.decide(battle, yourBulba, player);
    battle.doTurn();
    //break;
  }
  print("You're at ${myBulba.individual.hp}, they're at ${yourBulba.individual.hp}");
}