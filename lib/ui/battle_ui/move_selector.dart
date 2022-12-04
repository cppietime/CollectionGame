import 'package:flutter/material.dart';
import '../../battle/battle.dart';
import '../../data/move/move.dart';

class MoveSelector extends StatelessWidget {
  MoveSelector(this.notify, this.battler, {super.key});

  final void Function() notify;
  final Battler battler;

  @override
  Widget build(BuildContext context) {
    final doStruggle = !battler.availableMoves.any((move) {
      if (move == null) {
        return false;
      }
      return battler.individual.ppOf(move) > 0;
    });
    return AlertDialog(
      title: Text('Choose a move for $battler'),
      content: Container(
        width: double.maxFinite,
        child: ListView(
          scrollDirection: Axis.vertical,
          children: [
            for (final move in battler.availableMoves)
              if (move != null)
                ListTile(
                  title: Text(
                    '${move.name} - ${battler.individual.ppOf(move)}/${move.pp}'),
                  onTap: () {
                    if (battler.individual.ppOf(move) > 0 || doStruggle) {
                      Navigator.of(context).pop(doStruggle ? Move.struggle : move);
                    }
                  },
                ),
            ListTile(
              title: const Text('Cancel'),
              onTap: () {
                Navigator.of(context).pop(null);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class TargetSelector extends StatelessWidget {
  TargetSelector(this.battle, this.candidates, {super.key});
  final Battle battle;
  final Iterable<MoveTarget> candidates;

  @override
  Widget build(BuildContext context) {
    final validEnemies = candidates.where((target) => !target.selfSide).map((target) => target.sideIndex).toSet();
    final validAllies = candidates.where((target) => target.selfSide).map((target) => target.sideIndex).toSet();
    return AlertDialog(
      title: const Text('Choose a target'),
      content: Container(
        width: double.maxFinite,
        child: Column(
          children: [
            Row(
              children: [
                for (int i = 0; i < battle.state.maxPerSide; i++)
                  TextButton(onPressed: (){
                    if (validEnemies.contains(i)) {
                      Navigator.of(context).pop(MoveTarget(false, i));
                    }
                  },
                  child: Text('${battle.state.enemySide[i] ?? '-'}')),
              ],
            ),
            Row(
                children: [
                  for (int i = 0; i < battle.state.maxPerSide; i++)
                    TextButton(onPressed: (){
                    if (validAllies.contains(i)) {
                      Navigator.of(context).pop(MoveTarget(true, i));
                    }
                  },
                  child: Text('${battle.state.playerSide[i] ?? '-'}')),
                ],
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
