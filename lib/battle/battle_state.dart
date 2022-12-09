import 'dart:collection';
import 'dart:math';

import 'package:collectgame/battle/battle_action.dart';
import 'package:collectgame/battle/effect_side.dart';
import 'package:collectgame/data/ball/ball.dart';
import 'package:collectgame/data/move/move_effect.dart';
import 'package:collectgame/data/prng.dart';
import 'package:flutter/foundation.dart';

import '../data/move/move.dart';
import '../data/species/stat.dart';
import 'battler.dart';
import 'effect.dart';
import 'effect_global.dart';

typedef BattleEvent = void Function(BattleState battleState);
typedef LogFunction = void Function(String message);

class BattleState {
  BattleState({
    this.maxPerSide = 1,
    this.log = _debugLog,
  });

  final int maxPerSide;
  Map<int, Battler> playerSide = {};
  Map<int, Battler> enemySide = {};
  Queue<BattleEvent> eventQueue = Queue();
  List<BattleEffectSide> playerSideEffects = [];
  List<BattleEffectSide> enemySideEffects = [];
  List<BattleEffectGlobal> fieldEffects = [];

  List<Battler> speedSorted = [];

  LogFunction log;

  Individual? captive;

  bool _battleEnded = false;

  bool inflict(Battler target, Battler? source, Effect status) {
    if (status.onInflict == null) {
      if (status.index < innateStats) {
        target.individual.statusCondition = status;
        return true;
      }
      target.setEffect(BattleEffect(status, 0));
      return true;
    }
    return status.onInflict!(this, target, source);
  }

  StatChange changeStats(Battler target, Battler? source, StatChange change) {
    change = target.effectiveAbility.onStatsChange
            ?.call(this, target, source, change) ??
        change;
    for (final battler in speedSorted) {
      change = battler.effectiveAbility.onGlobalStatChange
              ?.call(this, target, battler, change) ??
          change;
    }
    for (final stat in change.stats) {
      final old = target.statChanges[stat.idx];
      if (change.absolute) {
        target.statChanges[stat.idx] = change.steps;
      } else {
        target.statChanges[stat.idx] += change.steps;
        if (stat == Stat.critRatio) {
          target.statChanges[stat.idx] =
              min(2, max(target.statChanges[stat.idx], 0));
        } else {
          target.statChanges[stat.idx] =
              min(6, max(target.statChanges[stat.idx], -6));
        }
      }
      int diff = target.statChanges[stat.idx] - old;
      if (diff == 0) {
        log("$target's ${stat.fullName} didn't change.");
      } else {
        diff = min(3, max(-3, diff));
        final adverb = ['', 'sharply ', 'drastically '][diff.abs() - 1];
        final verb = diff > 0 ? 'rose' : 'fell';
        log("$target's ${stat.fullName} $adverb$verb!");
      }
    }
    return change;
  }

  Map<int, Battler> sideOf(Battler battler) {
    if (playerSide.values.contains(battler)) {
      return playerSide;
    }
    if (enemySide.values.contains(battler)) {
      return enemySide;
    }
    throw ArgumentError.value(
        '$battler', "Missing Battler", "Provided battler is not in the battle");
  }

  Map<int, Battler> sideAgainst(Battler battler) {
    if (playerSide.values.contains(battler)) {
      return enemySide;
    }
    if (enemySide.values.contains(battler)) {
      return playerSide;
    }
    throw ArgumentError.value(
        '$battler', "Missing Battler", "Provided battler is not in the battle");
  }

