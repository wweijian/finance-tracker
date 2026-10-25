import SwiftUI

struct ImportHorizontalScrollControls: View {
    @ObservedObject var controller: ImportTableScrollController

    var body: some View {
        HStack(spacing: 6) {
            Text("Scroll columns").font(.caption).foregroundStyle(.secondary)
            Button("Scroll left", systemImage: "chevron.left", action: controller.scrollLeft)
                .disabled(!controller.canScrollLeft)
                .help("Scroll to earlier columns")
            Slider(value: Binding(get: { controller.horizontalPosition }, set: { controller.scroll(to: $0) }), in: 0...1)
                .frame(width: 160)
                .disabled(!controller.canScrollLeft && !controller.canScrollRight)
                .accessibilityLabel("Horizontal table position")
                .help("Drag to scroll across the table")
            Button("Scroll right", systemImage: "chevron.right", action: controller.scrollRight)
                .disabled(!controller.canScrollRight)
                .help("Scroll to later columns, including remarks")
        }
        .labelStyle(.iconOnly)
        .controlSize(.small)
    }
}
