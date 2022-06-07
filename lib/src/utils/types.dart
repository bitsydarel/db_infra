///
typedef MapHeaders = Map<String, String>;

///
typedef JsonMap = Map<String, Object?>;

///
extension A on Iterable<Enum> {
  List<String> asNameList() {
    return map((Enum e) => e.name).toList();
  }
}
