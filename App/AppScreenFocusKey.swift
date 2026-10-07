import SwiftUI

struct AppScreenFocusKey: FocusedValueKey {
    typealias Value = Binding<AppScreen>
}

extension FocusedValues {
    var appScreen: Binding<AppScreen>? {
        get { self[AppScreenFocusKey.self] }
        set { self[AppScreenFocusKey.self] = newValue }
    }
}
