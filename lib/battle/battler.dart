import 'dart:math';

import 'package:collectgame/battle/battle_action.dart';
import 'package:collectgame/battle/battle_state.dart';
import 'package:collectgame/data/ability/ability.dart';
import 'package:collectgame/data/ball/ball.dart';
import 'package:collectgame/data/prng.dart';
import 'package:collectgame/data/species/creature_type.dart';
import 'package:collectgame/data/species/nature.dart';
import 'package:collectgame/data/species/species.dart';
import 'package:collectgame/data/species/stat.dart';

import '../data/move/move.dart';
import 'battle_player.dart';
import 'effect.dart';

enum AbilitySelector {
  first,
  second,
  hidden;
}

enum Gender {
  male,
  female,
  genderless;
}

class Individual {
  Individual(
    this.species, {
    List<int>? ivs,
    Nature? nature,
    int exp = 0,
    this.happiness = 0,
    int? pid,
    int? otTID,
    int? otSID,
    this.metAtId = -1,
    Gender? gender,
  })  : currentMoves = List.filled(4, null),
        ivs = ivs ?? List.filled(innateStats, 0),
        nature = nature ?? Nature.docile,
        evolutionCriteria = List.filled(species.evolutions.length, 0),
        movePP = List.filled(4, 0),
        pid = pid ?? PRNG.instance.u16(),
        otTID = otTID ?? PRNG.instance.u16(),
        otSID = otSID ?? PRNG.instance.u16(),
        exp = 0 {
    gainExp(exp);
    hp = calcStat(Stat.hp);
    switch (species.genderDistribution) {
      case GenderDistribution.genderless:
        this.gender = Gender.genderless;
        break;
      case GenderDistribution.allMale:
        this.gender = Gender.male;
        break;
      case GenderDistribution.allFemale:
        this.gender = Gender.female;
        break;
      default:
        if (gender == null || gender == Gender.genderless) {
          this.gender =
              PRNG.instance.uniform() <= species.genderDistribution.femaleChance
                  ? Gender.female
                  : Gender.male;
        } else {
          this.gender = gender;
        }
    }
  }

  // Semi-immutable
  Species species;

  String? nickname;

  Gender gender = Gender.genderless;
  int pid = 0;
  AbilitySelector ability = AbilitySelector.first;
  List<int> ivs;
  Nature nature;

  // Caught data
  Ball? ball;

  DateTime metOn = DateTime.fromMillisecondsSinceEpoch(0);
  int metAtId;

  String? otName;

  int otTID;
  int otSID;

  // Mutable
  int exp = 0;
  int _level = 1;

  int get level => _level;
  int happiness = 0;
  List<int> evs = List.filled(innateStats, 0);
  int hatchStepsLeft = 0;
  List<int> ppUps = List.filled(4, 0);
  List<int> evolutionCriteria;

  // Item heldItem
  List<int> contestStats = List.filled(ContestType.values.length, 0);

  // Ribbons
  BigInt rememberedTmMoves = BigInt.zero;
  BigInt rememberedEggMoves = BigInt.zero;
  BigInt rememberedTutorMoves = BigInt.zero;

  List<Move?> currentMoves;

  // Party only data
  late int hp;

  List<int> movePP;

  Effect? statusCondition;

  void defaultMoves() {
    int counter = 0;
    for (final move in species.levelUpMoves) {
      if (move.level >= level) {
        return;
      }
      currentMoves[counter] = move.move;
      counter = (counter + 1) % 4;
    }
  }

  void gainExp(int gain) {
    if (_level <= 0) {
      _level = 1;
      exp = 0;
    }
    exp += gain;
    while (_level < 100 && gain > 0) {
      final needed = species.expCurve.levelFn(_level + 1) - exp;
      if (gain >= needed) {
        _level++;
      }
      gain -= needed;
    }
  }

