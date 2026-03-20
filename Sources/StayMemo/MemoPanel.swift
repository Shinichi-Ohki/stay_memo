import AppKit
import SwiftUI

class MemoPanel: NSPanel {
    private let store = MemoStore.shared

    init() {
        let width: CGFloat = 360
        let height: CGFloat = 320
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel, .utilityWindow],
            backing: .buffered,
            defer: false
        )

        title = "StayMemo"
        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isMovableByWindowBackground = true
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        animationBehavior = .utilityWindow
        isReleasedWhenClosed = false

        // Restore saved frame
        if let frameStr = UserDefaults.standard.string(forKey: "memo_windowFrame"),
           !frameStr.isEmpty {
            let frame = NSRectFromString(frameStr)
            if frame.width > 0 && frame.height > 0 {
                setFrame(frame, display: false)
            }
        }

        let hostView = NSHostingView(rootView: MemoView(panel: self))
        contentView = hostView

        updatePinState()
    }

    func updatePinState() {
        let pinned = store.isPinned
        if pinned {
            level = .floating
            hidesOnDeactivate = false
        } else {
            level = .floating
            hidesOnDeactivate = true
        }
    }

    override func resignKey() {
        super.resignKey()
        if !store.isPinned {
            close()
        }
    }

    override func close() {
        // Save window frame before closing
        UserDefaults.standard.set(NSStringFromRect(frame), forKey: "memo_windowFrame")
        super.close()
    }

    override var canBecomeKey: Bool { true }
}
