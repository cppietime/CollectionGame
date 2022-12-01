enum Nature {
  hardy(1, 1),
  lonely(1, 2),
  adamant(1, 3),
  naughty(1, 4),
  brave(1, 5),
  bold(2, 1),
  docile(2, 2),
  impish(2, 3),
  lax(2, 4),
  relaxed(2, 5),
  modest(3, 1),
  mild(3, 2),
  bashful(3, 3),
  rash(3, 4),
  quiet(3, 5),
  calm(4, 1),
  gentle(4, 2),
  careful(4, 3),
  quirky(4, 4),
  sassy(4, 5),
  timid(5, 1),
  hasty(5, 2),
  jolly(5, 3),
  naive(5, 4),
  serious(5, 5);
  const Nature(this.upStat, this.downStat);
  final int upStat, downStat;
}