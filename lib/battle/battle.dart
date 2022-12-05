import 'dart:ui';

import 'battle_player.dart';
import 'battle_state.dart';
import 'battler.dart';
import 'battle_action.dart';

export 'battle_action.dart';
export 'battle_ai.dart';
export 'battle_player.dart';
export 'battle_state.dart';
export 'battler.dart';

class Battle {
  Battle(this.state);

  final BattleState state;
  List<BattlePlayer> players = [];

  VoidCallback? onBattleEnd;

  bool registerAction(BattlePlayer player, Battler battler, BattleAction action,
      [bool attemptTurn = false]) {
    assert(players.contains(player),
    'Player $player is not in battle players list.');
    battler.queuedAction = action;
    bool ready = readyForTurn();
    if (attemptTurn && ready) {
      doTurn();
    }
    return ready;
  }

  bool readyForTurn() {
    return !players.any((player) {
      return !player.readyToAct();
    });
  }

  bool battleStillActive() {
    return !players.any((player) => !player.canStillBattle());
  }

  Future<void> doTurn() async {
    for (final player in players) {
      player.runAi(state);
    }
    state.doTurn();
    for (final player in players) {
      //player.activeBattlers.removeWhere((battler) => battler.individual.hp <= 0);
      await player.replaceFainted(state);
    }
    if (!battleStillActive()) {
      // TODO what to do when the battle ends
      print('The battle is over. You may try to do other stuff in debugging but really it is already over now');
      onBattleEnd?.call();
    }
  }
}
