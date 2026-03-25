import SwiftUI

struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.branch")
                            .font(.title)
                            .foregroundStyle(.blue)
                        Text("Digit Help")
                            .font(.title.bold())
                    }
                    Text("Git branch comparison dashboard for macOS")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Divider()

                // Getting Started
                HelpSection(title: "Getting Started", icon: "play.circle") {
                    HelpStep(number: 1, text: "Open Settings from the sidebar")
                    HelpStep(number: 2, text: "Click \"Discover Repos\" to find local repos, or \"Add Manually\"")
                    HelpStep(number: 3, text: "Select a repository from the sidebar to view its branches")
                    HelpStep(number: 4, text: "Configure base branches in Settings (e.g. main, develop, staging)")
                }

                // Grid
                HelpSection(title: "Branch Grid", icon: "tablecells") {
                    Text("Each row is a remote branch. Each column is a base branch you're comparing against.")
                        .helpBody()

                    VStack(alignment: .leading, spacing: 8) {
                        HelpBadge(
                            icon: "checkmark",
                            iconColor: .green,
                            background: .green,
                            text: "Branch is fully merged into the base"
                        )
                        HelpBadge(
                            icon: "arrow.up",
                            iconColor: .red,
                            background: .red,
                            text: "Branch is N commits ahead of the base"
                        )
                        HelpBadge(
                            icon: "arrow.up.right.square",
                            iconColor: .blue,
                            background: .blue,
                            text: "Click to open GitHub comparison view"
                        )
                    }
                }

                // Filtering
                HelpSection(title: "Filtering Branches", icon: "line.3.horizontal.decrease.circle") {
                    Text("Build a multi-select filter to focus on specific branches:")
                        .helpBody()
                    HelpStep(number: 1, text: "Type in the search field to find branches")
                    HelpStep(number: 2, text: "Click a branch from the dropdown to add it")
                    HelpStep(number: 3, text: "Repeat to add more branches")
                    HelpStep(number: 4, text: "Click the x on a chip to remove it, or the clear button to reset")
                    Text("Filters are saved per-repository and persist across sessions.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }

                // Base Branches
                HelpSection(title: "Base Branches", icon: "plus.circle") {
                    VStack(alignment: .leading, spacing: 6) {
                        HelpItem(icon: "plus", text: "Click the + in the grid header to add a base branch")
                        HelpItem(icon: "xmark", text: "Hover a base branch header and click x to remove it")
                    }
                    Text("Base branches are the branches you want to compare all other branches against (e.g. main, develop, staging).")
                        .helpBody()
                        .padding(.top, 2)
                }

                // Expanding Commits
                HelpSection(title: "Commit Details", icon: "list.bullet.indent") {
                    Text("Click the chevron next to a branch name to expand and see individual commits.")
                        .helpBody()
                    VStack(alignment: .leading, spacing: 6) {
                        HelpItem(icon: "checkmark.circle.fill", text: "Commit is present in the base branch")
                        HelpItem(icon: "xmark.circle.fill", text: "Commit is not yet in the base branch")
                    }
                    Text("Commit hashes are clickable links to GitHub when a GitHub URL is configured.")
                        .helpBody()
                        .padding(.top, 2)
                }

                // Sorting
                HelpSection(title: "Sorting", icon: "arrow.up.arrow.down") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("**A \u{2192} Z / Z \u{2192} A** — Alphabetical by branch name")
                            .helpBody()
                        Text("**Newest First / Oldest First** — By most recent commit date")
                            .helpBody()
                    }
                }

                // Hiding
                HelpSection(title: "Hiding Branches", icon: "eye.slash") {
                    VStack(alignment: .leading, spacing: 6) {
                        HelpItem(icon: "eye.slash", text: "Click the eye icon on a row to hide that branch")
                        HelpItem(icon: "eye", text: "Use View > Show All Branches to unhide everything")
                        HelpItem(icon: "archivebox", text: "Use View > Hide Feature Branches to hide all feature/* branches")
                    }
                    Text("Hidden branches appear in a bar at the bottom and can be restored individually.")
                        .helpBody()
                        .padding(.top, 2)
                }

                // Column Resizing
                HelpSection(title: "Column Resizing", icon: "arrow.left.and.right") {
                    Text("Drag the border between any column headers to resize columns.")
                        .helpBody()
                }

                // Keyboard Shortcuts
                HelpSection(title: "Keyboard Shortcuts", icon: "keyboard") {
                    HStack(spacing: 12) {
                        Text("Cmd+R")
                            .font(.system(.caption, design: .monospaced))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.quaternary)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        Text("Refresh — fetch from remote and reload branches")
                            .helpBody()
                    }
                }

                // GitHub Integration
                HelpSection(title: "GitHub Integration", icon: "link") {
                    Text("When a GitHub URL is configured for a repository:")
                        .helpBody()
                    VStack(alignment: .leading, spacing: 6) {
                        HelpItem(icon: "arrow.triangle.branch", text: "Branch names link to the branch on GitHub")
                        HelpItem(icon: "number", text: "Commit hashes link to the commit on GitHub")
                        HelpItem(icon: "arrow.up.right.square", text: "Comparison badges link to the GitHub compare view")
                    }
                    Text("Requires the GitHub CLI (gh) for repo discovery. Install from cli.github.com.")
                        .helpBody()
                        .padding(.top, 2)
                }

                Spacer(minLength: 20)
            }
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Help Components

private struct HelpSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.headline)
            content()
        }
    }
}

private struct HelpStep: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)")
                .font(.caption2.bold())
                .foregroundStyle(.white)
                .frame(width: 18, height: 18)
                .background(.blue)
                .clipShape(Circle())
            Text(text)
                .helpBody()
        }
    }
}

private struct HelpItem: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 16)
            Text(text)
                .helpBody()
        }
    }
}

private struct HelpBadge: View {
    let icon: String
    let iconColor: Color
    let background: Color
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption2.bold())
                .foregroundStyle(iconColor)
                .padding(4)
                .background(background.opacity(0.15))
                .clipShape(Capsule())
            Text(text)
                .helpBody()
        }
    }
}

private extension Text {
    func helpBody() -> some View {
        self.font(.callout).foregroundStyle(.secondary)
    }
}
