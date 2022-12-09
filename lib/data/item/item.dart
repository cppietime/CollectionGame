import 'dart:convert';
import 'dart:math';

import 'package:collectgame/data/ball/ball.dart';
import 'package:flutter/services.dart';

import '../registry.dart';
import '../species/stat.dart';
import 'bag.dart';

import '../../battle/battle.dart';

typedef UseInBattleCallback = Future<bool> Function(
    BattleState battleState, Battler user, int param);
typedef UseOnBattlerCallback = Future<bool> Function(
    BattleState, Individual subject, BattlePlayer player, int param);
typedef BattlePredicate = Future<bool> Function(
    BattleState battleState, Battler user, int param);
typedef BattlerPredicate = Future<bool> Function(BattleState battleState,
    Individual subject, BattlePlayer player, int param);

final _battlePredicates = <String, BattlePredicate>{
  'ball': _ballBattlePredicate,
};
final _battleCallbacks = <String, UseInBattleCallback>{
  'ball': _ballBattleCallback,
};

final _battlerPredicates = <String, BattlerPredicate>{
  'heal': _healBattlerPredicate,
};
final _battlerCallbacks = <String, UseOnBattlerCallback>{
  'heal': _healBattlerCallback,
};

class Item {
  Item(
    this.id, {
    required this.name,
    required this.description,
    required this.pocket,
    this.battlePredicate,
    this.onBattleUse,
    this.battlerPredicate,
    this.onBattlerUse,
    this.param = 0,
  }) {
    index = items.put(id, this);
  }

  static final items = Registry<Item>();

  final String id;
  late final int index;

  final String name;
  final String description;
  final ItemCategory pocket;
  final int param;

  final BattlePredicate? battlePredicate;
  final UseInBattleCallback? onBattleUse;

  final BattlerPredicate? battlerPredicate;
  final UseOnBattlerCallback? onBattlerUse;

  static Item fromJson(Map<String, dynamic> jsonObject) {
    final id = jsonObject['id'] as String;
    final name = jsonObject['name'] as String? ?? id;
    final description = jsonObject[id] as String? ?? '';
    final pocket = ItemCategory.values.byName(jsonObject['pocket'] as String);
    final param = jsonObject['param'] as int? ?? 0;
    final battleKey = jsonObject['battle_callback'] as String? ?? '';
    final onBattleUse =
        _battleCallbacks[battleKey];
    final battlePredicate = _battlePredicates[battleKey];
    final battlerKey = jsonObject['battler_callback'] as String? ?? '';
    final onBattlerUse =
        _battlerCallbacks[battlerKey];
    final battlerPredicate = _battlerPredicates[battlerKey];
    return Item(
      id,
      name: name,
      description: description,
      pocket: pocket,
      param: param,
      battlePredicate: battlePredicate,
      onBattleUse: onBattleUse,
      battlerPredicate: battlerPredicate,
      onBattlerUse: onBattlerUse,
    );
  }

  static const itemsPath = 'assets/items.json';

  static Future<void> readItems() async {
    final jsonString = await rootBundle.loadString(itemsPath);
    final jsonList = jsonDecode(jsonString) as List<dynamic>;
    for (final jsonObject in jsonList) {
      final mapObject = jsonObject as Map<String, dynamic>;
      fromJson(mapObject);
    }
  }
}

Future<bool> _healBattlerPredicate(BattleState state, Individual subject, BattlePlayer player, int param) async {
  return subject.hp < subject.calcStat(Stat.hp);
}

Future<bool> _healBattlerCallback(
    BattleState state, Individual subject, BattlePlayer player, int param) async {
  if (subject.hp == subject.calcStat(Stat.hp)) {
    return false;
  }
  subject.hp += param;
  subject.hp = min(subject.hp, subject.calcStat(Stat.hp));
  state.log('Healed $subject');
  return true;
}

Future<bool> _ballBattlePredicate(BattleState state, Battler user, int param) async {
  final targets = state.enemySide.values;
  if (targets.length > 1) {
    return false;
  }
  final target = targets.first;
  return target.commander!.isWild;
}

Future<bool> _ballBattleCallback(BattleState state, Battler user, int param) async {
  final target = state.enemySide.values.first;
  await state.throwBall(user, target, Ball.values[param]);
  return true;
}