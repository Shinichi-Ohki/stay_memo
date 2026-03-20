import Foundation
import SwiftUI

@Observable
final class MemoStore {
    static let shared = MemoStore()

    var pages: [String] = ["", "", ""]
    var currentPage: Int = 0
    var isPinned: Bool = false
    var fontName: String = "Menlo"
    var fontSize: Double = 14

    var currentText: String {
        get { pages[currentPage] }
        set {
            pages[currentPage] = newValue
            save()
        }
    }

    var font: NSFont {
        NSFont(name: fontName, size: fontSize) ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
    }

    private let defaults = UserDefaults.standard

    private init() {
        load()
    }

    func save() {
        defaults.set(pages, forKey: "memo_pages")
        defaults.set(currentPage, forKey: "memo_currentPage")
        defaults.set(isPinned, forKey: "memo_isPinned")
        defaults.set(fontName, forKey: "memo_fontName")
        defaults.set(fontSize, forKey: "memo_fontSize")
    }

    private func load() {
        if let saved = defaults.stringArray(forKey: "memo_pages") {
            pages = saved
            // Ensure we always have exactly 3 pages
            while pages.count < 3 { pages.append("") }
        }
        currentPage = defaults.integer(forKey: "memo_currentPage")
        if currentPage < 0 || currentPage > 2 { currentPage = 0 }
        isPinned = defaults.bool(forKey: "memo_isPinned")
        if let name = defaults.string(forKey: "memo_fontName") {
            fontName = name
        }
        let size = defaults.double(forKey: "memo_fontSize")
        if size > 0 { fontSize = size }
    }
}
