import 'package:collectgame/battle/battle.dart';
import 'package:collectgame/battle/battle_ai.dart';
import 'package:collectgame/battle/battle_action.dart';
import 'package:collectgame/battle/battle_player.dart';
import 'package:collectgame/battle/battle_state.dart';
import 'package:collectgame/battle/battler.dart';
import 'package:collectgame/data/ability/ability.dart';
import 'package:collectgame/data/move/move.dart';
import 'package:collectgame/data/move/move_effect.dart';
import 'package:collectgame/data/species/species.dart';
import 'package:flutter/cupertino.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Ability.initialize();
  MoveEffect.initialize();
  await Move.readMoves();
  await Species.readSpecies();
  final myBulba = Individual(Species.species['bulbasaur'], exp: 500);
  final yourBulba = Individual(Species.species['bulbasaur'], exp: 500);
  myBulba.movePP[0] = 0; // Enough to use scratch but low enough to end up using Struggle
  myBulba.movePP[1] = 3; // Enough to use protect but low enough to end up using Struggle
  myBulba.defaultMoves();
  final battleState = BattleState();
  final ai = RandomBattleAi();
  final playerOne = BattlePlayer()
    ..isPlayer = true;
  final playerTwo = BattlePlayer()..ai = ai;
  final battle = Battle(battleState)..players.addAll([playerOne, playerTwo]);

  playerOne
    ..party.add(myBulba)
    ..sendOut(battle.state, 0);
  playerTwo
    ..party.add(yourBulba)
    ..sendOut(battle.state, 0);

  while (myBulba.hp > 0 && yourBulba.hp > 0) {
    print("You're at ${myBulba.hp}, they're at ${yourBulba.hp}");
    battle.registerAction(playerOne, playerOne.activeBattlers[0]!, BattleAction(BattleActionType.move, BattleActionAttackParam(myBulba.currentMoves[1]!, MoveTarget.fromInt(0))));
    battle.doTurn();
  }
  print("You're at ${myBulba.hp}, they're at ${yourBulba.hp}");
}
