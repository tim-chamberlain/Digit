import SwiftUI

struct ComparisonCellView: View {
    @Environment(RepoViewModel.self) private var viewModel
    let branch: Branch
    let baseBranch: String

    var body: some View {
        Group {
            if let entry = viewModel.gridEntry(for: branch) {
                let aheadCount = entry.commitsAhead(of: baseBranch)
                let partialCount = entry.commitsPartial(for: baseBranch, allBases: viewModel.baseBranches)

                if aheadCount == 0 && partialCount == 0 {
                    // Fully merged, no partials — green checkmark
                    Image(systemName: "checkmark")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.green.opacity(0.1))
                        .clipShape(Capsule())
                } else {
                    HStack(spacing: 4) {
                        if aheadCount > 0 {
                            // Ahead — red badge
                            HStack(spacing: 2) {
                                Image(systemName: "arrow.up")
                                    .font(.caption2)
                                Text("\(aheadCount)")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.red.opacity(0.1))
                            .clipShape(Capsule())

                            if let url = viewModel.githubCompareURL(branch: branch, base: baseBranch) {
                                Link(destination: url) {
                                    Image(systemName: "arrow.up.right.square")
                                        .font(.caption2)
                                        .foregroundStyle(.blue)
                                }
                                .help("Open PR comparison on GitHub")
                            }
                        } else if partialCount > 0 {
                            // Fully in this base but partial across others — blue badge
                            Text("\(partialCount)")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.blue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.blue.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            } else {
                Text("—")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
