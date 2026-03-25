import SwiftUI

struct SidebarView: View {
    @Environment(RepoStore.self) private var repoStore
    @Environment(RepoViewModel.self) private var viewModel
    @Binding var selection: SidebarItem?

    var body: some View {
        List(selection: $selection) {
            if !repoStore.repos.isEmpty {
                Section("Repositories") {
                    ForEach(repoStore.repos) { repo in
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(repo.name)
                                    .fontWeight(.medium)
                                Text(repo.path)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        } icon: {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(.blue)
                        }
                        .tag(SidebarItem.repo(repo.id))
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Digit")
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Button {
                    selection = .help
                } label: {
                    Label("Help", systemImage: "questionmark.circle")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .foregroundStyle(selection == .help ? Color.accentColor : .primary)
                .background(selection == .help ? Color.accentColor.opacity(0.15) : Color.clear)

                Button {
                    selection = .settings
                } label: {
                    Label("Settings", systemImage: "gear")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .foregroundStyle(selection == .settings ? Color.accentColor : .primary)
                .background(selection == .settings ? Color.accentColor.opacity(0.15) : Color.clear)
            }
        }
    }
}
