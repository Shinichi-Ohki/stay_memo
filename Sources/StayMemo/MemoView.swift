import SwiftUI

struct MemoView: View {
    @State private var store = MemoStore.shared
    weak var panel: MemoPanel?

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar: page tabs + pin toggle
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Button(action: {
                        panel?.clearTextSelection()
                        store.currentPage = index
                        store.save()
                    }) {
                        Text("\(index + 1)")
                            .font(.system(size: 12, weight: store.currentPage == index ? .bold : .regular))
                            .frame(width: 28, height: 22)
                    }
                    .buttonStyle(.plain)
                    .background(store.currentPage == index ? Color.accentColor.opacity(0.2) : Color.clear)
                    .cornerRadius(4)
                    .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
                }

                Spacer()

                Button(action: {
                    store.showInvisibles.toggle()
                    store.save()
                }) {
                    Image(systemName: "paragraphsign")
                        .font(.system(size: 12))
                        .foregroundColor(store.showInvisibles ? .accentColor : .secondary)
                }
                .buttonStyle(.plain)
                .help(store.showInvisibles ? "非表示文字を隠す" : "非表示文字を表示")

                Button(action: {
                    store.isPinned.toggle()
                    store.save()
                    panel?.updatePinState()
                }) {
                    Image(systemName: store.isPinned ? "pin.fill" : "pin")
                        .font(.system(size: 12))
                        .foregroundColor(store.isPinned ? .accentColor : .secondary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("p", modifiers: .command)
                .help(store.isPinned ? "ピン留め解除 (⌘P)" : "ピン留め (⌘P)")
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)

            Divider()

            // Text editor
            PlainTextView(
                text: Binding(
                    get: { store.currentText },
                    set: { store.currentText = $0 }
                ),
                font: store.font,
                showInvisibles: store.showInvisibles,
                invisiblesColor: store.invisiblesNSColor
            )
        }
        .frame(minWidth: 250, minHeight: 150)
    }
}
