enum Stat {
  hp(0, 'HP'),
  atk(1, 'Attack'),
  def(2, 'Defense'),
  spAtk(3, 'Special Attack'),
  spDef(4, 'Special Defense'),
  speed(5, 'Speed'),
  accuracy(6, 'Accuracy'),
  evasion(7, 'Evasion'),
  critRatio(8, 'Critical Hit Ratio');

  const Stat(this.idx, this.fullName);

  final int idx;
  final String fullName;
}

class StatChange {
  const StatChange(this.stats, this.steps, [this.absolute = false]);
  final Set<Stat> stats;
  final int steps;
  final bool absolute;

  /// Stat is encoded into an integer as follows
  /// MSB - (1 if absolute: 1 bit)(1 if negative: 1 bit)(stat steps: 3 bits)(stats: 8 bits) - LSB
  int encode() {
    final negative = steps < 0;
    assert(steps.abs() < Stat.values.length);
    final bitset = stats.fold<int>(0, (i, stat) => (i | (1 << stat.idx)));
    return bitset | (steps.abs() << Stat.values.length) | (negative ? (1 << Stat.values.length + 3) : 0) | (absolute ? (1 << Stat.values.length + 4) : 0);
  }

  static StatChange decode(int encoded) {
    final absolute = (encoded & (1 << Stat.values.length + 4)) != 0;
    final negative = (encoded & (1 << Stat.values.length + 3)) != 0;
    final steps = (negative ? -1 : 1) * ((encoded >> Stat.values.length) & 7);
    final stats = Stat.values.where((stat) => (encoded & (1 << stat.idx)) != 0).toSet();
    return StatChange(stats, steps, absolute);
  }
}

const innateStats = 6;
const totalStats = 9;
const volatileStats = totalStats - innateStats;
