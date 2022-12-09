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
  final myBulba = Individual(Species.species['bulbasaur'], exp: 500)
    ..nickname = "Sore";
  final myBulba2 = Individual(Species.species['bulbasaur'], exp: 500)
    ..nickname = "Ballbasaur";
  final myBulba3 = Individual(Species.species['bulbasaur'], exp: 500)
    ..nickname = "Bass";
  final yourBulba = Individual(Species.species['bulbasaur'], exp: 500);
  final yourBulba2 = Individual(Species.species['bulbasaur'], exp: 500)
    ..nickname = "Bulbutt";
  myBulba.movePP.fillRange(0, 4, 10);
  myBulba.defaultMoves();
  myBulba2.defaultMoves();
  myBulba3.defaultMoves();
  final battleState = BattleState(maxPerSide: 2);
  final ai = RandomBattleAi();
  final playerOne = BattlePlayer()..isPlayer = true;
  final playerTwo = BattlePlayer()..ai = ai;
  final battle = Battle(battleState)..players.addAll([playerOne, playerTwo]);

  playerOne
    ..party.add(myBulba)
    ..party.add(myBulba2)
    ..party.add(myBulba3)
    ..bag.give(Item.items['potion'], 2)
    ..bag.give(Item.items['pokeball'], 50);
  playerTwo
    //..party.add(yourBulba)
    ..party.add(yourBulba2)
    ..isWild = true;

  await playerOne.replaceFainted(battle.state);
  await playerTwo.replaceFainted(battle.state);

  runApp(MainApp(battle, playerOne));
}

class MainApp extends StatelessWidget {
  late BattleScreen Function() builder;
  final GlobalKey battleScreenKey = GlobalKey();
  MainApp(Battle battle, BattlePlayer player, {super.key}) {
    builder = () => BattleScreen(battle, player, key: battleScreenKey);
    battle.onBattleEnd = (condition) async {
      final context = battleScreenKey.currentContext!;
      await showDialog(
          context: context,
          builder: (context) => AlertDialog(title: Text('$condition')));
      Navigator.of(context).popAndPushNamed('/end');
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/battle': (context) => Scaffold(body: builder()),
        '/end': (context) => Scaffold(
              appBar: AppBar(title: const Text("It's over!")),
            ),
      },
      initialRoute: '/battle',
    );
  }
}
