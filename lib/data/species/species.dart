import 'dart:convert';
import 'dart:math';

import 'package:collectgame/data/ability/ability.dart';
import 'package:collectgame/data/move/move.dart';
import 'package:collectgame/data/registry.dart';
import 'package:collectgame/data/species/stat.dart';
import 'package:flutter/services.dart';

import 'creature_type.dart';
import 'evolution.dart';
import 'nature.dart';

typedef LvlToExp = int Function(int lvl);
// Taken from https://bulbapedia.bulbagarden.net/wiki/Experience#Relation_to_level
int _slow(int lvl) => (5 * pow(lvl, 3) / 4) as int;

int _mediumSlow(int lvl) =>
    (6 * pow(lvl, 3) / 5 - 15 * lvl * lvl + 100 * lvl - 140) as int;

int _mediumFast(int lvl) => lvl * lvl * lvl;

int _fast(int lvl) => (4 * pow(lvl, 3) / 5) as int;

int _fluctuating(int lvl) {
  if (lvl < 15) {
    return pow(lvl, 3) * (24 + (lvl + 1) / 3 as int) / 50 as int;
  }
  if (lvl < 36) {
    return pow(lvl, 3) * (lvl + 14) / 50 as int;
  }
  return pow(lvl, 3) * (32 + lvl / 2 as int) / 50 as int;
}

int _erratic(int lvl) {
  if (lvl < 50) {
    return pow(lvl, 3) * (100 - lvl) / 50 as int;
  }
  if (lvl < 68) {
    return pow(lvl, 3) * (150 - lvl) / 100 as int;
  }
  if (lvl < 98) {
    return pow(lvl, 3) * (1911 - 10 * lvl / 3 as int) / 500 as int;
  }
  return pow(lvl, 3) * (160 - lvl) / 100 as int;
}

enum ExpCurve {
  slow(_slow),
  mediumSlow(_mediumSlow),
  mediumFast(_mediumFast),
  fast(_fast),
  fluctuating(_fluctuating),
  erratic(_erratic);

  const ExpCurve(this.levelFn);

  final LvlToExp levelFn;
}

enum GenderDistribution { genderless, equal }

enum EggGroup { undiscovered }

class LevelUpMove {
  const LevelUpMove(this.level, this.move);

  final int level;
  final Move move;
}

class Species {
  static final Registry<Species> species = Registry();

  Species(
    this.id, {
    required this.name,
    required this.dexNo,
    required this.type1,
    this.type2,
    required this.ability1,
    this.ability2,
    this.abilityH,
    required this.baseStats,
    required this.happiness,
    required this.catchRate,
    required this.expCurve,
    required this.genderDistribution,
    required this.hatchTime,
    required this.eggGroup1,
    this.eggGroup2,
    this.description = "",
    this.category = "",
    this.height = 0,
    this.weight = 0,
    this.levelUpMoves = const [],
    this.eggMoves = const {},
    this.tutorMoves = const {},
    this.tms = const {},
    this.evolutions = const [],
  }) {
    index = species.put(id, this);
  }

  final String id;
  late final int index;

  // Dex info
  final String name;
  final int dexNo;
  final String description;
  final String category;
  final double height;
  final double weight;

  // Battle info
  final CreatureType type1;
  final CreatureType? type2;
  final Ability ability1;
  final Ability? ability2;
  final Ability? abilityH;
  final List<int> baseStats;

  // Training info
  final int happiness;
  final int catchRate;
  final ExpCurve expCurve;
  final List<LevelUpMove> levelUpMoves;
  final Set<Move> eggMoves;
  final Set<Move> tutorMoves;
  final Set<int> tms;
  final List<Evolution> evolutions;

  // Breeding info
  final GenderDistribution genderDistribution;
  final int hatchTime;
  final EggGroup eggGroup1;
  final EggGroup? eggGroup2;

  int calcStat(Stat stat, int level, int iv, int ev, Nature nature) {
    int baseStat = baseStats[stat.idx] * 2;
    if (baseStat == 0) {
      // Shedinja
      return 1;
    }
    // From https://bulbapedia.bulbagarden.net/wiki/Stat#Generation_III_onward
    if (stat == Stat.hp) {
      return ((2 * baseStat + iv + ev ~/ 4) * level) ~/ 100 + 10 + level;
    } else {
      baseStat = ((2 * baseStat + iv + ev ~/ 4) * level) ~/ 100 + 5;
      if (nature.upStat != nature.downStat) {
        if (nature.upStat == stat.idx) {
          baseStat += baseStat ~/ 10;
        } else if (nature.upStat == stat.idx) {
          baseStat -= baseStat ~/ 10;
        }
      }
      return baseStat;
    }
  }