  Future<void> doTurn() async {
    _sortBySpeed();
    for (final attacker in speedSorted) {
      final action = attacker.queuedAction!;
      switch (action.type) {
        case BattleActionType.move:
          _doMove(attacker);
          break;
        case BattleActionType.swap:
          _doSwap(attacker);
          break;
        case BattleActionType.item:
          await _doUseItem(attacker);
          break;
        default:
          break;
      }
      attacker.queuedAction = null;
      if (_battleEnded) {
        break;
      }
    }
    if (!_battleEnded) {
      for (final attacker in speedSorted) {
        if (attacker.individual.hp <= 0) {
          continue;
        }
        final nonVolatile = attacker.individual.statusCondition;
        if (nonVolatile != null) {
          nonVolatile.endOfTurn
              ?.call(this, attacker, BattleEffect(nonVolatile, 0));
        }
        if (attacker.individual.hp <= 0) {
          continue;
        }
        Set<Effect> expired = {};
        for (final effect in attacker.volatileStatus) {
          effect.effect.endOfTurn?.call(this, attacker, effect);
          if (effect.effect.persists?.call(this, attacker, effect) == false) {
            expired.add(effect.effect);
          }
          if (attacker.individual.hp <= 0) {
            break;
          }
        }
        for (final effect in expired) {
          attacker.removeEffect(effect);
        }
        _faintCheck();
      }
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
    final old = side[index];
    if (old != null) {
      speedSorted[speedSorted.indexOf(old)] = battler;
    }
    side[index] = battler;
    battler.indexOnSide = index;
  }

  static void _debugLog(String message) {
    if (kDebugMode) {
      print(message);
    }
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
          return -priority; // High priority means go first
        }
        return -((a.effectiveSpeed(this) - b.effectiveSpeed(this))) *
            trickRoom; // High speed goes first, too
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
    eventQueue.add((state) => state.log("It doesn't affect $target..."));
  }

  Iterable<Battler> _decodeTargets(
      Battler attacker, MoveTarget target, TargetType targetType) {
    // TODO make this method make sense
    final attackerSide = attacker.isPlayers ? playerSide : enemySide;
    final otherSide = attacker.isPlayers ? enemySide : playerSide;
    switch (targetType) {
      case TargetType.all:
      case TargetType.allOther:
        return playerSide.values.toList() + enemySide.values.toList();
      case TargetType.self:
      case TargetType.allySide:
      case TargetType.enemySide:
        return [
          attacker
        ]; // When an entire side is the target, target self for simplicity
      case TargetType.allAllies:
      case TargetType.adjacentAllies:
        return attacker.isPlayers ? playerSide.values : enemySide.values;
      case TargetType.allEnemies:
      case TargetType.adjacentEnemies:
      case TargetType.allAdjacent:
        return attacker.isPlayers ? enemySide.values : playerSide.values;
      case TargetType.oneAlly:
      case TargetType.oneEnemy:
      case TargetType.oneAdjacent:
      case TargetType.one:
      case TargetType.adjacentEnemy:
      case TargetType.adjacentAlly:
        final side = (target.selfSide ? attackerSide : otherSide);
        return [
          if (side.isNotEmpty) (side[target.sideIndex] ?? side.values.first)
        ];
    }
  }

  Battler? _decodeSingleTarget(Battler attacker, MoveTarget target) {
    final side =
        (attacker.isPlayers == target.selfSide) ? playerSide : enemySide;
    return side[target.sideIndex];
  }

  double _calcEfficacy(Battler attacker, Battler defender, Move move) {
    double efficacy = defender.effectiveTypes
        .fold(1, (i, type) => i * move.type.efficacy(type));
    return efficacy;
  }

  int _calcInitialDamage(Battler attacker, Battler defender, Move move,
      bool crit, double efficacy) {
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

    double stab = attacker.effectiveTypes.contains(move.type) ? 1.5 : 1;

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
    damage = min(damage, defender.individual.hp);
    if (damage > 0) {
      inflict(defender, attacker, Effect.tookDamageThisTurn);
    }
    log('$attacker does $damage to $defender!');
    defender.individual.hp -= damage;
    for (final effect in move.effects) {
      effect.effect.onDoDamage
          ?.call(this, attacker, defender, damage, effect.param);
    }
  }

  void _remove(Battler battler) {
    if (battler.isPlayers && playerSide.containsKey(battler.indexOnSide)) {
      log('$battler fainted!');
      playerSide.remove(battler.indexOnSide);
    } else if (!battler.isPlayers &&
        enemySide.containsKey(battler.indexOnSide)) {
      log('$battler fainted!');
      enemySide.remove(battler.indexOnSide);
    }
  }

