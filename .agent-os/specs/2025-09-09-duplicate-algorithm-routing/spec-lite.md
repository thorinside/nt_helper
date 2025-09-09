# Spec Summary (Lite)

Fix ConnectionDiscoveryService to use the stable algorithm IDs already being generated instead of unstable hashCode fallback. Store the algorithmUuid in AlgorithmRouting instances to resolve the "Initializing routing editor..." freeze with duplicate algorithms.