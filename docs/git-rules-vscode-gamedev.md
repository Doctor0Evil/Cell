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
