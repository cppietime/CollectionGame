import 'package:collectgame/data/species/species.dart';

enum CreatureType {
  typeless,
  normal,
  fighting,
  flying,
  ghost,
  bug,
  rock,
  ground,
  poison,
  steel,
  grass,
  fire,
  water,
  electric,
  ice,
  psychic,
  dragon,
  dark,
  fairy;

  static final Map<CreatureType, Set<CreatureType>> weaknesses = {
    normal: {fighting},
    fighting: {flying, psychic, fairy},
    flying: {rock, electric, ice},
    ghost: {ghost, dark},
    bug: {flying, rock, fire},
    rock: {fighting, steel, grass, water},
    ground: {grass, water, ice},
    poison: {ground, psychic},
    steel: {fighting, ground, fire},
    grass: {flying, bug, poison, fire, ice},
    fire: {rock, ground, water},
    water: {grass, electric},
    electric: {ground},
    ice: {fighting, rock, steel, fire},
    psychic: {bug, ghost, dark},
    dragon: {ice, dragon, fairy},
    dark: {fighting, bug, fairy},
    fairy: {poison, steel},
  };

  static final Map<CreatureType, Set<CreatureType>> immunities = {
    normal: {ghost},
    flying: {ground},
    ghost: {normal, fighting},
    ground: {electric},
    steel: {poison},
    dark: {psychic},
    fairy: {dragon}
  };

  static final Map<CreatureType, Set<CreatureType>> resistances = {
    fighting: {bug, rock, dark},
    flying: {fighting, bug, grass},
    ghost: {bug, poison},
    bug: {fighting, ground, grass},
    rock: {normal, flying, poison, fire},
    ground: {poison, rock},
    poison: {fighting, bug, poison, grass, fairy},
    steel: {
      normal,
      flying,
      bug,
      rock,
      steel,
      grass,
      ice,
      psychic,
      dragon,
      fairy
    },
    grass: {ground, grass, water},
    fire: {bug, steel, fire, grass, ice, fairy},
    water: {steel, fire, water, ice},
    electric: {flying, steel, electric},
    ice: {ice},
    psychic: {fighting, psychic},
    dragon: {grass, fire, water, electric},
    dark: {ghost, dark},
    fairy: {fighting, bug, dark}
  };

  bool affects(CreatureType other) {
    return !(immunities[other] ?? {}).contains(this);
  }

  double efficacy(CreatureType other) {
    if (!affects(other)) {
      return 1; // We only will calculate damage in this case if immunity is negated.
    } else if ((weaknesses[other] ?? {}).contains(this)) {
      return 2;
    } else if ((resistances[other] ?? {}).contains(this)) {
      return 0.5;
    }
    return 1;
  }

  double efficacyOn(Species species) {
    double power = efficacy(species.type1);
    if (species.type2 != null) {
      power *= efficacy(species.type2!);
    }
    return power;
  }

  static CreatureType? of(String? name) =>
      name == null ? null : CreatureType.values.asNameMap()[name];
}
