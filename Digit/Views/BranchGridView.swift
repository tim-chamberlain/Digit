import SwiftUI

struct BranchGridView: View {
    @Environment(RepoViewModel.self) private var viewModel

    var body: some View {
        @Bindable var vm = viewModel

        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 12) {
                // Filter
                BranchFilterField()

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
            GeometryReader { geo in
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
                    .frame(minWidth: geo.size.width, minHeight: geo.size.height, alignment: .topLeading)
                }
            }

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
    @Environment(RepoStore.self) private var repoStore

    private var availableBranches: [String] {
        let existing = Set(viewModel.baseBranches)
        return viewModel.branches
            .map(\.displayName)
            .filter { !existing.contains($0) }
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    var body: some View {
        @Bindable var vm = viewModel

        HStack(spacing: 0) {
            Text("Branch")
                .frame(width: viewModel.branchColumnWidth, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            ColumnResizeHandle(width: $vm.branchColumnWidth, minWidth: 150)

            Text("Author")
                .frame(width: viewModel.authorColumnWidth, alignment: .leading)
                .padding(.horizontal, 8)

            ColumnResizeHandle(width: $vm.authorColumnWidth, minWidth: 60)

            Text("Date Range")
                .frame(width: viewModel.dateColumnWidth, alignment: .leading)
                .padding(.horizontal, 8)

            ColumnResizeHandle(width: $vm.dateColumnWidth, minWidth: 100)

            ForEach(viewModel.baseBranches, id: \.self) { base in
                BaseBranchHeader(name: base) {
                    viewModel.removeBaseBranch(base, repoStore: repoStore)
                }
                .frame(width: viewModel.baseColumnWidth)

                ColumnResizeHandle(width: $vm.baseColumnWidth, minWidth: 60)
            }

            Menu {
                ForEach(availableBranches, id: \.self) { branch in
                    Button(branch) {
                        viewModel.addBaseBranch(branch, repoStore: repoStore)
                    }
                }
            } label: {
                Image(systemName: "plus")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            Spacer(minLength: 0)
        }
        .fixedSize(horizontal: false, vertical: true)
        .font(.caption.bold())
        .foregroundStyle(.secondary)
        .background(.quaternary.opacity(0.3))
    }
}

struct BaseBranchHeader: View {
    let name: String
    let onRemove: () -> Void
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 2) {
            Text(name)
            if isHovering {
                Button {
                    onRemove()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 4)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

struct BranchFilterField: View {
    @Environment(RepoViewModel.self) private var viewModel
    @Environment(RepoStore.self) private var repoStore
    @State private var showDropdown = false
    @State private var searchText = ""

    private var matchingBranches: [Branch] {
        let nonHidden = viewModel.branches.filter { !viewModel.hiddenBranches.contains($0.name) }
        let unselected = nonHidden.filter { !viewModel.selectedFilterBranches.contains($0.name) }
        if searchText.isEmpty {
            return unselected.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
        }
        let terms = searchText.lowercased().components(separatedBy: " ").filter { !$0.isEmpty }
        return unselected.filter { branch in
            let name = branch.displayName.lowercased()
            return terms.allSatisfy { name.contains($0) }
        }
        .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    private var selectedBranchObjects: [Branch] {
        viewModel.branches
            .filter { viewModel.selectedFilterBranches.contains($0.name) }
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    var body: some View {
        HStack(spacing: 6) {
            // Selected branch chips
            ForEach(selectedBranchObjects) { branch in
                HStack(spacing: 3) {
                    Text(branch.displayName)
                        .font(.caption2)
                        .lineLimit(1)
                    Button {
                        viewModel.toggleFilterBranch(branch, repoStore: repoStore)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 7, weight: .bold))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(.blue.opacity(0.12))
                .foregroundStyle(.blue)
                .clipShape(Capsule())
            }

            // Search field
            Image(systemName: "magnifyingglass")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField("Filter branches...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.callout)
                .onChange(of: searchText) { _, newValue in
                    if !newValue.isEmpty {
                        showDropdown = true
                    }
                    viewModel.filterText = newValue
                }
                .onTapGesture {
                    showDropdown = true
                }

            if !viewModel.selectedFilterBranches.isEmpty || !searchText.isEmpty {
                Button {
                    viewModel.clearFilter(repoStore: repoStore)
                    searchText = ""
                    showDropdown = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.quaternary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .popover(isPresented: $showDropdown) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(matchingBranches) { branch in
                        Button {
                            viewModel.toggleFilterBranch(branch, repoStore: repoStore)
                            searchText = ""
                            viewModel.filterText = ""
                        } label: {
                            HStack(spacing: 6) {
                                Text(branch.displayName)
                                    .font(.callout)
                                    .foregroundStyle(.primary)
                                Spacer()
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(width: 300, height: min(CGFloat(matchingBranches.count) * 28 + 8, 300))
            .padding(.vertical, 4)
        }
    }
}

struct ColumnResizeHandle: View {
    @Binding var width: CGFloat
    let minWidth: CGFloat
    @State private var isDragging = false
    @State private var startWidth: CGFloat = 0

    var body: some View {
        Color(isDragging ? .controlAccentColor : .separatorColor)
            .frame(width: isDragging ? 2 : 1)
            .padding(.horizontal, 2)
            .contentShape(Rectangle().inset(by: -3))
            .onHover { hovering in
                if hovering {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            startWidth = width
                        }
                        width = max(minWidth, startWidth + value.translation.width)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
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
