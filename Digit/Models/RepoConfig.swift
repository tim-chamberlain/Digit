import Foundation

struct RepoConfig: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var path: String
    var baseBranches: [String]
    var githubBasePath: String

    init(id: UUID = UUID(), name: String, path: String, baseBranches: [String] = ["main"], githubBasePath: String = "") {
        self.id = id
        self.name = name
        self.path = path
        self.baseBranches = baseBranches
        self.githubBasePath = githubBasePath
    }
}
