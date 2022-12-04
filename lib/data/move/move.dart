import 'dart:convert';

import 'package:collectgame/data/move/move_effect.dart';
import 'package:collectgame/data/species/creature_type.dart';
import 'package:flutter/services.dart';

import '../registry.dart';

enum MoveCategory { physical, special, status }

enum TargetType {
  oneEnemy,
  oneAlly,
  oneAdjacent,
  one,
  self,
  enemySide,
  allySide,
  adjacentEnemies,
  adjacentAllies,
  adjacentEnemy,
  adjacentAlly,
  allEnemies,
  allAllies,
  allAdjacent,
  allOther,
  all;

  Iterable<MoveTarget> allPossibleTargets(int maxPerSide, int myPosition) {
    switch (this) {
      case TargetType.oneEnemy:
        return List<MoveTarget>.generate(
            maxPerSide, (i) => MoveTarget(false, i));
      case TargetType.oneAlly:
        return List<MoveTarget>.generate(maxPerSide, (i) => MoveTarget(true, i))
            .where((t) => t.sideIndex != myPosition);
      case TargetType.oneAdjacent:
        final targets = [MoveTarget(false, myPosition)];
        if (myPosition > 0) {
          targets.addAll([
            MoveTarget(false, myPosition - 1),
            MoveTarget(true, myPosition - 1)
          ]);
        }
        if (myPosition + 1 < maxPerSide) {
          targets.addAll([
            MoveTarget(false, myPosition + 1),
            MoveTarget(true, myPosition + 1)
          ]);
        }
        return targets;
      case TargetType.adjacentEnemy:
        final targets = [MoveTarget(false, myPosition)];
        if (myPosition > 0) {
          targets.add(MoveTarget(false, myPosition - 1));
        }
        if (myPosition + 1 < maxPerSide) {
          targets.add(MoveTarget(false, myPosition + 1));
        }
        return targets;
      case TargetType.adjacentAlly:
        final targets = <MoveTarget>[];
        if (myPosition > 0) {
          targets.add(MoveTarget(true, myPosition - 1));
        }
        if (myPosition + 1 < maxPerSide) {
          targets.add(MoveTarget(true, myPosition + 1));
        }
        return targets;
      case TargetType.one:
        return List<MoveTarget>.generate(
                maxPerSide, (i) => MoveTarget(false, i)) +
            List<MoveTarget>.generate(maxPerSide, (i) => MoveTarget(true, i)).where((t) => t.sideIndex != myPosition).toList();
      case TargetType.self:
      case TargetType.allySide:
      case TargetType.enemySide:
      case TargetType.adjacentAllies:
      case TargetType.adjacentEnemies:
      case TargetType.allAdjacent:
      case TargetType.allAllies:
      case TargetType.allEnemies:
      case TargetType.all:
      case TargetType.allOther:
        return [MoveTarget(true, myPosition)];
    }
  }
}

class MoveTarget {
  const MoveTarget(this.selfSide, this.sideIndex);
  final bool selfSide;
  final int sideIndex;

  int toInt() => sideIndex | (selfSide ? 0x0100 : 0x0000);

  static MoveTarget fromInt(int i) => MoveTarget(i >= 0x0100, i & 0xff);
}

enum ContestType { cute, cool, beauty, smart, tough }

enum HitCount { once, twice, thrice, upToThree, upToTen, twoToFive }

enum MoveFlag {
  contact,
  protect,
  magicCoat,
  snatch,
  mirrorMove,
  kingsRock,
  dance,
  sound,
  fang,
  claw,
  punch;
}

class MoveEffectEntry {
  const MoveEffectEntry(this.effect, this.param, this.chance);

  final MoveEffect effect;
  final int param;
  final double chance;
}

class Move {
  static final Registry<Move> moves = Registry();

  Move(this.id,
      {required this.name,
      required this.pp,
      required this.description,
      required this.power,
      required this.accuracy,
      required this.type,
      required this.category,
      this.priority = 0,
      this.targetType = TargetType.oneEnemy,
      required this.contestType,
      required this.appeal,
      required this.jam,
      required this.contestDescription,
      this.flags = const {MoveFlag.protect, MoveFlag.mirrorMove},
      this.hitCount = HitCount.once,
      this.effects = const []}) {
    index = moves.put(id, this);
  }

  final String id;
  final String name;
  final int pp;
  final String description;
  late final int index;
  final int power;
  final int accuracy;
  final CreatureType type;
  final MoveCategory category;
  final int priority;
  final TargetType targetType;
  final ContestType contestType;
  final int appeal;
  final int jam;
  final String contestDescription;
  final Set<MoveFlag> flags;
  final HitCount hitCount;
  final List<MoveEffectEntry> effects;

  @override
  String toString() => name;

  static Move fromJson(Map<String, dynamic> jsonObject) {
    final id = jsonObject['id'] as String;
    final name = jsonObject['name'] as String? ?? id;
    final pp = jsonObject['pp'] as int? ?? 10;
    final description = jsonObject['description'] as String? ?? "";
    final power = jsonObject['power'] as int? ?? 0;
    final accuracy = jsonObject['accuracy'] as int? ?? 100;
    final priority = jsonObject['priority'] as int? ?? 0;
    final type = CreatureType.values.byName(jsonObject['type'] as String);
    final category =
        MoveCategory.values.byName(jsonObject['category'] as String);
    final target =
        TargetType.values.byName(jsonObject['target'] as String? ?? "one");
    final contestType = ContestType.values
        .byName(jsonObject['contestType'] as String? ?? "cool");
    final appeal = jsonObject['appeal'] as int? ?? 0;
    final jam = jsonObject['jam'] as int? ?? 0;
    final contestDescription =
        jsonObject['contest_description'] as String? ?? "";
    final flags =
        (jsonObject['flags'] as List<dynamic>? ?? ['protect', 'mirrorMove'])
            .map((s) => MoveFlag.values.byName(s as String))
            .toSet();
    final hitCount =
        HitCount.values.byName(jsonObject['hit_count'] as String? ?? "once");
    final effects = (jsonObject['effects'] as List<dynamic>? ?? []).map((e) {
      final map = e as Map<String, dynamic>;
      return MoveEffectEntry(
          MoveEffect.effects[map['effect'] as String],
          (map['param'] as num? ?? 0).toInt(),
          (map['chance'] as num? ?? 1).toDouble());
    }).toList(growable: false);
    return Move(
      id,
      name: name,
      pp: pp,
      description: description,
      power: power,
      accuracy: accuracy,
      priority: priority,
      type: type,
      category: category,
      targetType: target,
      contestType: contestType,
      appeal: appeal,
      jam: jam,
      contestDescription: contestDescription,
      flags: flags,
      hitCount: hitCount,
      effects: effects,
    );
  }

  static const String movesPath = "assets/moves.json";

  static Future<void> readMoves() async {
    final jsonString = await rootBundle.loadString(movesPath);
    final jsonList = jsonDecode(jsonString) as List<dynamic>;
    for (final jsonObject in jsonList) {
      fromJson(jsonObject);
    }
  }

  static final struggle = Move('struggle',
      name: 'Struggle',
      pp: 1,
      description: 'Struggle',
      power: 50,
      accuracy: 0,
      type: CreatureType.typeless,
      category: MoveCategory.physical,
      contestType: ContestType.cool,
      targetType: TargetType.one,
      appeal: 4,
      jam: 0,
      contestDescription: "",
      effects: [
        MoveEffectEntry(MoveEffect.recoilFraction, 50, 1),
        MoveEffectEntry(MoveEffect.affectsEverything, 0, 1),
      ]);
}
