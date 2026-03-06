import SwiftUI

struct SettingsView: View {
    @Environment(RepoStore.self) private var repoStore
    @Environment(RepoViewModel.self) private var viewModel
    @State private var showingAddSheet = false
    @State private var showingDiscovery = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Text("Settings")
                        .font(.largeTitle.bold())
                    Spacer()
                }

                // Repositories section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Repositories")
                            .font(.title2.bold())
                        Spacer()
                        Button {
                            showingDiscovery = true
                        } label: {
                            Label("Discover Repos", systemImage: "magnifyingglass")
                        }
                        .controlSize(.small)

                        Button {
                            showingAddSheet = true
                        } label: {
                            Label("Add Manually", systemImage: "plus.circle")
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }

                    if repoStore.repos.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 32))
                                .foregroundStyle(.tertiary)
                            Text("No repositories configured")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                            Text("Discover repos from GitHub or add one manually")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(24)
                        .background(.quaternary.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        ForEach(repoStore.repos) { repo in
                            RepoSettingsCard(repo: repo)
                        }
                    }
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .sheet(isPresented: $showingAddSheet) {
            AddRepoSheet { newRepo in
                repoStore.add(newRepo)
            }
        }
        .sheet(isPresented: $showingDiscovery) {
            DiscoverReposSheet()
        }
    }
}

// MARK: - Discover Repos Sheet

struct DiscoverReposSheet: View {
    @Environment(RepoStore.self) private var repoStore
    @Environment(\.dismiss) private var dismiss

    @State private var localRepos: [DiscoveredRepo] = []
    @State private var ghRepos: [String: [DiscoveredRepo]] = [:] // owner -> repos
    @State private var orgs: [String] = []
    @State private var ghAvailable = false
    @State private var isScanning = false
    @State private var isFetchingGH = false
    @State private var selectedRepos: Set<String> = []
    @State private var scanPaths: String = "~/git, ~/projects, ~/repos, ~/dev, ~/code, ~/src"
    @State private var addedCount = 0

    private let discovery = DiscoveryService()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Discover Repositories")
                    .font(.title2.bold())
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(20)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Local scan section
                    localScanSection

