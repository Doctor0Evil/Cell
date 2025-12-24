# Git, VS Code, and Game-Dev Ruleset (Space Lifecycle)

This document defines **mandatory behaviors** for IDEs, MCP servers, and coding agents operating in this space.  
It focuses on:

- Git + VS Code errors like:
  - `fatal: not a git repository`
  - `failed to execute git`
  - `Git installation not found` / `Git is not recognized`
  - `No source control providers registered`
- Branching and PR workflows for **game development** (Godot-like projects, large assets, multi-disciplinary teams).
- Automation-friendly patterns that tools can execute without guesswork.

---

## 1. Source Control & Git detection rules

### 1.1. Always verify SCM preconditions

Before any branch/PR operation, agents **must** ensure:

1. VS Code Source Control is active and recognizes a repository.  
2. A folder containing a `.git` directory is opened in VS Code (or in the current working directory for CLI).  
3. Git is installed and callable:  
   - `git --version` must succeed in the integrated terminal.

If any of these fail, **stop** and apply the error-specific rules below before proceeding.

---

### 1.2. Handling “Git missing / Git installation not found / Git is not recognized”

These map to **Git executable / PATH issues**:

1. Run in terminal:

```
git --version
```

2. If this fails:
- Instruct user/environment to install Git from the official downloads.  
- On Windows, ensure the installer option *“Git from the command line and also from 3rd‑party software”* is selected so VS Code can see Git.

3. After installation, ensure Git is on `PATH`:
- On Windows, verify `C:\Program Files\Git\cmd` or similar is present in the system `Path` environment variable.

4. In VS Code:
- Confirm `git.enabled` is `true` in settings.
- If VS Code still cannot locate Git, set a concrete Git path:

```json
{
  "git.enabled": true,
  "git.path": "C:\\Program Files\\Git\\cmd\\git.exe"
}
```

5. Restart VS Code and re-open the repository folder.

If errors persist after these steps, agents may **only then** investigate extensions or environment-specific issues.

---

### 1.3. Handling “No source control providers registered”

This indicates VS Code has no active SCM provider or no repo is detected.

Agents must:

1. **Check built-in Git extension**:
- Open Extensions view.
- Search `@builtin git`.
- Ensure the **Git** extension is **Enabled**, not disabled.
- If changed, reload VS Code.

2. **Confirm Git is enabled in settings**:
- Ensure:

```json
{
  "git.enabled": true
}
```

3. **Confirm a real repo is open**:
- Use `File → Open Folder...` and open a directory that actually contains `.git` at its root.
- In the integrated terminal:

```
pwd   # or 'cd' on Windows
ls -a # or 'dir /a'
```

The `.git` directory must be visible.

4. **Nudge VS Code SCM if it’s “asleep”**:
- From Command Palette (`Ctrl+Shift+P`), run a safe Git command:
  - `Git: Open All Changes`  
  - or `Git: Fetch` / `Git: Pull`  
- Even if this shows “Git: There are no available repositories”, after canceling, SCM often refreshes and recognizes the repo.

5. If, after all of the above, there is still no provider:
- Verify no conflicting SCM provider is forcing Git off.
- Confirm workspace is not misconfigured (multi-root workspace without the repo folder added).

---

### 1.4. Handling “fatal: not a git repository (or any of the parent directories): .git”

This means the current working directory is not inside a Git repo.

Agents must:

1. Run:

```
pwd   # show current folder
ls -a # or 'dir /a' to check for .git
```

2. If `.git` is **not** present:
- Instruct to `cd` into the correct repo root (e.g., `cd /path/to/game-repo`).  
- Only run Git commands (status, commit, branch, etc.) from inside that repo root.

3. Agents **MUST NOT** suggest `git init` in an existing cloned repo structure unless explicitly creating a brand new repository.

4. If the user cannot locate the repo or `.git` appears corrupted:
- Suggest recloning from the remote (GitHub, etc.) into a fresh folder instead of attempting risky manual fixes.

---

## 2. VS Code Source Control usage patterns

Once SCM is working:

1. Use Source Control view to:
- Stage/unstage changes (plus icon, or “Stage All”).
- Commit using the message box and checkmark.
- View diffs using the built-in diff editor.

2. Use the branch UI for:
- Creating branches, switching branches.
- Syncing (push/pull) with the remote.

3. Agents should:
- Prefer VS Code’s UI for conflict resolution where possible (visual merge tools).
- Offer command-line equivalents for automation or headless environments.

---

## 3. Game-development Git workflow rules

These rules tune Git behavior for **game projects** (e.g., Godot-like, large assets, multi-disciplinary teams).

### 3.1. Branching model for game projects

Agents must default to a **feature branch workflow** unless the repo defines otherwise.

Recommended branch types:

- `main` / `master`  
- Always stable and releasable; game should build and run from here.

- `develop` (optional, if Gitflow-style)  
- Integration branch for features; CI may build and test here.

- `feature/*`  
- One branch per mechanic/system/feature (e.g., `feature/ai-patrol`, `feature/horror-lighting-pass`).

- `hotfix/*`  
- For urgent production fixes.

The agent should:

1. Instruct users to start work by updating the base branch:

```
git checkout main
git pull origin main
```

or if using `develop`:

```
git checkout develop
git pull origin develop
```

2. Create feature branches:

```
git checkout -b feature/<short-description>
```

3. Encourage **small, frequent commits** with meaningful messages and scope-limited changes.

