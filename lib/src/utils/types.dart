///
typedef MapHeaders = Map<String, String>;

///
typedef JsonMap = Map<String, Object?>;

/// Get the enum name.
String enumName(final Object enumEntry) {
  final String description = enumEntry.toString();
  final int indexOfDot = description.indexOf('.');
  assert(
    indexOfDot != -1 && indexOfDot < description.length - 1,
    'The provided object "$enumEntry" is not an enum.',
  );
  return description.substring(indexOfDot + 1);
}
