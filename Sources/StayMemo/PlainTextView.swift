import SwiftUI
import AppKit

fileprivate class InvisibleLayoutManager: NSLayoutManager {
    var showInvisibles = false
    var invisiblesColor: NSColor = .systemGray

    // Returns a visible marker symbol for an invisible Unicode character, nil for normal chars.
    private func invisibleSymbol(for c: unichar) -> String? {
        switch c {
        // ── Standard whitespace ──────────────────────────────────────────────
        case 0x0009: return "→"   // CHARACTER TABULATION
        case 0x000A: return "¶"   // LINE FEED
        case 0x000B: return "↕"   // LINE TABULATION (vertical tab)
        case 0x000C: return "↡"   // FORM FEED
        case 0x000D: return "↵"   // CARRIAGE RETURN
        case 0x0020: return "·"   // SPACE

        // ── Space variants (various widths) ──────────────────────────────────
        case 0x00A0: return "·"   // NO-BREAK SPACE
        case 0x1680: return "·"   // OGHAM SPACE MARK
        case 0x2000...0x200A: return "·"  // EN QUAD … HAIR SPACE (11 kinds)
        case 0x202F: return "·"   // NARROW NO-BREAK SPACE
        case 0x205F: return "·"   // MEDIUM MATHEMATICAL SPACE
        case 0x3000: return "·"   // IDEOGRAPHIC SPACE
        case 0x2800: return "·"   // BRAILLE PATTERN BLANK
        case 0x3164: return "·"   // HANGUL FILLER
        case 0xFFA0: return "·"   // HALFWIDTH HANGUL FILLER

        // ── Zero-width / truly invisible (prompt-injection risk) ─────────────
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

        // ── Directional formatting (RTL override, bidi spoofing) ─────────────
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
        case 0x206A...0x206F: return "⇄"  // INHIBIT/ACTIVATE SWAPPING & SHAPING

        default: return nil
        }
    }

    override func drawGlyphs(forGlyphRange glyphsToShow: NSRange, at origin: NSPoint) {
        super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)
        guard showInvisibles, let textStorage = textStorage else { return }

        let string = textStorage.string as NSString
        let charRange = characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)

        var charIndex = charRange.location
        while charIndex < NSMaxRange(charRange) {
            let c = string.character(at: charIndex)
            let symbol: String
            let charLength: Int

            // Tags block U+E0000–U+E007F: surrogate pair high=0xDB40, low=0xDC00–0xDC7F.
            // Each tag character encodes an ASCII character at (low - 0xDC00).
            // Decode and show the hidden ASCII so injection payloads become readable.
            if c == 0xDB40, charIndex + 1 < NSMaxRange(charRange) {
                let low = string.character(at: charIndex + 1)
                guard low >= 0xDC00 && low <= 0xDC7F else { charIndex += 1; continue }
                let offset = Int(low - 0xDC00)
                switch offset {
                case 0x20:        symbol = "·"                              // TAG SPACE
                case 0x21...0x7E: symbol = String(UnicodeScalar(offset)!)   // TAG printable ASCII → decoded char
                default:          symbol = "∅"                              // LANGUAGE TAG / CANCEL TAG
                }
                charLength = 2
            } else if let s = invisibleSymbol(for: c) {
                symbol = s
                charLength = 1
            } else {
                charIndex += 1
                continue
            }

            drawInvisible(symbol, atChar: charIndex, length: charLength,
                          string: string, textStorage: textStorage, origin: origin)
            charIndex += charLength
        }
    }

    private func drawInvisible(_ symbol: String, atChar charIndex: Int, length charLength: Int,
                               string: NSString, textStorage: NSTextStorage, origin: NSPoint) {
        // Resolve a glyph index for the character; fall back to the next character if zero-width.
        var glyphIndex: Int?
        let gr = glyphRange(forCharacterRange: NSRange(location: charIndex, length: charLength),
                            actualCharacterRange: nil)
        if gr.location != NSNotFound && gr.location < numberOfGlyphs {
            glyphIndex = gr.location
        } else {
            let nextChar = charIndex + charLength
            if nextChar < string.length {
                let gr2 = glyphRange(forCharacterRange: NSRange(location: nextChar, length: 1),
                                     actualCharacterRange: nil)
                if gr2.location != NSNotFound && gr2.location < numberOfGlyphs {
                    glyphIndex = gr2.location
                }
            }
        }
        guard let gi = glyphIndex else { return }

        let lineRect = lineFragmentRect(forGlyphAt: gi, effectiveRange: nil)
        guard lineRect != .zero else { return }
        let glyphLoc = location(forGlyphAt: gi)

        let font = textStorage.attribute(.font, at: charIndex, effectiveRange: nil) as? NSFont
            ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)

        // Badge style: filled background in invisiblesColor, symbol in contrasting color.
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
        let luminance = 0.2126 * c.redComponent + 0.7152 * c.greenComponent + 0.0722 * c.blueComponent
        return luminance > 0.5 ? .black : .white
    }
}

struct PlainTextView: NSViewRepresentable {
    @Binding var text: String
    var font: NSFont
    var showInvisibles: Bool
    var invisiblesColor: NSColor

    func makeNSView(context: Context) -> NSScrollView {
        let textStorage = NSTextStorage()
        let layoutManager = InvisibleLayoutManager()
        layoutManager.showInvisibles = showInvisibles
        layoutManager.invisiblesColor = invisiblesColor
        context.coordinator.layoutManager = layoutManager

        let textContainer = NSTextContainer(
            size: CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        )
        textContainer.widthTracksTextView = true
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        let scrollView = NSScrollView(frame: .zero)
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        let contentSize = scrollView.contentSize
        let textView = NSTextView(
            frame: NSRect(origin: .zero, size: contentSize),
            textContainer: textContainer
        )
        textView.minSize = NSSize(width: 0, height: contentSize.height)
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = .width
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.font = font
        textView.textColor = .textColor
        textView.string = text
        textView.delegate = context.coordinator
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.backgroundColor = .textBackgroundColor
        textView.insertionPointColor = .textColor

        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let textView = scrollView.documentView as! NSTextView
        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
        }
        textView.font = font
        textView.textColor = .textColor

        if let lm = context.coordinator.layoutManager {
            let needsRedraw = lm.showInvisibles != showInvisibles || lm.invisiblesColor != invisiblesColor
            lm.showInvisibles = showInvisibles
            lm.invisiblesColor = invisiblesColor
            if needsRedraw {
                textView.setNeedsDisplay(textView.bounds)
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: PlainTextView
        fileprivate weak var layoutManager: InvisibleLayoutManager?

        init(_ parent: PlainTextView) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}
