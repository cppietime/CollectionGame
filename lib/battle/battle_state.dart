import 'dart:collection';
import 'dart:math';

import 'package:collectgame/battle/battle_action.dart';
import 'package:collectgame/battle/effect_side.dart';
import 'package:collectgame/data/move/move_effect.dart';
import 'package:collectgame/data/prng.dart';

import '../data/move/move.dart';
import '../data/species/stat.dart';
import 'battler.dart';
import 'effect.dart';
import 'effect_global.dart';

typedef BattleEvent = void Function(BattleState battleState);

class BattleState {
  final int maxPerSide = 1;
  Map<int, Battler> playerSide = {};
  Map<int, Battler> enemySide = {};
  Queue<BattleEvent> eventQueue = Queue();
  List<BattleEffectSide> playerSideEffects = [];
  List<BattleEffectSide> enemySideEffects = [];
  List<BattleEffectGlobal> fieldEffects = [];

  List<Battler> speedSorted = [];

  bool inflict(Battler target, Battler? source, Effect status) {
    return status.onInflict?.call(this, target, source) ?? false;
  }

  Map<int, Battler> sideOf(Battler battler) {
    if (playerSide.values.contains(battler)) {
      return playerSide;
    }
    if (enemySide.values.contains(battler)) {
      return enemySide;
    }
    throw ArgumentError.value(
        battler, "Missing Battler", "Provided battler is not in the battle");
  }

  Map<int, Battler> sideAgainst(Battler battler) {
    if (playerSide.values.contains(battler)) {
      return enemySide;
    }
    if (enemySide.values.contains(battler)) {
      return playerSide;
    }
    throw ArgumentError.value(
        battler, "Missing Battler", "Provided battler is not in the battle");
  }

  void doTurn() {
    _sortBySpeed();
    for (final attacker in speedSorted) {
      _doMove(attacker);
    }
  }

  void sendOut(Battler battler) {
    final side = battler.isPlayers ? playerSide : enemySide;
    for (int i = 0; i < maxPerSide; i++) {
      if (!side.containsKey(i)) {
        side[i] = battler;
        battler.indexOnSide = 1;
        return;
      }
    }
    throw StateError('Side is already full');
  }

  void swapIn(Battler battler, int index) {
    final side = battler.isPlayers ? playerSide : enemySide;
    side[index] = battler;
    battler.indexOnSide = index;
  }

  int _priorityFor(Battler attacker) {
    if (attacker.queuedAction == null) {
      return 0;
    }
    if (attacker.queuedAction!.type == BattleActionType.move) {
      final param = attacker.queuedAction!.param as BattleActionAttackParam;
      final move = param.move;
      final targets = _decodeTargets(attacker, param.target, move.targetType);

      // Pursuit check
      if (move.effects.any((effect) => effect.effect == MoveEffect.pursuit)) {
        if (targets.any(
            (target) => target.queuedAction?.type == BattleActionType.swap)) {
          return 8;
        }
      }

      int priority = move.priority;
      // TODO item check
      // Ability check
      for (final target in targets) {
        priority = attacker.effectiveAbility.priorityModifier
                ?.call(this, attacker, target, move, priority) ??
            priority;
      }
      return priority;
    }
    return attacker.queuedAction!.priority();
  }

  void _sortBySpeed() {
    final trickRoom =
        fieldEffects.any((effect) => effect.effect == EffectGlobal.trickRoom)
            ? -1
            : 1;
    speedSorted
      ..clear()
      ..addAll(playerSide.values)
      ..addAll(enemySide.values)
      ..sort((a, b) {
        final priority = _priorityFor(a) - _priorityFor(b);
        if (priority != 0) {
          return priority;
        }
        return ((a.effectiveSpeed(this) - b.effectiveSpeed(this))) * trickRoom;
      });
  }

  void _doMoveFail(Battler attacker) {
    attacker.lastMoveUsed = null;
    attacker.timesLastMoveUsed = 0;
    inflict(attacker, null, Effect.lastMoveFailed);
  }

  void _doMoveMiss(Battler attacker, Battler target, Move move) {
    for (final effect in move.effects) {
      effect.effect.onMiss?.call(this, attacker, target, effect.param);
    }
  }

  void _doMoveIneffectiveOn(Battler attacker, Battler target) {
    // TODO just say the "doesn't effect" message
  }