---

### 3.2. Integrating and updating branches

To keep branches up-to-date and reduce conflicts:

1. Regularly rebase or merge from parent branch:

```
git fetch origin
git rebase origin/develop   # or origin/main
```

2. Prefer:
- Rebase for smaller branches that are short-lived.
- Merge for large, long-lived branches (to avoid painful interactive rebases).

3. Before PR merge:
- Ensure branch builds and runs in the game engine.
- Resolve conflicts and rerun automated tests (if present).

---

### 3.3. Large assets and Git LFS

Game projects frequently include large binary files (textures, models, audio)

Agents should:

1. Recommend **Git LFS** for large assets:

```
git lfs install
git lfs track "*.png"
git lfs track "*.psd"
git lfs track "*.fbx"
git add .gitattributes
git commit -m "Configure Git LFS for large assets"
```

2. Encourage `.gitignore` rules to exclude:
- Engine caches and temporary files.
- Local/editor-specific metadata that is not needed in source control.

3. Advise structuring assets so that:
- Different teams (art, code, design) seldom modify the same files, reducing merge conflicts in binaries.

---

## 4. Pull Requests and collaboration

Agents should enforce PR discipline aligned with game-dev best practices:

1. **Before opening a PR**:
- Update branch from main/develop.
- Ensure:
  - Game builds in the engine.
  - No obvious build-breaking changes.
  - Commit history is reasonable (optionally squashed).

2. **PR content**:
- Describe:
  - What changed.
  - How to test (e.g., which level/scene to open).
  - Any asset or content implications (new sounds, shaders, scenes).

<<<<<<< HEAD
### Companion mentor: CellCompanionHorrorAssetMentor

Add a companion mentor node to help IDEs and agents generate and integrate horror assets safely and reproducibly. Place the file at `res/scripts/ai/cell_companion_horror_asset_mentor.gd` and register it as an autoload or call it from your editor bridge.

Recommended behavior:

- The mentor exposes: `suggest_asset_pipeline(concept)`, `build_horror_prompt(region, asset_focus)`, `suggest_safe_sources()`, and `get_attribution_instructions(license_type)`.
- Use `suggest_asset_pipeline()` to drive per-asset checklists and bind pipeline steps to CI checks (lint, size, palette, license metadata).
- Before committing assets, query `get_attribution_instructions()` to ensure proper attribution for CC-BY assets and refuse import on unknown licenses.

<<<<<<< HEAD
### Horror art pipeline mentor: CellHorrorArtPipelineMentor

Add a horror art pipeline mentor at `res/scripts/ai/cell_horror_art_pipeline_mentor.gd` to provide asset teams and IDE agents with:

- Reusable pipeline steps: blockout → mood → detail → Godot prep → integration → profile → document.
- A recommended folder structure rooted at `res/ASSETS`, `res/scenes`, and `res/scripts` to keep assets, scenes, and scripts grouped by feature/entity for easy tracing and PR reviews.
- Practical tips for environment art, character concept prompts, and night-vision shader guidance.

Register this script as an autoload (or call from the same PromptHub the other mentor uses) so IDE bridges can request pipeline steps and folder guidance automatically.
=======
This companion is included in the repository at `res/scripts/ai/cell_companion_horror_asset_mentor.gd` and can be used by IDE plugins or external MCP agents to keep asset creation compliant and reproducible.
=======
3. **During PR review**:
- Encourage early and frequent integration to avoid huge, unreviewable PRs.
- Suggest use of visual diff or specialized merge tools for scene/asset files when supported.

4. **After merge**:
- Delete merged feature branches in remote and local to keep branch list clean (if repo policy permits).
>>>>>>> 3dc78c9 (12)
>>>>>>> 78c917a (12)

---

## 5. Automation & MCP/IDE behavior

To remain automation-friendly:

1. Agents must **prefer deterministic commands** that can be executed by tools, such as:
- Diagnostics:
```
git --version
git status
git rev-parse --show-toplevel
git branch -a
```
- Branch operations:
```
git checkout main
git pull origin main
git checkout -b feature/<name>
git fetch origin
git rebase origin/main
```

2. Agents must **not** request or store secrets/tokens in the repository:
- Use platform features (e.g., GitHub Actions secrets) for authentication.
- Never embed personal access tokens, GITHUB_SECRETS, or similar in code or config.

3. When encountering SCM errors:
- Always run the Git/VS Code diagnostics in Sections 1 and 2 **before** attempting branch surgery (rebases, resets, rewrites).

---

## 6. Error → Action summary (for quick application)

| Error / Symptom                                | Required Agent Actions                                                                                          |
|-----------------------------------------------|------------------------------------------------------------------------------------------------------------------|
| `Git not found` / `Git installation not found`| Check `git --version`; install Git; ensure PATH; set `"git.path"` if needed; restart VS Code.    |
| `No source control providers registered`      | Enable built-in Git extension; set `"git.enabled": true`; open correct repo folder; nudge SCM via Git commands. |
| `fatal: not a git repository`                 | Verify current directory; ensure `.git` exists; `cd` to repo root; avoid `git init` unless intentionally new. |
| VS Code shows repo but Git operations fail    | Verify remote configuration, branch tracking, and that Git is properly configured; repair upstream and remotes.  |

All tools and agents in this space must **adhere to this ruleset** when handling Git/ VS Code issues and must ensure a healthy SCM state before performing game‑dev branch/PR operations.
