# Digit

A native macOS app for visualizing git branch status across multiple repositories. Inspired by [digit.kelkhoff.com](https://digit.kelkhoff.com/).

![macOS](https://img.shields.io/badge/platform-macOS-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-✓-green)

## Features

- **Branch comparison grid** — See which branches are ahead, merged, or partially merged into your base branches at a glance
- **Per-commit tracking** — Expand any branch to see individual commits and which base branches contain each one
- **GitHub integration** — Links to compare views, commits, and branches on GitHub
- **Repo discovery** — Automatically find local repos and cross-reference with GitHub using `gh` CLI
- **Multi-repo support** — Configure and switch between multiple repositories
- **Sort & filter** — Sort branches alphabetically or by date, filter by name
- **Hide/show branches** — Keep your view clean by hiding branches you don't need to see

## Getting Started

1. Clone and open in Xcode
2. Build and run (requires macOS 14+)
3. Go to Settings and add a repository (or use Discover to find them automatically)
4. Configure your base branches (e.g., `main`, `develop`)

## Requirements

- macOS 14.0+
- Xcode 15+
- Git installed at `/usr/bin/git`
- Optional: [GitHub CLI](https://cli.github.com/) (`gh`) for repo discovery
