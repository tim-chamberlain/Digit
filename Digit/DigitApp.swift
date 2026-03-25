import SwiftUI

@main
struct DigitApp: App {
    @State private var repoStore = RepoStore()
    @State private var viewModel = RepoViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(repoStore)
                .environment(viewModel)
        }
        .defaultSize(width: 1200, height: 800)
        .commands {
            CommandGroup(replacing: .help) {
                Button("Digit Help") {
                    showHelp()
                }
                .keyboardShortcut("?", modifiers: .command)
            }
        }
    }

    @FocusedBinding(\.sidebarSelection) private var selection

    private func showHelp() {
        selection = .help
    }
}