                    // GitHub section
                    if ghAvailable {
                        Divider()
                        githubSection
                    }
                }
                .padding(20)
            }

            Divider()

            // Footer
            HStack {
                if addedCount > 0 {
                    Text("\(addedCount) repo(s) added")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
                Spacer()
                if !selectedRepos.isEmpty {
                    Button("Add \(selectedRepos.count) Selected") {
                        addSelectedRepos()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(20)
        }
        .frame(width: 650, height: 550)
        .task {
            ghAvailable = await discovery.isGHAvailable()
            await scanLocal()
            if ghAvailable {
                await fetchGitHub()
            }
        }
    }

    // MARK: - Local Scan

    private var localScanSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Local Repositories", systemImage: "folder.fill")
                    .font(.headline)
                Spacer()
                if isScanning {
                    ProgressView().controlSize(.small)
                }
                Button("Rescan") {
                    Task { await scanLocal() }
                }
                .controlSize(.small)
                .disabled(isScanning)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Scan Directories")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                TextField("~/git, ~/projects, ...", text: $scanPaths)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.caption, design: .monospaced))
            }

            if localRepos.isEmpty && !isScanning {
                Text("No git repositories found in scanned directories")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(8)
            } else {
                ForEach(localRepos) { repo in
                    discoveredRepoRow(repo)
                }
            }
        }
    }

    // MARK: - GitHub

    private var githubSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("GitHub Repositories", systemImage: "globe")
                    .font(.headline)

                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                    Text("gh authenticated")
                        .font(.caption)
                }
                .foregroundStyle(.green)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(.green.opacity(0.1))
                .clipShape(Capsule())

                Spacer()

                if isFetchingGH {
                    ProgressView().controlSize(.small)
                }
                Button("Refresh") {
                    Task { await fetchGitHub() }
                }
                .controlSize(.small)
                .disabled(isFetchingGH)
            }

            if ghRepos.isEmpty && !isFetchingGH {
                Text("No repos found")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(8)
            }

            ForEach(Array(ghRepos.keys.sorted()), id: \.self) { owner in
                DisclosureGroup {
                    ForEach(ghRepos[owner] ?? []) { repo in
                        discoveredRepoRow(repo)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "building.2")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(owner)
                            .font(.callout)
                            .fontWeight(.medium)
                        Text("\(ghRepos[owner]?.count ?? 0) repos")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: - Row

    private func discoveredRepoRow(_ repo: DiscoveredRepo) -> some View {
        let hasLocalPath = repo.localPath != nil && !repo.localPath!.isEmpty
        let alreadyAdded = repoStore.repos.contains(where: {
            if hasLocalPath {
                return $0.path == repo.localPath!
            }
            return !repo.githubBasePath.isEmpty && $0.githubBasePath == repo.githubBasePath
        })
        let isDisabled = alreadyAdded || !hasLocalPath
        let isSelected = selectedRepos.contains(repo.id)

        return HStack(spacing: 10) {
            Button {
                if isSelected {
                    selectedRepos.remove(repo.id)
                } else {
                    selectedRepos.insert(repo.id)
                }
            } label: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .secondary)
            }
            .buttonStyle(.plain)
            .disabled(isDisabled)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(repo.name)
                        .font(.system(.callout, design: .monospaced))
                        .fontWeight(.medium)

                    if repo.isPrivate {
                        Text("private")
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(.orange.opacity(0.1))
                            .foregroundStyle(.orange)
                            .clipShape(Capsule())
                    }

                    if alreadyAdded {
                        Text("added")
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(.green.opacity(0.1))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    }

                    if !hasLocalPath {
                        Text("no local clone")
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(.secondary.opacity(0.1))
                            .foregroundStyle(.secondary)
                            .clipShape(Capsule())
                    }
                }
                if let localPath = repo.localPath, !localPath.isEmpty {
                    Text(localPath)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                } else {
                    Text(repo.nameWithOwner)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()
        }
        .padding(8)
        .background(isSelected ? Color.accentColor.opacity(0.05) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .opacity(isDisabled ? 0.5 : 1)
    }

    // MARK: - Actions

    private func scanLocal() async {
        isScanning = true
        let paths = scanPaths.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        localRepos = await discovery.scanLocalRepos(in: paths)
        isScanning = false
    }

    private func fetchGitHub() async {
        isFetchingGH = true
        var results: [String: [DiscoveredRepo]] = [:]

        // Build a lookup from GitHub URL -> local path using already-scanned local repos
        var urlToLocalPath: [String: String] = [:]
        for local in localRepos {
            let normalized = local.url.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            if !normalized.isEmpty {
                urlToLocalPath[normalized] = local.localPath
            }
        }

        // Personal repos
        if let personal = try? await discovery.listRepos() {
            let username = personal.first?.nameWithOwner.components(separatedBy: "/").first ?? "Personal"
            results[username] = personal.map { repo in
                crossReference(repo, urlToLocalPath: urlToLocalPath)
            }
        }

        // Org repos
        if let orgList = try? await discovery.listOrgs() {
            orgs = orgList
            for org in orgList {
                if let orgRepos = try? await discovery.listRepos(owner: org) {
                    results[org] = orgRepos.map { repo in
                        crossReference(repo, urlToLocalPath: urlToLocalPath)
                    }
                }
            }
        }

        ghRepos = results
        isFetchingGH = false
    }

    private func crossReference(_ repo: DiscoveredRepo, urlToLocalPath: [String: String]) -> DiscoveredRepo {
        if repo.localPath != nil { return repo }
        let normalized = repo.url.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if let localPath = urlToLocalPath[normalized] {
            return DiscoveredRepo(
                nameWithOwner: repo.nameWithOwner,
                name: repo.name,
                url: repo.url,
                isPrivate: repo.isPrivate,
                localPath: localPath
            )
        }
        return repo
    }

    private func addSelectedRepos() {
        let allDiscovered = localRepos + ghRepos.values.flatMap { $0 }
        for repo in allDiscovered where selectedRepos.contains(repo.id) {
            // Skip repos without a local path — can't run git commands on them
            guard let localPath = repo.localPath, !localPath.isEmpty else { continue }

            let alreadyAdded = repoStore.repos.contains(where: {
                $0.githubBasePath == repo.githubBasePath || $0.path == localPath
            })
            guard !alreadyAdded else { continue }

            let config = RepoConfig(
                name: repo.name,
                path: localPath,
                baseBranches: ["main"],
                githubBasePath: repo.githubBasePath
            )
            repoStore.add(config)
            addedCount += 1
        }
        selectedRepos.removeAll()

        // Auto-detect base branches for repos with local paths
        Task {
            for repo in repoStore.repos {
                guard !repo.path.isEmpty else { continue }
                let bases = await discovery.detectBaseBranches(repoPath: repo.path)
                if !bases.isEmpty && repo.baseBranches == ["main"] {
                    var updated = repo
                    updated.baseBranches = bases
                    repoStore.update(updated)
                }
            }
        }
    }
}

