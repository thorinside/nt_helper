# Spec Summary (Lite)

Refactor the Port model to remove the generic Map<String, dynamic> metadata field and collapse it into direct typesafe properties on the Port class. This will improve developer experience through compile-time validation, IDE autocomplete support, and eliminate the need for manual type casting and string-based property access.