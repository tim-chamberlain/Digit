import SwiftUI

struct BranchGridView: View {
    @Environment(RepoViewModel.self) private var viewModel

    var body: some View {
        @Bindable var vm = viewModel

        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 12) {
                // Filter
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Filter branches...", text: $vm.filterText)
                        .textFieldStyle(.plain)
                        .font(.callout)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.quaternary.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .frame(maxWidth: 250)

                // Sort
                Picker("Sort", selection: $vm.sortMode) {
                    ForEach(RepoViewModel.SortMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.menu)
                .controlSize(.small)
                .frame(width: 150)

                Spacer()

                // Branch visibility
                Menu {
                    Button("Show All Branches") { viewModel.showAllBranches() }
                    Button("Hide Feature Branches") { viewModel.hideFeatureBranches() }
                    Divider()
                    Button("Expand All Commits") { viewModel.expandAll() }
                    Button("Collapse All Commits") { viewModel.collapseAll() }
                } label: {
                    Label("View", systemImage: "eye")
                        .font(.caption)
                }
                .controlSize(.small)

                // Branch count badge
                Text("\(viewModel.filteredBranches.count) branches")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
            .background(.bar)

            Divider()

            // Grid
            ScrollView([.horizontal, .vertical]) {
                VStack(spacing: 0) {
                    GridHeaderRow()
                    Divider()

                    LazyVStack(spacing: 0) {
                        ForEach(Array(viewModel.filteredBranches.enumerated()), id: \.element.id) { index, branch in
                            VStack(spacing: 0) {
                                BranchRowView(branch: branch)
                                    .background(index % 2 == 0 ? Color.clear : Color.gray.opacity(0.04))

                                if viewModel.expandedBranches.contains(branch.name) {
                                    CommitListView(branch: branch)
                                        .background(Color.gray.opacity(0.06))
                                }

                                Divider().opacity(0.5)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Hidden branches
            if !viewModel.hiddenBranchList.isEmpty {
                Divider()
                HiddenBranchesBar()
            }
        }
    }
}

struct GridHeaderRow: View {
    @Environment(RepoViewModel.self) private var viewModel

    var body: some View {
        HStack(spacing: 0) {
            Text("Branch")
                .frame(width: 300, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            Text("Date Range")
                .frame(width: 180, alignment: .leading)
                .padding(.horizontal, 8)

            ForEach(viewModel.baseBranches, id: \.self) { base in
                Text(base)
                    .frame(width: 100, alignment: .center)
                    .padding(.horizontal, 4)
            }

            Spacer(minLength: 0)
        }
        .font(.caption.bold())
        .foregroundStyle(.secondary)
        .background(.quaternary.opacity(0.3))
    }
}

struct HiddenBranchesBar: View {
    @Environment(RepoViewModel.self) private var viewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                Text("Hidden:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(viewModel.hiddenBranchList) { branch in
                    Button {
                        viewModel.toggleBranchHidden(branch)
                    } label: {
                        HStack(spacing: 4) {
                            Text(branch.displayName)
                                .font(.caption2)
                            Image(systemName: "eye")
                                .font(.caption2)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(.plain)
                    .background(.quaternary.opacity(0.5))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 6)
        }
        .background(.bar)
    }
}
