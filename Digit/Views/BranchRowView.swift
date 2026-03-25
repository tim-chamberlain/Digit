import SwiftUI

struct BranchRowView: View {
    @Environment(RepoViewModel.self) private var viewModel
    let branch: Branch

    var body: some View {
        HStack(spacing: 0) {
            // Branch name + actions
            HStack(spacing: 6) {
                // Expand toggle
                Button {
                    viewModel.toggleExpanded(branch)
                } label: {
                    Image(systemName: viewModel.expandedBranches.contains(branch.name) ? "chevron.down" : "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 14)
                }
                .buttonStyle(.plain)

                // Hide button
                Button {
                    withAnimation {
                        viewModel.hideBranch(branch)
                    }
                } label: {
                    Image(systemName: "eye.slash")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .help("Hide branch")

                // Branch name
                if let url = viewModel.githubBranchURL(branch) {
                    Link(destination: url) {
                        branchNameText
                    }
                } else {
                    branchNameText
                }
            }
            .frame(width: viewModel.branchColumnWidth, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Spacer().frame(width: 5) // match resize handle

            // Author
            Text(branch.author)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(width: viewModel.authorColumnWidth, alignment: .leading)
                .padding(.horizontal, 8)

            Spacer().frame(width: 5) // match resize handle

            // Date range
            dateRangeView
                .frame(width: viewModel.dateColumnWidth, alignment: .leading)
                .padding(.horizontal, 8)

            Spacer().frame(width: 5) // match resize handle

            // Comparison cells
            ForEach(viewModel.baseBranches, id: \.self) { base in
                ComparisonCellView(branch: branch, baseBranch: base)
                    .frame(width: viewModel.baseColumnWidth)
                    .padding(.horizontal, 4)

                Spacer().frame(width: 5) // match resize handle
            }

            Spacer(minLength: 0)
        }
    }

    private var branchNameText: some View {
        Text(branch.displayName)
            .font(.system(.callout, design: .monospaced))
            .fontWeight(.medium)
            .lineLimit(1)
    }

    @ViewBuilder
    private var dateRangeView: some View {
        if let oldest = branch.oldestCommitDate, let newest = branch.newestCommitDate {
            VStack(alignment: .leading, spacing: 1) {
                Text(newest, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if oldest != newest {
                    Text(oldest, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        } else {
            Text("—")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}
