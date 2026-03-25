import SwiftUI

struct ComparisonCellView: View {
    @Environment(RepoViewModel.self) private var viewModel
    let branch: Branch
    let baseBranch: String

    var body: some View {
        Group {
            if let entry = viewModel.gridEntry(for: branch) {
                let aheadCount = entry.commitsAhead(of: baseBranch)

                if aheadCount == 0 {
                    // Fully merged — green checkmark
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
