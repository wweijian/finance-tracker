import AppKit
import SwiftUI
import XCTest
@testable import LedgerlyApp

@MainActor
final class AddTransactionsFloatingButtonTests: XCTestCase {
    func testEnabledButtonRendersVisibleTealFill() async throws {
        _ = NSApplication.shared
        let view = AddTransactionsFloatingButton(showsMenu: .constant(false))
            .padding(20)
            .background(.white)
            .environment(\.colorScheme, .light)
        let host = NSHostingView(rootView: view)
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 88, height: 88),
                              styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = host
        defer { window.close() }
        host.layoutSubtreeIfNeeded()
        try await Task.sleep(for: .milliseconds(50))
        host.layoutSubtreeIfNeeded()

        let bitmap = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
        host.cacheDisplay(in: host.bounds, to: bitmap)
        var coloredPixels = 0
        for y in 0..<bitmap.pixelsHigh {
            for x in 0..<bitmap.pixelsWide {
                guard let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB) else { continue }
                if color.alphaComponent > 0.9 && color.redComponent < 0.3
                    && color.greenComponent > 0.4 && color.blueComponent > 0.4 {
                    coloredPixels += 1
                }
            }
        }
        let coloredFraction = Double(coloredPixels) / Double(bitmap.pixelsWide * bitmap.pixelsHigh)
        XCTAssertGreaterThan(coloredFraction, 0.1, "The add button must show its colored fill, not just a native menu icon.")
    }
}