  int calcStat(Stat stat) {
    assert(stat.idx < innateStats);
    int value =
        species.calcStat(stat, level, ivs[stat.idx], evs[stat.idx], nature);
    return value;
  }

  Ability calcAbility() {
    switch (ability) {
      case AbilitySelector.first:
        return species.ability1;
      case AbilitySelector.second:
        return species.ability2 ?? species.ability1;
      case AbilitySelector.hidden:
        return species.abilityH ?? species.ability1;
    }
  }

  List<CreatureType> types() {
    List<CreatureType> types = [species.type1];
    if (species.type2 != null) {
      types.add(species.type2!);
    }
    return types;
  }

  int ppOf(Move move) {
    final moveIndex = currentMoves.indexOf(move);
    if (moveIndex == -1) {
      return 0;
    }
    return movePP[moveIndex];
  }

  int losePP(Move move, int pp) {
    final moveIndex = currentMoves.indexOf(move);
    if (moveIndex == -1) {
      return 0;
    }
    if (movePP[moveIndex] < pp) {
      pp = movePP[moveIndex];
    }
    movePP[moveIndex] -= pp;
    return pp;
  }

  @override
  String toString() => nickname ?? '$species';

  static Species? breedsTo(Individual one, Individual two) {
    if (!Species.canBreed(one.species, two.species)) {
      return null;
    }
    final canBreed =
        one.gender != two.gender || one.gender == EggGroup.genderless;
    if (canBreed) {
      final parent = one.gender == Gender.female
          ? one
          : two.species.eggGroup1 == EggGroup.ditto
              ? one
              : two;
      return parent.species.breedsTo();
    }
    return null;
  }
}

class Battler {
  Battler(this.individual)
      : effectiveStats = Stat.values
            .map((stat) =>
                stat.idx < innateStats ? individual.calcStat(stat) : 0)
            .toList(),
        availableMoves = individual.currentMoves,
        effectiveAbility = individual.calcAbility(),
        effectiveTypes = individual.types();

  Individual individual;
  List<int> effectiveStats;
  Ability effectiveAbility;
  List<CreatureType> effectiveTypes;

  List<Move?> availableMoves;

  List<BattleEffect> volatileStatus = [];
  List<int> statChanges = List.filled(Stat.values.length, 0);

  Move? lastMoveUsed;

  int timesLastMoveUsed = 0;
  int indexOnSide = 0;
  bool isPlayers = false;

  BattleAction? queuedAction;

  BattlePlayer? commander;

  int effectiveSpeed(BattleState state) {
    int speed = individual.calcStat(Stat.speed);
    // TODO modify from ability
    // TODO modify from side effects
    // TODO modify from global effects
    return speed;
  }

  double stageMultiplier(int stages) {
    if (stages > 0) {
      return 1 + 0.5 * stages;
    } else if (stages < 0) {
      return 1 / (1 - 0.5 * stages);
    }
    return 1;
  }

  int calcStat(Stat stat, {bool? critical}) {
    if (stat.idx < innateStats) {
      int val = effectiveStats[stat.idx];
      int stages = statChanges[stat.idx];
      if (critical == true) {
        if (stat == Stat.atk || stat == Stat.spAtk) {
          stages = max(0, stages);
        } else if (stat == Stat.def || stat == Stat.spDef) {
          stages = min(0, stages);
        }
      }
      return (val * stageMultiplier(stages)).truncate();
    } else {
      return statChanges[stat.idx];
    }
  }

  BattleEffect? currentEffect(Effect effect) {
    for (final current in volatileStatus) {
      if (current.effect == effect) {
        return current;
      }
    }
    return null;
  }

  void setEffect(BattleEffect effect) {
    volatileStatus.removeWhere((current) => current.effect == effect.effect);
    volatileStatus.add(effect);
  }

  void removeEffect(Effect effect) {
    volatileStatus.removeWhere((current) => current.effect == effect);
  }

  @override
  String toString() => '${isPlayers ? "Your " : "Foe "}$individual';
}
