import SwiftUI
import tdgCoreMain

struct GeneralPreferencesView: View {
    @Environment(CloudPreferences.self) private var preferences
    @State private var prefixInput: String = ""

    private var exampleShortId: String {
        let sampleHex = "A1B2C3D4"
        let validated = ShortIdHelper.validatePrefix(prefixInput)
        return "\(validated)-\(sampleHex)"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    Image(systemName: imgGearshapeFill)
                        .foregroundStyle(Color.priority)
                        .font(.title2)
                    Text("General Preferences")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.priority)
                }
                .padding(.bottom, 10)

                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Short ID Prefix")
                            .font(.headline)

                        Text("Tasks get a short identifier like **\(exampleShortId)** for use in commit messages, AI tools, and cross-references. The prefix distinguishes this installation from others (e.g. personal vs. business).")
                            .font(.callout)
                            .foregroundStyle(.secondary)

                        HStack {
                            TextField("Prefix", text: $prefixInput)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 120)
                                .autocorrectionDisabled()
                            #if os(iOS)
                                .textInputAutocapitalization(.characters)
                            #endif
                                .onChange(of: prefixInput) { _, newValue in
                                    let validated = ShortIdHelper.validatePrefix(newValue)
                                    if validated != preferences.shortIdPrefix {
                                        preferences.shortIdPrefix = validated
                                    }
                                }

                            Text("→  \(exampleShortId)")
                                .font(.body.monospaced())
                                .foregroundStyle(.secondary)
                        }

                        Text("2–5 letters, automatically uppercased. Default: \(ShortIdHelper.defaultPrefix)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(5)
                } label: {
                    Label("Short ID", systemImage: imgSearch)
                }
            }
            .padding(20)
        }
        .onAppear {
            prefixInput = preferences.shortIdPrefix
        }
    }
}

#Preview {
    let appComponents = setupApp(isTesting: true)
    GeneralPreferencesView()
        .environment(appComponents.preferences)
}
