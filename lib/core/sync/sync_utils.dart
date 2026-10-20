/// Validation utilities for Supabase UUID foreign keys and sync payloads.
library;

final _uuidRegex = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// Returns true if [id] is a valid non-guest RFC 4122 UUID.
bool isValidUuid(String? id) {
  if (id == null || id.isEmpty || id.trim().toLowerCase() == 'guest') {
    return false;
  }
  return _uuidRegex.hasMatch(id.trim());
}
