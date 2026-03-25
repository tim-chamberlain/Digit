# Digit

A native macOS app for visualizing git branch status across multiple repositories. Inspired by [digit.kelkhoff.com](https://digit.kelkhoff.com/).

![macOS](https://img.shields.io/badge/platform-macOS-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-✓-green)

## Features

- **Branch comparison grid** — See which branches are ahead or fully merged into your base branches at a glance
- **Per-commit tracking** — Expand any branch to see individual commits and which base branches contain each one
- **Dynamic base branches** — Add and remove base branches (e.g. main, develop, staging, release) directly from the grid header
- **Branch filtering** — Search for branches and build up a multi-select filter that persists across sessions
- **Author column** — See who created each branch
- **Resizable columns** — Drag column borders to adjust widths
- **GitHub integration** — Click branch names, commit hashes, or comparison badges to open GitHub
- **Repo discovery** — Automatically find local repos and cross-reference with GitHub using `gh` CLI
- **Multi-repo support** — Configure and switch between multiple repositories
- **Sort options** — Sort branches alphabetically (A-Z / Z-A) or by date (newest / oldest first)
- **Hide/show branches** — Hide individual branches or all feature branches to focus your view

## Getting Started

### Requirements

- macOS 14.0+
- Xcode 15+
- Git installed at `/usr/bin/git`
- Optional: [GitHub CLI](https://cli.github.com/) (`gh`) for repo discovery and GitHub links

### Installation

1. Clone the repository
2. Open `Digit.xcodeproj` in Xcode
3. Build and run (Cmd+R)

### Adding Repositories

**Automatic discovery:**
1. Open Settings from the sidebar
2. Click "Discover Repos"
3. **Local tab** — Scans common directories (`~/git`, `~/projects`, `~/repos`, `~/dev`, `~/code`, `~/src`) for git repos. You can customize the scan directories.
4. **GitHub tab** — Lists your personal and organization repos via `gh` CLI (requires `gh auth login`). Cross-references with local clones.
5. Select repos and click "Add Selected"

**Manual setup:**
1. Open Settings > "Add Manually"
2. Browse to a local git repo path
3. GitHub URL and base branches are auto-detected
4. Adjust as needed and click "Add Repository"

### Configuring a Repository

Each repository has these settings:

| Setting | Description |
|---------|-------------|
| **Name** | Display name shown in the sidebar |
| **Path** | Local filesystem path to the git repo |
| **GitHub URL** | Base URL for GitHub links (e.g. `https://github.com/user/repo`) |
| **Base Branches** | Comma-separated list of branches to compare against |

Click "Detect" on any repo card to auto-detect the GitHub URL and common base branches.

## Usage

### Branch Grid

The main view is a scrollable grid where each row is a branch and each column is a base branch.

| Icon | Meaning |
|------|---------|
| Green checkmark | Branch is fully merged into the base |
| Red arrow + number | Branch is N commits ahead of the base |
| Blue link icon | Click to open the GitHub comparison view |

### Filtering Branches

The filter bar supports a search-and-add workflow:

1. Type in the search field to find branches
2. Click a branch from the dropdown to add it to the filter
3. Repeat to add more branches
4. Click the **x** on any chip to remove it
5. Click the clear button to reset all filters

Filters are saved per-repository and persist across app restarts.

### Managing Base Branches

- Click the **+** button in the grid header to add a base branch from a dropdown of all remote branches
- Hover over a base branch header and click the **x** to remove it

### Expanding Commits

Click the chevron next to any branch name to expand and see individual commits. Each commit shows:

- Short hash (clickable link to GitHub)
- Author name
- Relative date
- Commit message
- Per-base indicators (checkmark if in base, red dot if not)

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Cmd+R | Refresh (fetch from remote and reload) |

### Sorting

Use the Sort dropdown to order branches:

- **A → Z** / **Z → A** — Alphabetical by branch name
- **Newest First** / **Oldest First** — By most recent commit date

### Hiding Branches

- Click the eye icon on any branch row to hide it
- Use **View > Hide Feature Branches** to hide all `feature/` branches at once
- Hidden branches appear in a bar at the bottom and can be restored individually
- Use **View > Show All Branches** to unhide everything

## Architecture

```
Digit/
├── DigitApp.swift              # App entry point
├── Models/
│   ├── Branch.swift            # Branch and Commit structs
│   ├── BranchComparison.swift  # Grid entry with per-commit base tracking
│   └── RepoConfig.swift        # Repository configuration (Codable)
├── ViewModels/
│   └── RepoViewModel.swift     # Main state management (@Observable)
├── Services/
│   ├── GitService.swift        # Git command execution (actor)
│   ├── RepoStore.swift         # Persistence via UserDefaults
│   └── DiscoveryService.swift  # Local + GitHub repo discovery (actor)
└── Views/
    ├── ContentView.swift       # NavigationSplitView layout
    ├── SidebarView.swift       # Repo list sidebar
    ├── HeaderView.swift        # Repo name, status, refresh
    ├── BranchGridView.swift    # Grid, toolbar, filter, headers, resize handles
    ├── BranchRowView.swift     # Individual branch row
    ├── CommitListView.swift    # Expandable commit details
    ├── ComparisonCellView.swift# Merged/ahead badges
    └── SettingsView.swift      # Repo management and discovery
```

## License

MIT
