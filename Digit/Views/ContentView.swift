import SwiftUI

enum SidebarItem: Hashable {
    case repo(UUID)
    case settings
    case help
}

struct SidebarSelectionKey: FocusedValueKey {
    typealias Value = Binding<SidebarItem?>
}

extension FocusedValues {
    var sidebarSelection: Binding<SidebarItem?>? {
        get { self[SidebarSelectionKey.self] }
        set { self[SidebarSelectionKey.self] = newValue }
    }
}

struct ContentView: View {
    @Environment(RepoStore.self) private var repoStore
    @Environment(RepoViewModel.self) private var viewModel
    @State private var selection: SidebarItem?

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
        } detail: {
            switch selection {
            case .repo:
                if viewModel.repo != nil {
                    VStack(spacing: 0) {
                        HeaderView()
                        Divider()
                        BranchGridView()
                    }
                }
            case .settings:
                SettingsView()
            case .help:
                HelpView()
            case nil:
                VStack(spacing: 12) {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)
                    Text("Select a repository")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    if repoStore.repos.isEmpty {
                        Text("Add a repository in Settings")
                            .font(.callout)
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .focusedSceneValue(\.sidebarSelection, $selection)
        .onChange(of: selection) { _, newValue in
            if case .repo(let id) = newValue,
               let repo = repoStore.repos.first(where: { $0.id == id }) {
                viewModel.selectRepo(repo)
            }
        }
    }
}
