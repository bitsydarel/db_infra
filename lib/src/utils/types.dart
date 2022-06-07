/// Type that represent a http header.
typedef MapHeaders = Map<String, String>;

/// Type that represent a Json map.
typedef JsonMap = Map<String, Object?>;

/// Extension function on [Enum].
extension A on Iterable<Enum> {

  /// Create a list containing all the name of the enums.
  List<String> asNameList() {
    return map((Enum e) => e.name).toList();
  }
}
