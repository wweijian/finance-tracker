import SwiftUI

enum CategoryChartStyle {
    static func color(for category: String) -> Color {
        // A category keeps the same color across reports and reporting periods.
        let hash = category.unicodeScalars.reduce(UInt(2_166_136_261)) {
            ($0 ^ UInt($1.value)) &* 16_777_619
        }
        return Color(hue: Double(hash % 360) / 360, saturation: 0.65, brightness: 0.8)
    }
}
