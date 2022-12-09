import 'package:flutter/material.dart';

import '../../battle/battle.dart';
import '../../data/item/item.dart';
import '../../data/move/move.dart';
import '../../data/species/stat.dart';
import 'battle_bag_screen.dart';
import 'move_selector.dart';
import 'party_selector.dart';

class BattlerView extends StatelessWidget {
  BattlerView(this.battle, {this.playerSide = true, super.key});

  final Battle battle;
  final bool playerSide;

  @override
  Widget build(BuildContext context) {
    final side = playerSide ? battle.state.playerSide : battle.state.enemySide;
    final size = battle.state.maxPerSide;
    return Expanded(
        flex: 1,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (int i = 0; i < size; i++)
              (battler) {
                if (battler == null) {
                  return const Text('-');
                } else {
                  return Text(
                      '${battler!.individual}(${battler!.individual.hp}/${battler!.calcStat(Stat.hp)})');
                }
              }(side[i])
          ],
        ));
  }
}

class BattleLogView extends StatelessWidget {
  const BattleLogView(this.messages, {super.key});

  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    return Expanded(
        flex: 1,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              color: Colors.red,
            ),
            SingleChildScrollView(
              reverse: true,
              child: Column(
                children: messages.map((msg) => Text(msg)).toList(),
              ),
            ),
          ],
        ));
  }
}

class BattleMenu extends StatelessWidget {
  BattleMenu(this.battler, this.battle, this.player,
      {required this.onMoveChosen,
      required this.onSwap,
      required this.onItemChosen,
      this.onCancel,
      super.key});

  final Battler battler;
  final Battle battle;
  final BattlePlayer player;
  final Future<void> Function(Move, MoveTarget) onMoveChosen;
  final Future<void> Function(int) onSwap;
  final Future<void> Function(Item) onItemChosen;
  final Future<void> Function()? onCancel;

  @override
  Widget build(BuildContext context) {
    // TODO make all these buttons do something
    return Expanded(
      flex: 1,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('$battler'),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton(
                child: const Text('Attack'),
                onPressed: () async {
                  final moveChoice = await showDialog<Move?>(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => MoveSelector(() {}, battler),
                  );
                  if (moveChoice != null) {
                    final targetType = moveChoice.targetType;
                    final candidates = targetType.allPossibleTargets(
                        battle.state.maxPerSide, battler.indexOnSide);
                    if (candidates.length == 1) {
                      print('$moveChoice can only target ${candidates.first}');
                      await onMoveChosen(moveChoice, candidates.first);
                    } else {
                      final target = await showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) =>
                            TargetSelector(battle, candidates),
                      );
                      if (target != null) {
                        print('Chosen $target for $moveChoice');
                        await onMoveChosen(moveChoice, target);
                      }
                    }
                  }
                },
              ),
              TextButton(
                child: const Text('Bag'),
                onPressed: () async {
                  final itemChoice = await showDialog<Item?>(
                    context: context,
                    builder: (context) => BattleBagScreen(player.bag),
                  );
                  if (itemChoice != null) {
                    await onItemChosen(itemChoice);
                  }
                },
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton(
                child: const Text('Party'),
                onPressed: () async {
                  final index = await showDialog(
                    context: context,
                    builder: (context) => PartySelector(
                      player,
                      true,
                      true,
                    ),
                    barrierDismissible: false,
                  );
                  print('Chose party member at number $index');
                  if (index != null) {
                    await onSwap(index);
                  }
                },
              ),
              TextButton(
                child: const Text('Run'),
                onPressed: () {},
              ),
            ],
          ),
          if (onCancel != null)
            TextButton(
              onPressed: onCancel!,
              child: const Text('Cancel')
            ),
        ],
      ),
    );
  }
}

class BattleScreen extends StatefulWidget {
  BattleScreen(this.battle, this.player, {super.key}) {
    battle.state.log = (msg) => messages.add(msg);
  }

  final Battle battle;
  final BattlePlayer player;
  final messages = <String>[];

  int activeIndex = 0;
  int actionsToCancel = 0;

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  @override
  void initState() {
    super.initState();
    widget.player.selector = (x) async => await _playerSelector(x) ?? -1;
  }