// MARK: - Repo Settings Card

struct RepoSettingsCard: View {
    @Environment(RepoStore.self) private var repoStore
    let repo: RepoConfig

    @State private var name: String = ""
    @State private var path: String = ""
    @State private var githubBasePath: String = ""
    @State private var baseBranchesText: String = ""
    @State private var hasUnsavedChanges = false
    @State private var showDeleteConfirm = false
    @State private var isDetecting = false

    private let discovery = DiscoveryService()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Card header
            HStack {
                Image(systemName: "folder.fill")
                    .foregroundStyle(.blue)
                Text(repo.name)
                    .font(.headline)

                if hasUnsavedChanges {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .help("Unsaved changes")
                }

                Spacer()

                if isDetecting {
                    ProgressView().controlSize(.small)
                }

                Button("Detect") {
                    Task { await autoDetect() }
                }
                .controlSize(.small)
                .disabled(path.isEmpty || isDetecting)
                .help("Auto-detect GitHub URL and base branches")

                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red.opacity(0.7))
                .help("Remove repository")
            }

            Divider()

            // Fields
            VStack(alignment: .leading, spacing: 10) {
                fieldRow("Name") {
                    TextField("Repository name", text: $name)
                        .textFieldStyle(.roundedBorder)
                }

                fieldRow("Path") {
                    HStack(spacing: 8) {
                        TextField("Path to git repo", text: $path)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                        Button("Browse...") {
                            let panel = NSOpenPanel()
                            panel.canChooseDirectories = true
                            panel.canChooseFiles = false
                            panel.allowsMultipleSelection = false
                            if panel.runModal() == .OK, let url = panel.url {
                                path = url.path
                                if name.isEmpty {
                                    name = url.lastPathComponent
                                }
                                checkUnsaved()
                            }
                        }
                        .controlSize(.small)
                    }
                }

                fieldRow("GitHub URL") {
                    TextField("https://github.com/user/repo", text: $githubBasePath)
                        .textFieldStyle(.roundedBorder)
                }

                fieldRow("Base Branches") {
                    TextField("main, develop", text: $baseBranchesText)
                        .textFieldStyle(.roundedBorder)
                }
            }

            // Save button
            if hasUnsavedChanges {
                HStack {
                    Spacer()
                    Button("Save Changes") {
                        saveRepo()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
        }
        .padding(16)
        .background(.quaternary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onAppear { loadFields() }
        .onChange(of: name) { _, _ in checkUnsaved() }
        .onChange(of: path) { _, _ in checkUnsaved() }
        .onChange(of: githubBasePath) { _, _ in checkUnsaved() }
        .onChange(of: baseBranchesText) { _, _ in checkUnsaved() }
        .alert("Remove Repository", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                repoStore.remove(repo)
            }
        } message: {
            Text("Are you sure you want to remove \"\(repo.name)\"? This only removes it from Digit, not from disk.")
        }
    }

    private func fieldRow<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            content()
        }
    }

    private func loadFields() {
        name = repo.name
        path = repo.path
        githubBasePath = repo.githubBasePath
        baseBranchesText = repo.baseBranches.joined(separator: ", ")
        hasUnsavedChanges = false
    }

    private func checkUnsaved() {
        hasUnsavedChanges = name != repo.name
            || path != repo.path
            || githubBasePath != repo.githubBasePath
            || baseBranchesText != repo.baseBranches.joined(separator: ", ")
    }

    private func saveRepo() {
        var updated = repo
        updated.name = name
        updated.path = path
        updated.githubBasePath = githubBasePath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        updated.baseBranches = baseBranchesText
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        repoStore.update(updated)
        hasUnsavedChanges = false
    }

    private func autoDetect() async {
        guard !path.isEmpty else { return }
        isDetecting = true

        let detectedURL = await discovery.detectGitHubURL(repoPath: path)
        if !detectedURL.isEmpty && githubBasePath.isEmpty {
            githubBasePath = detectedURL
        }

        let detectedBases = await discovery.detectBaseBranches(repoPath: path)
        if !detectedBases.isEmpty {
            baseBranchesText = detectedBases.joined(separator: ", ")
        }

        checkUnsaved()
        isDetecting = false
    }
}

