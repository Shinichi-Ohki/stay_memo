import SwiftUI
import AppKit

// Transparent overlay that draws invisible-character badges on top of the text view.
// Kept separate from NSTextView so the layout system (scrollableTextView) is untouched.
fileprivate class InvisibleOverlayView: NSView {
    weak var textView: NSTextView?
    var showInvisibles = false
    var invisiblesColor: NSColor = .systemGray

    override var isOpaque: Bool { false }
    override var isFlipped: Bool { true }   // match NSTextView's coordinate system
    override func hitTest(_ point: NSPoint) -> NSView? { nil }  // pass events through

    override func draw(_ dirtyRect: NSRect) {
        guard showInvisibles,
              let tv = textView,
              let lm = tv.layoutManager,
              let tc = tv.textContainer,
              let ts = tv.textStorage else { return }

        let origin = tv.textContainerOrigin
        // dirtyRect is in overlay (= text view) coords; convert to text-container coords for glyph lookup
        let containerRect = dirtyRect.offsetBy(dx: -origin.x, dy: -origin.y)
        let glyphRange = lm.glyphRange(forBoundingRect: containerRect, in: tc)
        let charRange = lm.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
        let string = ts.string as NSString

        var charIndex = charRange.location
        while charIndex < NSMaxRange(charRange) {
            let c = string.character(at: charIndex)
            let symbol: String
            let charLength: Int

            // Tags block U+E0000–U+E007F: surrogate pair high=0xDB40, low=0xDC00–0xDC7F.
            // Decode to show the hidden ASCII payload.
            if c == 0xDB40, charIndex + 1 < NSMaxRange(charRange) {
                let low = string.character(at: charIndex + 1)
                guard low >= 0xDC00 && low <= 0xDC7F else { charIndex += 1; continue }
                let offset = Int(low - 0xDC00)
                switch offset {
                case 0x20:        symbol = "·"
                case 0x21...0x7E: symbol = String(UnicodeScalar(offset)!)
                default:          symbol = "∅"
                }
                charLength = 2
            } else if let s = invisibleSymbol(for: c) {
                symbol = s
                charLength = 1
            } else {
                charIndex += 1
                continue
            }

            drawBadge(symbol, atChar: charIndex, charLength: charLength,
                      string: string, textStorage: ts, layoutManager: lm, origin: origin)
            charIndex += charLength
        }
    }

    private func drawBadge(_ symbol: String, atChar charIndex: Int, charLength: Int,
                            string: NSString, textStorage: NSTextStorage,
                            layoutManager lm: NSLayoutManager, origin: NSPoint) {
        var glyphIndex: Int?
        let gr = lm.glyphRange(forCharacterRange: NSRange(location: charIndex, length: charLength),
                               actualCharacterRange: nil)
        if gr.location != NSNotFound && gr.location < lm.numberOfGlyphs {
            glyphIndex = gr.location
        } else {
            // Zero-width chars have no glyph; anchor to the next character's position.
            let nextChar = charIndex + charLength
            if nextChar < string.length {
                let gr2 = lm.glyphRange(forCharacterRange: NSRange(location: nextChar, length: 1),
                                        actualCharacterRange: nil)
                if gr2.location != NSNotFound && gr2.location < lm.numberOfGlyphs {
                    glyphIndex = gr2.location
                }
            }
        }
        guard let gi = glyphIndex else { return }

        let lineRect = lm.lineFragmentRect(forGlyphAt: gi, effectiveRange: nil)
        guard lineRect != .zero else { return }
        let glyphLoc = lm.location(forGlyphAt: gi)

        let font = textStorage.attribute(.font, at: charIndex, effectiveRange: nil) as? NSFont
            ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
        let fg = contrastColor(for: invisiblesColor)
        let attrs: [NSAttributedString.Key: Any] = [.foregroundColor: fg, .font: font]
        let symSize = (symbol as NSString).size(withAttributes: attrs)
        let drawPoint = NSPoint(x: origin.x + lineRect.origin.x + glyphLoc.x,
                                y: origin.y + lineRect.origin.y)
        let bgRect = NSRect(x: drawPoint.x, y: drawPoint.y,
                            width: max(symSize.width, 4), height: symSize.height)
        invisiblesColor.withAlphaComponent(1.0).setFill()
        NSBezierPath(roundedRect: bgRect, xRadius: 2, yRadius: 2).fill()
        (symbol as NSString).draw(at: drawPoint, withAttributes: attrs)
    }

    private func contrastColor(for color: NSColor) -> NSColor {
        guard let c = color.usingColorSpace(.sRGB) else { return .white }
        let lum = 0.2126 * c.redComponent + 0.7152 * c.greenComponent + 0.0722 * c.blueComponent
        return lum > 0.5 ? .black : .white
    }

    private func invisibleSymbol(for c: unichar) -> String? {
        switch c {
        // ── Standard whitespace ──────────────────────────────────────────────
        case 0x0009: return "→"   // CHARACTER TABULATION
        case 0x000A: return "¶"   // LINE FEED
        case 0x000B: return "↕"   // LINE TABULATION
        case 0x000C: return "↡"   // FORM FEED
        case 0x000D: return "↵"   // CARRIAGE RETURN
        case 0x0020: return "·"   // SPACE

        // ── Space variants ───────────────────────────────────────────────────
        case 0x00A0: return "·"   // NO-BREAK SPACE
        case 0x1680: return "·"   // OGHAM SPACE MARK
        case 0x2000...0x200A: return "·"  // EN QUAD … HAIR SPACE
        case 0x202F: return "·"   // NARROW NO-BREAK SPACE
        case 0x205F: return "·"   // MEDIUM MATHEMATICAL SPACE
        case 0x3000: return "·"   // IDEOGRAPHIC SPACE
        case 0x2800: return "·"   // BRAILLE PATTERN BLANK
        case 0x3164: return "·"   // HANGUL FILLER
        case 0xFFA0: return "·"   // HALFWIDTH HANGUL FILLER

        // ── Zero-width / invisible (prompt-injection risk) ───────────────────
        case 0x00AD: return "∅"   // SOFT HYPHEN
        case 0x034F: return "∅"   // COMBINING GRAPHEME JOINER
        case 0x115F: return "∅"   // HANGUL CHOSEONG FILLER
        case 0x1160: return "∅"   // HANGUL JUNGSEONG FILLER
        case 0x17B4: return "∅"   // KHMER VOWEL INHERENT AQ
        case 0x17B5: return "∅"   // KHMER VOWEL INHERENT AA
        case 0x180B...0x180D: return "∅"  // MONGOLIAN FREE VARIATION SELECTORS
        case 0x180E: return "∅"   // MONGOLIAN VOWEL SEPARATOR
        case 0x200B: return "∅"   // ZERO WIDTH SPACE
        case 0x200C: return "∅"   // ZERO WIDTH NON-JOINER
        case 0x200D: return "∅"   // ZERO WIDTH JOINER
        case 0x2060: return "∅"   // WORD JOINER
        case 0x2061: return "∅"   // FUNCTION APPLICATION
        case 0x2062: return "∅"   // INVISIBLE TIMES
        case 0x2063: return "∅"   // INVISIBLE SEPARATOR
        case 0x2064: return "∅"   // INVISIBLE PLUS
        case 0xFEFF: return "∅"   // ZERO WIDTH NO-BREAK SPACE (BOM)
        case 0xFFFC: return "∅"   // OBJECT REPLACEMENT CHARACTER
        case 0xFFF9...0xFFFB: return "∅"  // INTERLINEAR ANNOTATION markers

        // ── Directional formatting (bidi spoofing) ───────────────────────────
        case 0x061C: return "⇄"   // ARABIC LETTER MARK
        case 0x200E: return "⇄"   // LEFT-TO-RIGHT MARK
        case 0x200F: return "⇄"   // RIGHT-TO-LEFT MARK
        case 0x202A: return "⇄"   // LEFT-TO-RIGHT EMBEDDING
        case 0x202B: return "⇄"   // RIGHT-TO-LEFT EMBEDDING
        case 0x202C: return "⇄"   // POP DIRECTIONAL FORMATTING
        case 0x202D: return "⇄"   // LEFT-TO-RIGHT OVERRIDE
        case 0x202E: return "⇄"   // RIGHT-TO-LEFT OVERRIDE
        case 0x2066: return "⇄"   // LEFT-TO-RIGHT ISOLATE
        case 0x2067: return "⇄"   // RIGHT-TO-LEFT ISOLATE
        case 0x2068: return "⇄"   // FIRST STRONG ISOLATE
        case 0x2069: return "⇄"   // POP DIRECTIONAL ISOLATE
        case 0x206A...0x206F: return "⇄"  // SWAPPING & SHAPING CONTROLS

        default: return nil
        }
    }
}

