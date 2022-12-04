class Registry<T> {
  Registry({caseSensitive = false}) : _caseSensitive = caseSensitive;

  final List<T> _entries = [];
  final Map<String, int> _keys = {};
  final bool _caseSensitive;

  T get(int index) {
    return _entries[index];
  }

  Iterable<T> get values => _entries;

  int? getIndex(String key) {
    if (!_caseSensitive) {
      key = key.toLowerCase();
    }
    return _keys[key];
  }

  T operator [](String key) {
    final index = getIndex(key);
    return _entries[index ?? (throw ArgumentError("No key $key", "KeyError"))];
  }

  T? optional(String key) {
    final index = getIndex(key);
    if (index == null) {
      return null;
    }
    return _entries[index];
  }

  int put(String key, T value) {
    if (!_caseSensitive) {
      key = key.toLowerCase();
    }
    int? index = getIndex(key);
    if (index == null) {
      index = _entries.length;
      _keys[key] = _entries.length;
      _entries.add(value);
    } else {
      _entries[index] = value;
    }
    return index;
  }

  void operator []=(String key, T value) {
    put(key, value);
  }

  Map<String, T> toMap() {
    return _keys.map((key, value) => MapEntry(key, _entries[value]));
  }
}