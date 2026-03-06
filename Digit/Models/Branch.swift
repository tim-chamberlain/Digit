import Foundation

struct Branch: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let commits: [Commit]

    var displayName: String {
        name.replacingOccurrences(of: "remotes/origin/", with: "")
            .replacingOccurrences(of: "origin/", with: "")
    }

    var oldestCommitDate: Date? {
        commits.map(\.date).min()
    }

    var newestCommitDate: Date? {
        commits.map(\.date).max()
    }
}

struct Commit: Identifiable, Hashable {
    var id: String { hash }
    let hash: String
    let author: String
    let email: String
    let date: Date
    let message: String

    var shortHash: String {
        String(hash.prefix(7))
    }

    var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
