// Status that affects the entire field
enum EffectGlobal {
  gravity,
  trickRoom,
}

class BattleEffectGlobal {
  BattleEffectGlobal(this.effect, this.param);
  final EffectGlobal effect;
  int param;
}