// MARK: - Add Repo Sheet

struct AddRepoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var path: String = ""
    @State private var githubBasePath: String = ""
    @State private var baseBranchesText: String = "main"
    @State private var isDetecting = false

    private let discovery = DiscoveryService()
    var onAdd: (RepoConfig) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Add Repository")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 12) {
                fieldRow("Name") {
                    TextField("Repository name", text: $name)
                        .textFieldStyle(.roundedBorder)
                }

                fieldRow("Path") {
                    HStack(spacing: 8) {
                        TextField("Path to git repo", text: $path)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                        Button("Browse...") {
                            let panel = NSOpenPanel()
                            panel.canChooseDirectories = true
                            panel.canChooseFiles = false
                            panel.allowsMultipleSelection = false
                            if panel.runModal() == .OK, let url = panel.url {
                                path = url.path
                                if name.isEmpty {
                                    name = url.lastPathComponent
                                }
                                Task { await autoDetect() }
                            }
                        }
                        .controlSize(.small)
                    }
                }

                fieldRow("GitHub URL") {
                    HStack(spacing: 8) {
                        TextField("https://github.com/user/repo", text: $githubBasePath)
                            .textFieldStyle(.roundedBorder)
                        if isDetecting {
                            ProgressView().controlSize(.small)
                        }
                    }
                }

                fieldRow("Base Branches") {
                    TextField("main, develop", text: $baseBranchesText)
                        .textFieldStyle(.roundedBorder)
                }
            }

            Divider()

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Add Repository") {
                    let baseBranches = baseBranchesText
                        .components(separatedBy: ",")
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty }
                    let repo = RepoConfig(
                        name: name,
                        path: path,
                        baseBranches: baseBranches,
                        githubBasePath: githubBasePath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                    )
                    onAdd(repo)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty || path.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 500)
    }

    private func fieldRow<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            content()
        }
    }

    private func autoDetect() async {
        guard !path.isEmpty else { return }
        isDetecting = true

        let detectedURL = await discovery.detectGitHubURL(repoPath: path)
        if !detectedURL.isEmpty {
            githubBasePath = detectedURL
        }

        let detectedBases = await discovery.detectBaseBranches(repoPath: path)
        if !detectedBases.isEmpty {
            baseBranchesText = detectedBases.joined(separator: ", ")
        }

        isDetecting = false
    }
}
