import SwiftUI

struct SettingsView: View {
    @State private var store = MemoStore.shared
    @State private var availableFonts: [String] = []

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    var body: some View {
        Form {
            Section("フォント") {
                Picker("フォント", selection: Binding(
                    get: { store.fontName },
                    set: {
                        store.fontName = $0
                        store.save()
                    }
                )) {
                    ForEach(availableFonts, id: \.self) { name in
                        Text(name).tag(name)
                    }
                }

                HStack {
                    Text("サイズ")
                    Slider(
                        value: Binding(
                            get: { store.fontSize },
                            set: {
                                store.fontSize = $0
                                store.save()
                            }
                        ),
                        in: 8...36,
                        step: 1
                    )
                    Text("\(Int(store.fontSize))pt")
                        .monospacedDigit()
                        .frame(width: 40, alignment: .trailing)
                }
            }

            Section("プレビュー") {
                Text("あいうえお ABCDE 12345")
                    .font(.custom(store.fontName, size: store.fontSize))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(4)
            }

            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Text("StayMemo")
                            .font(.headline)
                        Text("Version \(appVersion)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 350, height: 300)
        .onAppear {
            availableFonts = NSFontManager.shared.availableFontFamilies.sorted()
        }
    }
}
