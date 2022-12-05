// Represents a participant. Contains inventory, team, etc..
import 'package:collection/collection.dart';

import '../data/item/bag.dart';

import 'battler.dart';
import 'battle_ai.dart';
import 'battle_state.dart';

class BattlePlayer {
  BattleAi? ai;

  final Map<int, Battler> activeBattlers = {};
  final List<Individual> party = [];
  final Bag bag = Bag();
  bool isPlayer = false;
  Future<int> Function(BattlePlayer)? selector;

  bool readyToAct() =>
      ai != null ||
      !activeBattlers.values.any((battler) => battler.queuedAction == null);

  void runAi(BattleState state) {
    if (ai == null) {
      return;
    }
    for (final battler in activeBattlers.values) {
      battler.queuedAction = ai!.decide(state, battler, this);
    }
  }

  void sendOut(BattleState state, int partyIndex, {int position = 0}) {
    final newBattler = Battler(party[partyIndex])..isPlayers = isPlayer;
    state.swapIn(newBattler, position);
    activeBattlers[position] = newBattler;
    newBattler.commander = this;
  }

  bool canStillBattle() {
    return party.any((indi) => indi.hp > 0);
  }

  Future<int> selectNextBattler() async {
    if (ai != null || selector == null) {
      // TODO select intelligently
      final active = activeBattlers.values.map((battler) => battler.individual)
          .toSet();
      for (int i = 0; i < party.length; i++) {
        final individual = party[i];
        if (individual.hp > 0 && !active.contains(individual)) {
          return i;
        }
      }
      return -1;
    }
    if (selector != null) {
      return await selector!(this);
    }
    return -1;
  }

  Future<void> replaceFainted(BattleState state) async {
    activeBattlers.removeWhere((pos, battler) => battler.individual.hp <= 0);
    final side = isPlayer ? state.playerSide : state.enemySide;
    for (int i = 0; i < state.maxPerSide; i++) {
      if (side[i] == null) {
        final next = await selectNextBattler();
        if (next != -1) {
          state.log('Go #$next');
          sendOut(state, next, position: i);
        }
      }
    }
  }

  Future<void> populateInitial(BattleState state) async {

  }
}
