import 'package:collectgame/battle/battle_state.dart';
import 'package:collectgame/battle/battler.dart';
import 'package:collectgame/data/move/move.dart';
import 'package:collectgame/data/move/move_effect.dart';
import 'package:collectgame/data/registry.dart';

typedef KnockoutTrigger = void Function(
    BattleState battleState, Individual fainted, Individual? cause);
typedef GlobalTrigger = void Function(
    BattleState battleState, Individual subject);
typedef AbilityModifier<T> = T Function(
    BattleState battleState, Battler user, Battler target, Move move, T param);

class Ability {
  static Registry<Ability> abilities = Registry();

  Ability(
    this.id,
    this.name, {
    this.affectsModifierAttack,
    this.affectsModifierDefend,
    this.accuracyModifierAttack,
    this.accuracyModifierDefend,
    this.damageModifierAttack,
    this.damageModifierDefend,
    this.critModifierAttack,
    this.critModifierDefend,
    this.speedModifier,
    this.onKnockOut,
    this.onKnockedOut,
    this.onTouch,
    this.onTouched,
    this.onSendOut,
    this.onSwitchedOut,
    this.onAllyAttack,
    this.onAllyAttacked,
    this.targetModifier,
    this.onTurnEnd,
    this.priorityModifier,
    this.description = "",
  }) {
    register();
  }

  void register() {
    print('Registing $id');
    index = abilities.put(id, this);
    print('Registered');
  }

  final String name;
  final String id;
  final String description;
  late final int index;

  final AbilityModifier<bool>? affectsModifierAttack;
  final AbilityModifier<bool>? affectsModifierDefend;
  final AbilityModifier<int>? accuracyModifierAttack;
  final AbilityModifier<int>? accuracyModifierDefend;
  final AbilityModifier<int>? damageModifierAttack;
  final AbilityModifier<int>? damageModifierDefend;
  final AbilityModifier<int>? critModifierAttack;
  final AbilityModifier<int>? critModifierDefend;
  final AbilityModifier<int>? speedModifier;
  final AbilityModifier<int>? priorityModifier;
  final KnockoutTrigger? onKnockOut;
  final KnockoutTrigger? onKnockedOut;
  final MoveHitTrigger? onTouch;
  final MoveHitTrigger? onTouched;
  final GlobalTrigger? onSendOut;
  final GlobalTrigger? onSwitchedOut;
  final MoveUseTrigger? onAllyAttack;
  final MoveUseTrigger? onAllyAttacked;
  final TargetModifier? targetModifier;
  final GlobalTrigger? onTurnEnd;

  /*
  TODO typedefs and members for these functions
  Functions of yet unknown type:
  attackingAffects: determine if a move affects a target
  defendingAffects
  attackingAccuracy: modify the accuracy of a move
  defendingAccuracy
  attackingDamage: modify the damage of a move
  defendingDamage
  attackingCritical
  defendingCritical
  onKnockOut
  onKnockedOut
  onTouch
  onTouched
  onSendOut
  onSwitchedOut
  allyAttacks
  modifyTarget
  onTurnEnd
  modifySpeed

  Flow of modifier once move is selected w/ ability
  check success against each status
  target = target_side.abilities.modifyTarget
  affects based on type matchup immunity
  user.ability.attackingAffects
  target.ability.defendingAffects
  move.modifySuccess
  determine if successful, quit if not
  user.ability.attackingAccuracy
  target.ability.defendingAccuracy
  move.modifyAccuracy
  determine if hits
  if missed: move.onMiss then quit
  user.ability.attackingCritical
  target.ability.defendingCritical
  user_side.abilities.allyAttacks
  move.modifyPower
  calculate damage
  user.ability.attackingDamage
  target.ability.defendingDamage
  move.modifyDamage
  move.isSuccessful, quit if none succeed
  inflict damage
  move.onHit
  user.ability.onTouch if contact
  target.ability.onTouched if contact

  e.g. User with corrosion uses toxic on a steel type
  target unchanged
  type matchup => does not affect
  corrosion.attackingAffects: does affect
  no other changes, move is successful
  abilities do not change accuracy
  move may modify accuracy based on user's type if Poison
  assume it hits
  non damaging move, skip damage modifiers
  move.isSuccessful checks if target is already poisoned, fails if so
  otherwise, inflict damage is skipped, then
  move.onHit is called, inflicting bad poisoning
  call onTouch(ed) methods if contact flag is set
   */

  static void initialize() {
    // List of abilities below
    // TODO define and implement abilities

    // Gen III
    Ability("stench", "Stench");
    Ability("drizzle", "Drizzle");
    Ability("speed_boost", "Speed Boost");
    Ability("battle_armor", "Battle Armor");

    // Gen IV
    Ability("tangled_feet", "Tangled Feet");

    // Gen V
    Ability("pickpocket", "Pickpocket");

    // Gen VI
    Ability("aroma_veil", "Aroma Veil");

    // Gen VII
    Ability("stamina", "Stamina");

    // Gen VIII
    Ability("intrepid_sword", "Intrepid Sword");

    // Gen IX
    Ability("lingering_aroma", "Lingering Aroma");
  }
}
