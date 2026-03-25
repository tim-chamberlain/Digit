import Foundation

struct RepoConfig: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var path: String
    var baseBranches: [String]
    var githubBasePath: String
    var filterBranches: [String]

    init(id: UUID = UUID(), name: String, path: String, baseBranches: [String] = ["main"], githubBasePath: String = "", filterBranches: [String] = []) {
        self.id = id
        self.name = name
        self.path = path
        self.baseBranches = baseBranches
        self.githubBasePath = githubBasePath
        self.filterBranches = filterBranches
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        path = try container.decode(String.self, forKey: .path)
        baseBranches = try container.decode([String].self, forKey: .baseBranches)
        githubBasePath = try container.decode(String.self, forKey: .githubBasePath)
        filterBranches = try container.decodeIfPresent([String].self, forKey: .filterBranches) ?? []
    }
}
