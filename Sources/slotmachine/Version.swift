/// The slot machine CLI's semantic version, surfaced by `slotmachine --version`.
///
/// The committed value is a development placeholder; the release workflow rewrites it
/// (via `sed`) to the tagged version when publishing a build.
enum SlotMachineVersion {
    /// The current semantic version string (e.g. `"0.1.0"`).
    static let current = "0.1.0"
}
