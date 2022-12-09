import 'dart:math';

import 'package:collectgame/battle/battle_state.dart';
import 'package:collectgame/battle/battler.dart';
import 'package:collectgame/battle/effect.dart';
import 'package:collectgame/data/move/move.dart';
import 'package:collectgame/data/prng.dart';
import 'package:collectgame/data/registry.dart';

import '../species/stat.dart';

typedef MoveEffectModifier<T> = T Function(
    BattleState battleState, Battler user, Battler target, int extra, T param);
typedef SuccessCheck = bool Function(
    BattleState battleState, Battler user, Battler target, int extra);
typedef MoveHitTrigger = void Function(
    BattleState battleState, Battler user, Battler target, int extra);
typedef MoveUseTrigger = void Function(
    BattleState battleState, Battler user, Move move);
typedef MoveDamageTrigger = void Function(BattleState battleState, Battler user,
    Battler target, int damage, int extra);
typedef TargetModifier = List<Battler> Function(
    BattleState battleState, Battler user, Move move, List<Battler> targets);

class MoveEffect {
  static Registry<MoveEffect> effects = Registry();

  MoveEffect(
    this.name, {
    this.accuracyModifier,
    this.powerModifier,
    this.damageModifier,
    this.successModifier,
    this.critStageModifier,
    this.attackModifier,
    this.defenseModifier,
    this.successCheck,
    this.onHit,
    this.onMiss,
    this.onDoDamage,
  }) {
    index = effects.put(name, this);
  }

  final String name;

  late final int index;

  final MoveEffectModifier<int>? accuracyModifier;

  final MoveEffectModifier<int>? powerModifier;

  final MoveEffectModifier<int>? damageModifier;

  final MoveEffectModifier<bool>? successModifier;

  final MoveEffectModifier<int>? critStageModifier;

  final MoveEffectModifier<int>? attackModifier;

  final MoveEffectModifier<int>? defenseModifier;

  final MoveDamageTrigger? onDoDamage;

  final SuccessCheck? successCheck;

  final MoveHitTrigger? onHit;

  final MoveHitTrigger? onMiss;

  // TODO define and implement move effects
  static late final MoveEffect protect;

  static late final MoveEffect mirrorMove;

  static late final MoveEffect snatch;

  static late final MoveEffect recoilFraction; // Param = % recoil
  static late final MoveEffect changeStats; // Param = encoded stat change
  static late final MoveEffect inflictTarget; // Param = id of status condition
  static late final MoveEffect inflictSelf; // Param = id of status condition
  static late final MoveEffect affectsEverything;

  static late final MoveEffect pursuit;

  static late final MoveEffect flinch;

  static late final MoveEffect critRatio;
  static late final MoveEffect oneHp;

  static void initialize() {
    protect = MoveEffect("protect",
        successModifier: (state, attacker, target, extra, success) {
      if (!success) {
        return false;
      }
      if (attacker.timesLastMoveUsed > 0 && attacker.lastMoveUsed != null) {
        bool didProtect = attacker.lastMoveUsed!.effects
            .any((effect) => effect.effect == protect);
        if (didProtect) {
          double prob = pow(0.5, attacker.timesLastMoveUsed) as double;
          return PRNG.instance.uniform() <= prob;
        }
      }
      return true;
    }, onHit: (state, attacker, target, extra) {
      state.inflict(target, attacker, Effect.protect);
    });
    mirrorMove = MoveEffect("mirror_move");
    snatch = MoveEffect("snatch");
    recoilFraction = MoveEffect(
      "recoil_fraction",
      onDoDamage: (state, user, target, damage, extra) {
        final recoil = max(1, damage * extra ~/ 100);
        user.individual.hp -= recoil;
        state.log('$user took $recoil in recoil damage!');
      },
    ); // Param = % recoil
    changeStats =
        MoveEffect("change_stats", onHit: (state, user, target, extra) {
      final statChange = StatChange.decode(extra);
      state.changeStats(target, user, statChange);
    }); // Param = encoded stat change
    inflictTarget = MoveEffect("inflict_target",
        onHit: (state, user, target, extra) {
          final effect = Effect.values[extra];
          state.inflict(target, target, effect);
        },
        successCheck: (state, user, target, extra) =>
            Effect.values[extra].canAffect?.call(state, target, user, null) ??
            true,
        successModifier: (state, user, target, extra, success) =>
            success &&
            (Effect.values[extra].canAffect?.call(state, target, user, null) ??
                true)); // Param = id of status condition
    inflictSelf = MoveEffect("inflict_self"); // Param = id of status condition
    affectsEverything = MoveEffect(
      "affects_everything",
      successModifier: (state, user, target, damage, extra) => true,
    );
    pursuit = MoveEffect("pursuit");
    flinch = MoveEffect("flinch", onHit: (state, user, target, extra) {
      state.inflict(target, user, Effect.flinched);
    });
    critRatio = MoveEffect("crit_ratio",
        critStageModifier: (state, user, target, extra, stage) =>
            stage + extra);
    oneHp = MoveEffect("one_hp",
        damageModifier: (state, user, target, extra, damage) =>
            min(damage, target.individual.hp - 1));
  }
}
