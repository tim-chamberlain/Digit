import SwiftUI

struct HeaderView: View {
    @Environment(RepoViewModel.self) private var viewModel

    var body: some View {
        HStack(spacing: 16) {
            // Repo name
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.branch")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Text(viewModel.repo?.name ?? "")
                    .font(.title2.bold())
            }

            // Status badge
            statusBadge

            Spacer()

            // Last fetch
            if let lastFetch = viewModel.lastFetchTime {
                Text("Fetched \(lastFetch, style: .relative) ago")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Refresh button
            Button {
                let vm = viewModel
                Task { await vm.refresh() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .controlSize(.small)
            .disabled(viewModel.loadState == .fetching || viewModel.loadState == .loading)
            .keyboardShortcut("r", modifiers: .command)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(.bar)
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch viewModel.loadState {
        case .idle:
            EmptyView()
        case .loading:
            HStack(spacing: 6) {
                ProgressView().controlSize(.small)
                Text("Loading")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.quaternary.opacity(0.5))
            .clipShape(Capsule())
        case .fetching:
            HStack(spacing: 6) {
                ProgressView().controlSize(.small)
                Text("Fetching")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.quaternary.opacity(0.5))
            .clipShape(Capsule())
        case .loaded:
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2)
                Text("Ready")
                    .font(.caption)
            }
            .foregroundStyle(.green)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.green.opacity(0.1))
            .clipShape(Capsule())
        case .error(let msg):
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2)
                Text(msg)
                    .font(.caption)
                    .lineLimit(1)
            }
            .foregroundStyle(.red)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.red.opacity(0.1))
            .clipShape(Capsule())
        }
    }
}
