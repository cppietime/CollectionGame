import 'dart:ffi';
import 'dart:math';

class PRNG {
  static final PRNG instance = PRNG();

  final Random random = Random();

  int u16() => random.nextInt(65536);

  double uniform() => random.nextDouble();

  int upto(int limit) => random.nextInt(limit);

  T choice<T>(List<T> candidates) => candidates[upto(candidates.length)];
}