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
    }
}
