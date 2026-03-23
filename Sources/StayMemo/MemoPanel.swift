import AppKit
import SwiftUI

class MemoPanel: NSPanel {
    private let store = MemoStore.shared
    private var globalClickMonitor: Any?

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
        hidesOnDeactivate = false

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

        // Global monitor: always active, checks visibility/pin in callback
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self = self, self.isVisible, !self.store.isPinned else { return }
            self.dismiss()
        }
    }

    deinit {
        if let monitor = globalClickMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    /// Hide the panel without closing, preserving frame and forcing text redraw on reopen
    func dismiss() {
        saveFrame()
        // Clear text selection without changing first responder
        clearTextSelection(in: contentView)
        orderOut(nil)
    }

    func clearTextSelection() {
        clearTextSelection(in: contentView)
    }

    private func clearTextSelection(in view: NSView?) {
        guard let view = view else { return }
        if let textView = view as? NSTextView {
            textView.setSelectedRange(NSRange(location: textView.selectedRange().location, length: 0))
        }
        for subview in view.subviews {
            clearTextSelection(in: subview)
        }
    }

    func saveFrame() {
        UserDefaults.standard.set(NSStringFromRect(frame), forKey: "memo_windowFrame")
    }

    override func close() {
        saveFrame()
        super.close()
    }

    func updatePinState() {
        if store.isPinned {
            level = .floating
        } else {
            level = .floating
        }
    }

    override var canBecomeKey: Bool { true }
}
