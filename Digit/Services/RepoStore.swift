import Foundation
import SwiftUI

@Observable
class RepoStore {
    private static let storageKey = "digit_repos"

    var repos: [RepoConfig] = []

    init() {
        load()
    }

    func add(_ repo: RepoConfig) {
        repos.append(repo)
        save()
    }

    func update(_ repo: RepoConfig) {
        if let index = repos.firstIndex(where: { $0.id == repo.id }) {
            repos[index] = repo
            save()
        }
    }

    func remove(_ repo: RepoConfig) {
        repos.removeAll { $0.id == repo.id }
        save()
    }

    func remove(at offsets: IndexSet) {
        repos.remove(atOffsets: offsets)
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(repos) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let decoded = try? JSONDecoder().decode([RepoConfig].self, from: data) else {
            return
        }
        repos = decoded
    }
}