  Iterable<Battler> _decodeTargets(
      Battler attacker, MoveTarget target, TargetType targetType) {
    final attackerSide = attacker.isPlayers ? playerSide : enemySide;
    final otherSide = attacker.isPlayers ? enemySide : playerSide;
    switch (targetType) {
      case TargetType.all:
        return playerSide.values.toList() + enemySide.values.toList();
      case TargetType.self:
      case TargetType.allySide:
      case TargetType.enemySide:
        return [attacker];
      case TargetType.allAllies:
        return attacker.isPlayers ? playerSide.values : enemySide.values;
      case TargetType.allEnemies:
        return attacker.isPlayers ? enemySide.values : playerSide.values;
      case TargetType.oneAlly:
      case TargetType.oneEnemy:
      case TargetType.adjacentAllies:
      case TargetType.adjacentEnemies:
        final side = (target.selfSide ? attackerSide : otherSide);
        return [side[target.sideIndex] ?? side.values.first];
    }
  }

  int _calcInitialDamage(
      Battler attacker, Battler defender, Move move, bool crit) {
    // Damage calculation as per https://bulbapedia.bulbagarden.net/wiki/Damage#Generation_V_onward
    int power = move.power;
    if (power != 0) {
      for (final effect in move.effects) {
        power = effect.effect.powerModifier?.call(this, attacker,
                attacker /* should be unused */, effect.param, power) ??
            power;
      }
      power = attacker.effectiveAbility.damageModifierAttack
              ?.call(this, attacker, defender, move, power) ??
          power;
    }

    int effectiveAttack = attacker.calcStat(
        move.category == MoveCategory.physical ? Stat.atk : Stat.spAtk,
        critical: crit);
    int effectiveDefense = defender.calcStat(
        move.category == MoveCategory.physical ? Stat.def : Stat.spDef,
        critical: crit);
    for (final effect in move.effects) {
      if (effect.effect.successCheck
              ?.call(this, attacker, defender, effect.param) ??
          true) {
        effectiveAttack = effect.effect.attackModifier?.call(
                this, attacker, defender, effect.param, effectiveAttack) ??
            effectiveAttack;
        effectiveDefense = effect.effect.defenseModifier?.call(
                this, attacker, defender, effect.param, effectiveDefense) ??
            effectiveDefense;
      }
    }

    double efficacy = move.type.efficacy(defender.individual.species.type1);
    if (defender.individual.species.type2 != null) {
      efficacy *= move.type.efficacy(defender.individual.species.type2!);
    }

    double stab = (move.type == attacker.individual.species.type1 ||
            move.type == attacker.individual.species.type2)
        ? 1.5
        : 1;

    double roll = PRNG.instance.uniform() * 0.15 + 0.85;

    double damage = (2 * attacker.individual.level) / 5 + 2;
    damage = (damage * power * effectiveAttack / effectiveDefense) / 50 + 2;
    damage *= stab * efficacy * roll;

    if (move.category == MoveCategory.physical &&
        attacker.individual.statusCondition == Effect.burn) {
      damage *= 0.5;
    }

    return damage.toInt();
  }

  void _doDamage(Battler attacker, Battler defender, Move move, int damage) {
    if (damage > 0) {
      inflict(defender, attacker, Effect.tookDamageThisTurn);
    }
    print('$attacker does $damage to $defender!');
    defender.individual.hp -= damage;
    for (final effect in move.effects) {
      effect.effect.onDoDamage
          ?.call(this, attacker, defender, damage, effect.param);
    }
    if (defender.individual.hp <= 0) {
      print('$defender Fainted');
    }
  }

  bool _moveAffectsTarget(Battler attacker, Battler target, Move move) {
    if (target == attacker) {
      return true;
    }
    bool effective =
        !target.effectiveTypes.any((type) => move.type.affects(type));
    effective = attacker.effectiveAbility.affectsModifierAttack
            ?.call(this, attacker, target, move, effective) ??
        effective;
    effective = target.effectiveAbility.affectsModifierDefend
            ?.call(this, attacker, target, move, effective) ??
        effective;
    effective = move.effects.any((effect) =>
            effect.effect.successModifier
                ?.call(this, attacker, target, effect.param, effective) ??
            true) ||
        move.effects.isEmpty;
    return effective;
  }

