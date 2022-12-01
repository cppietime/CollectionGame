enum Stat {
  hp(0),
  atk(1),
  def(2),
  spAtk(3),
  spDef(4),
  speed(5),
  accuracy(6),
  evasion(7),
  critRatio(8);

  const Stat(this.idx);

  final int idx;
}

const innateStats = 6;
const totalStats = 9;
const volatileStats = totalStats - innateStats;
