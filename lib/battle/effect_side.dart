// Statuses that affects one side of the battle
enum EffectSide {
  spikes
}

class BattleEffectSide {
  BattleEffectSide(this.effect, this.param);
  final EffectSide effect;
  int param;
}