  bool _performMoveOn(Battler attacker, Battler target, Move move) {
    if (move.accuracy > 0 && attacker != target) {
      // Accuracy == 0 is a never-miss move.
      int accuracy = move.accuracy;
      accuracy = attacker.effectiveAbility.accuracyModifierAttack
              ?.call(this, attacker, target, move, accuracy) ??
          accuracy;
      accuracy = target.effectiveAbility.accuracyModifierDefend
              ?.call(this, attacker, target, move, accuracy) ??
          accuracy;
      for (final effect in move.effects) {
        accuracy = effect.effect.accuracyModifier
                ?.call(this, attacker, target, effect.param, accuracy) ??
            accuracy;
      }
      int stages =
          attacker.calcStat(Stat.accuracy) - target.calcStat(Stat.evasion);
      stages = min(max(-6, stages), 6);
      if (stages > 0) {
        accuracy = (accuracy * (1 + 0.5 * stages)).toInt();
      } else if (stages < 0) {
        accuracy = accuracy ~/ (1 - 0.5 * stages);
      }
      if (PRNG.instance.uniform() * 100 > accuracy) {
        _doMoveMiss(attacker, target, move);
        return false;
      }
    }
    // Crit check
    int critStages = attacker.effectiveAbility.critModifierAttack
            ?.call(this, attacker, target, move, 0) ??
        0;
    critStages = target.effectiveAbility.critModifierDefend
            ?.call(this, attacker, target, move, critStages) ??
        critStages;
    for (final effect in move.effects) {
      if (effect.effect.successCheck
              ?.call(this, attacker, target, effect.param) ??
          true) {
        critStages = effect.effect.critStageModifier
                ?.call(this, attacker, target, effect.param, critStages) ??
            critStages;
      }
    }
    bool critical = false;
    if (0 <= critStages && critStages < 3) {
      final reciprocal = const [24, 8, 2][critStages];
      critical = PRNG.instance.uniform() * reciprocal <= 1;
    } else if (critStages >= 3) {
      critical = true;
    }

    bool hitTarget = move.power > 0;
    int damage = _calcInitialDamage(attacker, target, move, critical);
    damage = target.effectiveAbility.damageModifierDefend
            ?.call(this, attacker, target, move, damage) ??
        damage;
    for (final effect in move.effects) {
      if (effect.chance > 0 && PRNG.instance.uniform() > effect.chance) {
        continue;
      }
      if (effect.effect.successCheck
              ?.call(this, attacker, target, effect.param) ??
          true) {
        hitTarget = true;
        effect.effect.onHit?.call(this, attacker, target, effect.param);
        damage = effect.effect.damageModifier
                ?.call(this, attacker, target, effect.param, damage) ??
            damage;
      }
    }
    if (move.power > 0) {
      _doDamage(attacker, target, move, damage);
    }
    return hitTarget;
  }

  void _doMove(Battler attacker) {
    if (attacker.queuedAction == null ||
        attacker.queuedAction!.type != BattleActionType.move ||
        attacker.individual.hp <= 0) {
      return;
    }
    final attackParam = attacker.queuedAction!.param as BattleActionAttackParam;
    final attackerSide = attacker.isPlayers ? playerSide : enemySide;
    Move move = attackParam.move;
    MoveTarget target = attackParam.target;

    // Check success against each status
    bool success = true;
    for (final effect in attacker.volatileStatus) {
      if (!(effect.effect.successModifier
              ?.call(this, attacker, effect, move, success) ??
          true)) {
        success = false;
        _doMoveFail(attacker);
        return;
      }
    }

    // Get targets
    var initialTargets = _decodeTargets(attacker, target, move.targetType).toList();
    var targets = initialTargets.toList();
    for (final target in initialTargets) {
      targets = target.effectiveAbility.targetModifier
              ?.call(this, attacker, move, targets) ??
          targets;
    }

    // Move success check, prune targets it fails on
    success = move.targetType == TargetType.self;
    initialTargets.clear();
    for (final target in targets) {
      bool effective = _moveAffectsTarget(attacker, target, move);
      if (effective) {
        success = true;
        initialTargets.add(target);
      } else {
        _doMoveIneffectiveOn(attacker, target);
      }
    }
    if (!success) {
      _doMoveFail(attacker);
      return;
    }
    targets = initialTargets;

    // Perform ally ability modification (e.g. Steely Claws)
    for (final ally in attackerSide.values) {
      if (ally != attacker) {
        ally.effectiveAbility.onAllyAttack?.call(this, attacker, move);
      }
    }

    // Perform move on each target
    success = move.targetType == TargetType.self;
    for (final target in targets) {
      bool hitTarget = _performMoveOn(attacker, target, move);
      if (hitTarget) {
        success = true;
      }
    }
    if (!success) {
      _doMoveFail(attacker);
      return;
    }

    // Keep track of the move being used.
    if (attacker.lastMoveUsed == move) {
      attacker.timesLastMoveUsed += 1;
    } else {
      attacker.lastMoveUsed = move;
      attacker.timesLastMoveUsed = 1;
    }
    inflict(attacker, null, Effect.movedThisTurn);
  }
}