struct PlainTextView: NSViewRepresentable {
    @Binding var text: String
    var font: NSFont
    var showInvisibles: Bool
    var invisiblesColor: NSColor

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView

        let ps = NSMutableParagraphStyle()
        ps.defaultTabInterval = 28.0
        textView.defaultParagraphStyle = ps
        textView.typingAttributes[.paragraphStyle] = ps
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.font = font
        textView.string = text
        textView.delegate = context.coordinator
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.backgroundColor = .textBackgroundColor
        textView.insertionPointColor = .textColor

        let overlay = InvisibleOverlayView(frame: textView.bounds)
        overlay.autoresizingMask = [.width, .height]
        overlay.textView = textView
        overlay.showInvisibles = showInvisibles
        overlay.invisiblesColor = invisiblesColor
        textView.addSubview(overlay)
        context.coordinator.overlay = overlay

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let textView = scrollView.documentView as! NSTextView
        let textChanged = textView.string != text
        if textChanged {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
        }
        if textView.font != font {
            textView.font = font
        }

        if let overlay = context.coordinator.overlay {
            let colorChanged = overlay.showInvisibles != showInvisibles
                           || overlay.invisiblesColor != invisiblesColor
            overlay.showInvisibles = showInvisibles
            overlay.invisiblesColor = invisiblesColor
            if colorChanged || textChanged {
                overlay.needsDisplay = true
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: PlainTextView
        fileprivate weak var overlay: InvisibleOverlayView?

        init(_ parent: PlainTextView) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
            overlay?.needsDisplay = true
        }
    }
}