  @override
  Widget build(BuildContext context) {
    print(widget.player.activeBattlers);
    final battler = widget.player.activeBattlers[widget.activeIndex]!;
    return Column(
      children: [
        if(widget.battle.battleStillActive())
        BattlerView(widget.battle, playerSide: false),
        if(widget.battle.battleStillActive())
        BattlerView(widget.battle, playerSide: true),
        BattleLogView(widget.messages),
        if(widget.battle.battleStillActive())
        BattleMenu(
          battler,
          widget.battle,
          widget.player,
          onMoveChosen: (move, target) => _onMoveChosen(move, battler, target),
          onSwap: (index) => _onSwap(battler, index),
          onItemChosen: (item) => _onItemChosen(battler, item),
          onCancel: widget.actionsToCancel > 0 ? _onCancel : null,
        ),
      ],
    );
  }

  Future<void> _onMoveChosen(Move move, Battler battler, MoveTarget target) async {
    final action = BattleAction(
        BattleActionType.move, BattleActionAttackParam(move, target));
    widget.battle.registerAction(widget.player, battler, action, false);
    await _ontoNext();
  }

  Future<void> _onSwap(Battler battler, int index) async {
    final action = BattleAction(BattleActionType.swap, index);
    widget.battle.registerAction(widget.player, battler, action, false);
    await _ontoNext();
  }

  Future<void> _onItemChosen(Battler battler, Item item) async {
    print('$battler will use a ${item.name}');
    if (item.onBattleUse != null &&
        await item.battlePredicate?.call(widget.battle.state, battler, item.param) !=
            false) {
      final param = BattleActionItemParam(item);
      final action = BattleAction(BattleActionType.item, param);
      widget.battle.registerAction(widget.player, battler, action, false);
    } else if (item.onBattlerUse != null) {
      // TODO select a target with another screen showing the party
      final targetIndex = await showDialog(context: context, builder: (context) => PartySelector(widget.player, true, false));
      if (targetIndex != null && targetIndex < widget.player.party.length) {
        final target = widget.player.party[targetIndex];
        if (await item.battlerPredicate
            ?.call(widget.battle.state, target, widget.player, item.param) !=
            false) {
          final param = BattleActionItemParam(item, target);
          final action = BattleAction(BattleActionType.item, param);
          widget.battle.registerAction(widget.player, battler, action, false);
        }
      }
    }
    if (battler.queuedAction != null) {
      await _ontoNext();
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
            title: Text('${item.name} will have no effect'),
            actions: [
              TextButton(
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop())
            ]),
      );
    }
  }

  Future<void> _ontoNext() async {
    final turnComplete = widget.battle.readyForTurn();
    if (turnComplete) {
      await widget.battle.doTurn();
      widget.activeIndex = 0;
      widget.battle.state.log('-------------------');
      widget.battle.state.log('');
      widget.actionsToCancel = 0;
    } else {
      widget.activeIndex++;
      widget.actionsToCancel++;
    }
    while (widget.player.activeBattlers[widget.activeIndex] == null &&
        widget.player.activeBattlers.isNotEmpty) {
      widget.activeIndex++;
      if (widget.activeIndex >= widget.battle.state.maxPerSide) {
        widget.activeIndex = 0;
      }
    }
    setState(() {});
  }

  Future<void> _onCancel() async {
    do {
      widget.player.activeBattlers[widget.activeIndex]!.queuedAction = null;
      widget.activeIndex--;
      if (widget.activeIndex < 0) {
        widget.activeIndex = widget.battle.state.maxPerSide - 1;
      }
    } while (widget.player.activeBattlers[widget.activeIndex] == null);
    widget.actionsToCancel--;
    widget.player.activeBattlers[widget.activeIndex]!.queuedAction = null;
    setState(() {});
  }

  Future<int?> _playerSelector(BattlePlayer player) async {
    final canSend = player.party.any((member) =>
    member.hp > 0 &&
        (!player.activeBattlers.values
            .any((battler) => battler.individual == member)));
    if (!canSend) {
      return null;
    }
    return await showDialog<int>(
      context: context,
      builder: (context) => PartySelector(widget.player, false, true),
    );
  }
}