  @override
  String toString() => name;

  static Species fromJson(Map<String, dynamic> jsonObject) {
    final id = jsonObject['id'] as String;
    final name = jsonObject['name'] as String? ?? id;
    final dexNo = jsonObject['dex_no'] as int;
    final category = jsonObject['category'] as String? ?? "";
    final description = jsonObject['description'] as String? ?? "";
    final height = jsonObject['height'] as double? ?? 0;
    final weight = jsonObject['weight'] as double? ?? 0;
    final type1 = CreatureType.of(jsonObject['type1'] as String)!;
    final type2 = CreatureType.of(jsonObject['type2'] as String?);
    final ability1 = Ability.abilities[jsonObject['ability1'] as String];
    final ability2 =
        Ability.abilities.optional(jsonObject['ability2'] as String? ?? "");
    final abilityH =
        Ability.abilities.optional(jsonObject['abilityH'] as String? ?? "");
    final baseStats = List<int>.from(jsonObject['stats']);
    final happiness = jsonObject['happiness'] as int? ?? 100;
    final catchRate = jsonObject['catch_rate'] as int? ?? 30;
    final expCurve =
        ExpCurve.values.asNameMap()[jsonObject['exp_curve'] as String? ?? ""] ??
            ExpCurve.slow;
    final genderDistribution = GenderDistribution.values
            .asNameMap()[jsonObject['gender_distribution'] as String? ?? ""] ??
        GenderDistribution.equal;
    final hatchTime = jsonObject['hatchTime'] as int? ?? 1000;
    final eggGroup1 =
        EggGroup.values.byName(jsonObject['egg_group1'] as String);
    final eggGroup2 =
        EggGroup.values.asNameMap()[jsonObject['egg_group1'] as String? ?? ""];
    final lvlUpMoves =
        (jsonObject['level_moves'] as List<dynamic>? ?? []).map((lvlUpDyn) {
      final lvlUp = lvlUpDyn as List<dynamic>; // [ level, "move" ]
      final lvl = lvlUp[0] as int;
      final move = Move.moves[lvlUp[1] as String];
      return LevelUpMove(lvl, move);
    }).toList();
    final eggMoves = (jsonObject['egg_moves'] as List<dynamic>? ?? [])
        .map((name) => Move.moves[name as String])
        .toSet();
    final tutorMoves = (jsonObject['tutor_moves'] as List<dynamic>? ?? [])
        .map((name) => Move.moves[name as String])
        .toSet();
    final tms = (jsonObject['tms'] as List<dynamic>? ?? [])
        .map((i) => i as int)
        .toSet();
    final evolutions =
        (jsonObject['evolutions'] as List<dynamic>? ?? []).map((evoMap) {
      final evo = evoMap as Map<String, dynamic>;
      final method = EvolutionMethod.values.byName(evo['method'] as String);
      final param = evo['param'] as int? ?? 0;
      final into = evo['into'] as String;
      return Evolution(method, param, into);
    }).toList();

    return Species(
      id,
      name: name,
      dexNo: dexNo,
      category: category,
      description: description,
      height: height,
      weight: weight,
      type1: type1,
      type2: type2,
      ability1: ability1,
      ability2: ability2,
      abilityH: abilityH,
      baseStats: baseStats,
      happiness: happiness,
      catchRate: catchRate,
      expCurve: expCurve,
      hatchTime: hatchTime,
      eggGroup1: eggGroup1,
      eggGroup2: eggGroup2,
      genderDistribution: genderDistribution,
      levelUpMoves: lvlUpMoves,
      eggMoves: eggMoves,
      tms: tms,
      tutorMoves: tutorMoves,
      evolutions: evolutions,
    );
  }

  static const _speciesPath = "assets/species.json";

  static Future<void> readSpecies() async {
    final jsonString = await rootBundle.loadString(_speciesPath);
    final jsonList = jsonDecode(jsonString) as List<dynamic>;
    for (final jsonObject in jsonList) {
      fromJson(jsonObject as Map<String, dynamic>);
    }
    print(species.toMap());
  }
}
