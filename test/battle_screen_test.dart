import 'package:collectgame/battle/battle.dart';
import 'package:collectgame/data/ability/ability.dart';
import 'package:collectgame/data/move/move.dart';
import 'package:collectgame/data/move/move_effect.dart';
import 'package:collectgame/data/species/species.dart';
import 'package:collectgame/data/item/item.dart';
import 'package:collectgame/ui/battle_ui/battle_screen.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Ability.initialize();
  MoveEffect.initialize();
  await Move.readMoves();
  await Species.readSpecies();
  await Item.readItems();
  final myBulba = Individual(Species.species['bulbasaur'], exp: 500)..nickname = "Sore";
  final myBulba2 = Individual(Species.species['bulbasaur'], exp: 500)..nickname = "Ballbasaur";
  final myBulba3 = Individual(Species.species['bulbasaur'], exp: 500)..nickname = "Bass";
  final yourBulba = Individual(Species.species['bulbasaur'], exp: 500);
  final yourBulba2 = Individual(Species.species['bulbasaur'], exp: 500)..nickname = "Bulbutt";
  myBulba.movePP.fillRange(0, 4, 10);
  myBulba.defaultMoves();
  myBulba2.defaultMoves();
  myBulba3.defaultMoves();
  final battleState = BattleState(maxPerSide: 2);
  final ai = RandomBattleAi();
  final playerOne = BattlePlayer()
    ..isPlayer = true;
  final playerTwo = BattlePlayer()..ai = ai;
  final battle = Battle(battleState)..players.addAll([playerOne, playerTwo]);

  playerOne
    ..party.add(myBulba)
    ..party.add(myBulba2)
    ..party.add(myBulba3)
    ..replaceFainted(battle.state)
    ..bag.give(Item.items['potion'], 2);
  playerTwo
    ..party.add(yourBulba)
    ..party.add(yourBulba2)
    ..replaceFainted(battle.state);

  runApp(MainApp(() => BattleScreen(battle, playerOne)));
}

class MainApp extends StatelessWidget {
  final BattleScreen Function() builder;
  MainApp(this.builder, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: builder(),
      ),
    );
  }
}