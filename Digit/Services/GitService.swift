import Foundation

actor GitService {
    enum GitError: LocalizedError {
        case notARepository(String)
        case commandFailed(String)
        case parseError(String)

        var errorDescription: String? {
            switch self {
            case .notARepository(let path): return "Not a git repository: \(path)"
            case .commandFailed(let msg): return "Git command failed: \(msg)"
            case .parseError(let msg): return "Parse error: \(msg)"
            }
        }
    }

    private let repoPath: String

    init(repoPath: String) {
        self.repoPath = repoPath
    }

    // MARK: - Public API

    func fetch() async throws -> String {
        try await run("fetch", "--all", "--prune")
    }

    func remoteBranches() async throws -> [String] {
        let output = try await run("branch", "-r", "--format=%(refname:short)")
        return output
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.contains("HEAD") }
    }

    func commitsOnBranch(_ branch: String, limit: Int = 100) async throws -> [Commit] {
        let format = "%H|%an|%ae|%aI|%s"
        let output = try await run("log", branch, "--format=\(format)", "-\(limit)")
        return parseCommits(output)
    }

    /// Get the set of commit hashes that are in `branch` but NOT in `base`
    func commitsNotInBase(branch: String, base: String) async throws -> Set<String> {
        let output = try await run("rev-list", "\(base)..\(branch)")
        return Set(
            output.components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        )
    }

    /// Build a full grid entry for a branch: get its commits, then for each base
    /// determine which commits are NOT in that base.
    func buildGridEntry(branch: String, baseBranches: [String], allBranchNames: [String], limit: Int = 50) async throws -> BranchGridEntry {
        let commits = try await commitsOnBranch(branch, limit: limit)

        // For each base, get the set of hashes NOT in that base
        var notInBase: [String: Set<String>] = [:]
        for base in baseBranches {
            let fullBase = allBranchNames.first(where: { $0.hasSuffix("/\(base)") }) ?? "origin/\(base)"
            notInBase[base] = try await commitsNotInBase(branch: branch, base: fullBase)
        }

        // Build CommitWithBases for each commit
        let commitsWithBases = commits.map { commit in
            var bases: [String: Bool] = [:]
            for base in baseBranches {
                bases[base] = !(notInBase[base]?.contains(commit.hash) ?? false)
            }
            return CommitWithBases(commit: commit, basesWithCommit: bases)
        }

        return BranchGridEntry(branchName: branch, commits: commitsWithBases)
    }

    func latestCommitHash(_ branch: String) async throws -> String {
        let output = try await run("log", branch, "--format=%H", "-1")
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Private

    private func run(_ args: String...) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let pipe = Pipe()

            process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
            process.arguments = ["-C", repoPath] + args
            process.standardOutput = pipe
            process.standardError = pipe

            do {
                try process.run()
                process.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""

                if process.terminationStatus != 0 {
                    if output.contains("not a git repository") {
                        continuation.resume(throwing: GitError.notARepository(repoPath))
                    } else if output.contains("fatal:") {
                        continuation.resume(throwing: GitError.commandFailed(output.trimmingCharacters(in: .whitespacesAndNewlines)))
                    } else {
                        continuation.resume(returning: output)
                    }
                } else {
                    continuation.resume(returning: output)
                }
            } catch {
                continuation.resume(throwing: GitError.commandFailed(error.localizedDescription))
            }
        }
    }

    private func parseCommits(_ output: String) -> [Commit] {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let fallbackFormatter = ISO8601DateFormatter()
        fallbackFormatter.formatOptions = [.withInternetDateTime]

        return output
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .compactMap { line in
                let parts = line.components(separatedBy: "|")
                guard parts.count >= 5 else { return nil }
                let hash = parts[0]
                let author = parts[1]
                let email = parts[2]
                let dateStr = parts[3]
                let message = parts[4...].joined(separator: "|")
                let date = isoFormatter.date(from: dateStr)
                    ?? fallbackFormatter.date(from: dateStr)
                    ?? Date.distantPast
                return Commit(hash: hash, author: author, email: email, date: date, message: message)
            }
    }
}
