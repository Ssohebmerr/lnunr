class PremiumActivationResult {
  const PremiumActivationResult({
    required this.ok,
    this.needsProfile = false,
  });

  final bool ok;
  final bool needsProfile;
}
