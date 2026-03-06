import Foundation

struct DiscoveredRepo: Identifiable, Hashable {
    var id: String { nameWithOwner }
    let nameWithOwner: String
    let name: String
    let url: String
    let isPrivate: Bool
    let localPath: String?

    var githubBasePath: String {
        url.hasSuffix(".git") ? String(url.dropLast(4)) : url
    }
}

actor DiscoveryService {
    // MARK: - GitHub Discovery via gh CLI

    struct GHRepo: Decodable {
        let nameWithOwner: String
        let url: String
        let isPrivate: Bool
    }

    func isGHAvailable() async -> Bool {
        let output = try? await shell("/usr/bin/which", "gh")
        return output?.contains("gh") == true
    }

    func listOrgs() async throws -> [String] {
        let output = try await shell("/opt/homebrew/bin/gh", "org", "list")
        return output
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    func listRepos(owner: String? = nil, limit: Int = 100) async throws -> [DiscoveredRepo] {
        var args = ["repo", "list"]
        if let owner {
            args.append(owner)
        }
        args += ["--limit", "\(limit)", "--json", "nameWithOwner,url,isPrivate"]

        let output = try await shell("/opt/homebrew/bin/gh", args)
        let data = Data(output.utf8)
        let ghRepos = try JSONDecoder().decode([GHRepo].self, from: data)

        return ghRepos.map { repo in
            let name = repo.nameWithOwner.components(separatedBy: "/").last ?? repo.nameWithOwner
            return DiscoveredRepo(
                nameWithOwner: repo.nameWithOwner,
                name: name,
                url: repo.url,
                isPrivate: repo.isPrivate,
                localPath: nil
            )
        }
    }

    // MARK: - Local Repo Scanning

    func scanLocalRepos(in directories: [String] = ["~/git", "~/projects", "~/repos", "~/dev", "~/code", "~/src"]) async -> [DiscoveredRepo] {
        var results: [DiscoveredRepo] = []
        let fm = FileManager.default

        for dir in directories {
            let expandedPath = NSString(string: dir).expandingTildeInPath
            guard fm.fileExists(atPath: expandedPath) else { continue }

            guard let contents = try? fm.contentsOfDirectory(atPath: expandedPath) else { continue }
            for item in contents {
                let itemPath = (expandedPath as NSString).appendingPathComponent(item)
                let gitPath = (itemPath as NSString).appendingPathComponent(".git")

                if fm.fileExists(atPath: gitPath) {
                    // This directory is a git repo
                    if let repo = await buildDiscoveredRepo(at: itemPath, name: item) {
                        results.append(repo)
                    }
                } else {
                    // Not a repo — scan one level deeper for nested repos (e.g., ~/git/orgname/repo)
                    var isDir: ObjCBool = false
                    guard fm.fileExists(atPath: itemPath, isDirectory: &isDir), isDir.boolValue else { continue }
                    guard let subContents = try? fm.contentsOfDirectory(atPath: itemPath) else { continue }
                    for subItem in subContents {
                        let subPath = (itemPath as NSString).appendingPathComponent(subItem)
                        let subGitPath = (subPath as NSString).appendingPathComponent(".git")
                        guard fm.fileExists(atPath: subGitPath) else { continue }
                        if let repo = await buildDiscoveredRepo(at: subPath, name: subItem) {
                            results.append(repo)
                        }
                    }
                }
            }
        }
        return results
    }

    private func buildDiscoveredRepo(at path: String, name: String) async -> DiscoveredRepo? {
        let remoteURL = (try? await shell("/usr/bin/git", ["-C", path, "remote", "get-url", "origin"])) ?? ""
        let cleanRemote = remoteURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let githubURL = Self.normalizeGitHubURL(cleanRemote)
        let nameWithOwner = Self.extractNameWithOwner(from: githubURL) ?? name

        return DiscoveredRepo(
            nameWithOwner: nameWithOwner,
            name: name,
            url: githubURL,
            isPrivate: false,
            localPath: path
        )
    }

    func detectGitHubURL(repoPath: String) async -> String {
        let output = (try? await shell("/usr/bin/git", ["-C", repoPath, "remote", "get-url", "origin"])) ?? ""
        return Self.normalizeGitHubURL(output.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    func detectBaseBranches(repoPath: String) async -> [String] {
        let output = (try? await shell("/usr/bin/git", ["-C", repoPath, "branch", "-r", "--format=%(refname:short)"])) ?? ""
        let branches = output.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.contains("HEAD") }
            .map { $0.replacingOccurrences(of: "origin/", with: "") }

        let commonBases = ["main", "master", "develop", "dev", "staging", "release"]
        return commonBases.filter { base in branches.contains(base) }
    }

    // MARK: - Helpers

    static func normalizeGitHubURL(_ raw: String) -> String {
        var url = raw
        // Convert SSH to HTTPS
        if url.hasPrefix("git@github.com:") {
            url = url.replacingOccurrences(of: "git@github.com:", with: "https://github.com/")
        }
        // Remove .git suffix
        if url.hasSuffix(".git") {
            url = String(url.dropLast(4))
        }
        return url
    }

    static func extractNameWithOwner(from url: String) -> String? {
        guard url.contains("github.com") else { return nil }
        let parts = url.components(separatedBy: "github.com/")
        guard parts.count == 2 else { return nil }
        return parts[1].trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    private func shell(_ executable: String, _ args: String...) async throws -> String {
        try await shell(executable, Array(args))
    }

    private func shell(_ executable: String, _ args: [String]) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let pipe = Pipe()

            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = args
            process.standardOutput = pipe
            process.standardError = pipe

            do {
                try process.run()
                process.waitUntilExit()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                continuation.resume(returning: output)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
