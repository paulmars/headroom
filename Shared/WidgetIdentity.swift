/// Stable WidgetKit identities.
///
/// A widget kind is serialized into every placed tile. WidgetKit cannot
/// migrate a tile between configuration systems, so the legacy static widget
/// and the editable widget must never share one.
enum HeadroomWidgetIdentity {
    static let legacyKind = "HeadroomWidget"
    static let editableKind = "HeadroomWidget.Configurable"
    static let burnLeftKind = "HeadroomWidget.BurnLeft"
    static let smallResetKind = "HeadroomWidget.SmallReset"
}
