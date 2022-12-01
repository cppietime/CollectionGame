import 'package:collectgame/data/species/species.dart';

enum EvolutionMethod {
  levelUp
}

class Evolution {
  const Evolution(this.method, this.param, this.intoId);

  final EvolutionMethod method;
  final int param;
  final String intoId;
}