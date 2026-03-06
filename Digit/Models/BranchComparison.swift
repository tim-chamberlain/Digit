import Foundation

/// Represents a branch's full comparison grid against all base branches.
/// Each commit tracks which bases contain it.
struct BranchGridEntry: Identifiable {
    var id: String { branchName }
    let branchName: String
    let commits: [CommitWithBases]

    /// Commits NOT in the given base (ahead of it)
    func commitsAhead(of base: String) -> Int {
        commits.filter { $0.basesWithCommit[base] != true }.count
    }

    /// Commits IN this base but missing from at least one other base (partial merges)
    func commitsPartial(for base: String, allBases: [String]) -> Int {
        commits.filter { entry in
            guard entry.basesWithCommit[base] == true else { return false }
            return allBases.contains { otherBase in
                otherBase != base && entry.basesWithCommit[otherBase] != true
            }
        }.count
    }

    /// True if every commit is in this base
    func isFullyMerged(into base: String) -> Bool {
        commitsAhead(of: base) == 0
    }
}

struct CommitWithBases: Identifiable, Hashable {
    var id: String { commit.hash }
    let commit: Commit
    let basesWithCommit: [String: Bool]

    func isInBase(_ base: String) -> Bool {
        basesWithCommit[base] == true
    }

    static func == (lhs: CommitWithBases, rhs: CommitWithBases) -> Bool {
        lhs.commit.hash == rhs.commit.hash
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(commit.hash)
    }
}