  void _faintCheck() {
    for (final battler in speedSorted) {
      if (battler.individual.hp <= 0) {
        _remove(battler);
      }
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
    if (attacker.individual.hp <= 0) {
      // User already fainted
      return false;
    }
    if (target.individual.hp <= 0) {
      // Target already fainted
      return false;
    }
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
        log("$target evaded $attacker's $move.");
        return false;
      }
    }
    // Check for effect based failure, e.g. Protect
    for (final effect in target.volatileStatus) {
      if (effect.effect.successModifierDefend
              ?.call(this, target, effect, move, true) ==
          false) {
        _doMoveMiss(attacker, target, move);
        return false;
      }
    }
    // Crit check
    int critStages = attacker.statChanges[Stat.critRatio.idx];
    critStages = attacker.effectiveAbility.critModifierAttack
            ?.call(this, attacker, target, move, critStages) ??
        critStages;
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
    double efficacy = _calcEfficacy(attacker, target, move);
    if (move.power > 0) {
      if (critical) {
        log("It's a critical hit on $target!");
      }
      if (efficacy > 1) {
        log("It's supereffective on $target!");
      } else if (efficacy < 1) {
        log("It's not very effective on $target!");
      }
    }
    int damage = _calcInitialDamage(attacker, target, move, critical, efficacy);
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

    // Check if we're out of PP
    if (attacker.individual.ppOf(move) <= 0) {
      move = Move.struggle;
    }

    // Check success against each status
    bool success = true;
    for (final effect in attacker.volatileStatus) {
      if (!(effect.effect.successModifierAttack
              ?.call(this, attacker, effect, move, success) ??
          true)) {
        success = false;
        _doMoveFail(attacker);
        return;
      }
    }

    // Move is effectively used, expend the PP
    attacker.individual.losePP(move, 1);
    log('$attacker used $move!');

    // Get targets
    var initialTargets =
        _decodeTargets(attacker, target, move.targetType).toList();
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
      log('It failed...');
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
      _faintCheck();
      if (hitTarget) {
        success = true;
      }
    }
    if (!success) {
      _doMoveFail(attacker); // Should this really be called?
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

  void _doSwap(Battler attacker) {
    final newIndex = attacker.queuedAction!.param as int;
    log('Withdrew $attacker');
    attacker.commander!.sendOut(this, newIndex, position: attacker.indexOnSide);
    log('Sent out ${attacker.commander!.activeBattlers[attacker.indexOnSide]}');
  }

  Future<void> _doUseItem(Battler attacker) async {
    final param = attacker.queuedAction!.param as BattleActionItemParam;
    final item = param.item;
    final player = attacker.commander!;
    if (player.bag.quantityOf(item) == 0) {
      return;
    }
    print('$attacker is using a ${item.name}');
    final target = param.target;
    bool success = false;
    if (target == null && item.onBattleUse != null) {
      // Use on the user battler
      success = await item.onBattleUse!.call(this, attacker, item.param);
    } else if (target != null && item.onBattlerUse != null) {
      success = await item.onBattlerUse!(this, target, player, item.param);
    }
    if (success) {
      player.bag.take(item, 1);
    } else {
      log('${item.name} had no effect...');
    }
  }

  Future<void> throwBall(Battler user, Battler target, Ball ball) async {
    print('Using $ball on $target');
    log('Throwing a $ball at $target');
    bool success = ball.bypassCheck;
    if (!success) {
      final hp = target.individual.hp;
      final maxHp = target.calcStat(Stat.hp);
      final ballBonus = ball.catchModifier(this, target);
      final catchRate = target.individual.species.catchRate;
      int num = (3 * maxHp - 2 * hp) * 4096 * catchRate * ballBonus ~/ (3 * maxHp);
      double alpha = num.toDouble();
      switch (target.individual.statusCondition) {
        case Effect.sleep:
        case Effect.freeze:
          alpha *= 2;
          break;
        case Effect.poison:
        case Effect.burn:
        case Effect.paralysis:
          alpha *= 1.5;
          break;
        default:
      }
      final levelBonus = max(1, (30 - target.individual.level) / 10);
      alpha *= levelBonus;
      final beta = 65536 / pow(1044480 / alpha, 0.25);
      print('alpha=$alpha, beta=$beta');
      for (int i = 0; i < 4; i++) {
        success = true;
        final rand = PRNG.instance.upto(65536);
        if (rand >= beta) {
          success = false;
          break;
        }
      }
    }
    if (success) {
      captive = target.individual;
      _battleEnded = true;
      print('Captured!');
      log('Caught $target!');
    } else {
      print('Failed');
      log('It got away...');
    }
  }
}
