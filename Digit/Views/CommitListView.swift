import SwiftUI

struct CommitListView: View {
    @Environment(RepoViewModel.self) private var viewModel
    let branch: Branch

    var body: some View {
        let entry = viewModel.gridEntry(for: branch)
        let commitsWithBases = entry?.commits.prefix(20) ?? []

        VStack(spacing: 0) {
            ForEach(Array(commitsWithBases)) { cwb in
                HStack(spacing: 0) {
                    HStack(spacing: 10) {
                        // Hash
                        if let url = viewModel.githubCommitURL(cwb.commit) {
                            Link(destination: url) {
                                Text(cwb.commit.shortHash)
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundStyle(.blue)
                            }
                        } else {
                            Text(cwb.commit.shortHash)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }

                        // Author
                        Text(cwb.commit.author)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 100, alignment: .leading)
                            .lineLimit(1)

                        // Date
                        Text(cwb.commit.relativeDate)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .frame(width: 100, alignment: .leading)

                        // Message
                        Text(cwb.commit.message)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .padding(.leading, 44)
                    .padding(.vertical, 4)

                    Spacer(minLength: 0)

                    // Per-base-branch indicators
                    ForEach(viewModel.baseBranches, id: \.self) { base in
                        commitBaseIndicator(cwb: cwb, base: base)
                            .frame(width: 100)
                            .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 12)

                if cwb.id != commitsWithBases.last?.id {
                    Divider().opacity(0.2).padding(.leading, 44)
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func commitBaseIndicator(cwb: CommitWithBases, base: String) -> some View {
        if cwb.isInBase(base) {
            // Commit is in this base
            Image(systemName: "checkmark")
                .font(.system(size: 8))
                .foregroundStyle(.green.opacity(0.6))
        } else {
            // Commit is NOT in this base (ahead)
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .foregroundStyle(.red.opacity(0.6))
        }
    }
}
