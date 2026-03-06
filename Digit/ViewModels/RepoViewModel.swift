import Foundation
import SwiftUI

@MainActor
@Observable
class RepoViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case fetching
        case loaded
        case error(String)
    }

    enum SortMode: String, CaseIterable {
        case alphabeticalAsc = "A → Z"
        case alphabeticalDesc = "Z → A"
        case newestFirst = "Newest First"
        case oldestFirst = "Oldest First"
    }

    var repo: RepoConfig?
    var branches: [Branch] = []
    var gridEntries: [String: BranchGridEntry] = [:] // branchName -> grid entry
    var loadState: LoadState = .idle
    var lastFetchTime: Date?
    var fetchOutput: String = ""

    // UI state
    var filterText: String = ""
    var sortMode: SortMode = .alphabeticalAsc
    var hiddenBranches: Set<String> = []
    var expandedBranches: Set<String> = []

    private var gitService: GitService?

    var filteredBranches: [Branch] {
        var result = branches.filter { !hiddenBranches.contains($0.name) }

        if !filterText.isEmpty {
            let terms = filterText.lowercased().components(separatedBy: " ").filter { !$0.isEmpty }
            result = result.filter { branch in
                let name = branch.displayName.lowercased()
                return terms.allSatisfy { name.contains($0) }
            }
        }

        switch sortMode {
        case .alphabeticalAsc:
            result.sort { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
        case .alphabeticalDesc:
            result.sort { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedDescending }
        case .newestFirst:
            result.sort { ($0.newestCommitDate ?? .distantPast) > ($1.newestCommitDate ?? .distantPast) }
        case .oldestFirst:
            result.sort { ($0.oldestCommitDate ?? .distantFuture) < ($1.oldestCommitDate ?? .distantFuture) }
        }

        return result
    }

    var hiddenBranchList: [Branch] {
        branches.filter { hiddenBranches.contains($0.name) }
            .sorted { $0.displayName < $1.displayName }
    }

    var baseBranches: [String] {
        repo?.baseBranches ?? []
    }

    func selectRepo(_ config: RepoConfig) {
        repo = config
        gitService = GitService(repoPath: config.path)
        branches = []
        gridEntries = [:]
        hiddenBranches = []
        expandedBranches = []
        loadState = .idle
        Task { await loadBranches() }
    }

    func loadBranches() async {
        guard let gitService, let repo else { return }
        loadState = .loading

        do {
            let branchNames = try await gitService.remoteBranches()

            // Build grid entries with per-commit/per-base tracking
            var loadedBranches: [Branch] = []
            var entries: [String: BranchGridEntry] = [:]

            for name in branchNames {
                let entry = try await gitService.buildGridEntry(
                    branch: name,
                    baseBranches: repo.baseBranches,
                    allBranchNames: branchNames,
                    limit: 50
                )
                entries[name] = entry

                // Build Branch from the grid entry commits
                let commits = entry.commits.map(\.commit)
                loadedBranches.append(Branch(name: name, commits: commits))
            }

            branches = loadedBranches
            gridEntries = entries
            loadState = .loaded
        } catch {
            loadState = .error(error.localizedDescription)
        }
    }

    func refresh() async {
        guard let gitService else { return }
        loadState = .fetching

        do {
            let output = try await gitService.fetch()
            fetchOutput = output
            lastFetchTime = Date()
            await loadBranches()
        } catch {
            fetchOutput = error.localizedDescription
            loadState = .error(error.localizedDescription)
        }
    }

    func toggleBranchHidden(_ branch: Branch) {
        if hiddenBranches.contains(branch.name) {
            hiddenBranches.remove(branch.name)
        } else {
            hiddenBranches.insert(branch.name)
        }
    }

    func showAllBranches() {
        hiddenBranches.removeAll()
    }

    func hideFeatureBranches() {
        guard let repo else { return }
        for branch in branches {
            let display = branch.displayName
            if !repo.baseBranches.contains(display) {
                hiddenBranches.insert(branch.name)
            }
        }
    }

    func toggleExpanded(_ branch: Branch) {
        if expandedBranches.contains(branch.name) {
            expandedBranches.remove(branch.name)
        } else {
            expandedBranches.insert(branch.name)
        }
    }

    func expandAll() {
        expandedBranches = Set(branches.map(\.name))
    }

    func collapseAll() {
        expandedBranches.removeAll()
    }

    func gridEntry(for branch: Branch) -> BranchGridEntry? {
        gridEntries[branch.name]
    }

    func githubCompareURL(branch: Branch, base: String) -> URL? {
        guard let repo, !repo.githubBasePath.isEmpty else { return nil }
        let branchName = branch.displayName
        let urlString = "\(repo.githubBasePath)/compare/\(base)...\(branchName)"
        return URL(string: urlString)
    }

    func githubCommitURL(_ commit: Commit) -> URL? {
        guard let repo, !repo.githubBasePath.isEmpty else { return nil }
        return URL(string: "\(repo.githubBasePath)/commit/\(commit.hash)")
    }

    func githubBranchURL(_ branch: Branch) -> URL? {
        guard let repo, !repo.githubBasePath.isEmpty else { return nil }
        return URL(string: "\(repo.githubBasePath)/tree/\(branch.displayName)")
    }
}
