---
name: resolving-merge-conflicts
description: "Use when you need to resolve an in-progress git merge/rebase conflict."
---

1. **See the current state** of the merge/rebase. Check git history and the conflicting files. Record the initial index, worktree and untracked paths so unrelated user changes remain separate from the resolution.

2. **Find the primary sources** for each conflict. Understand deeply why each change was made, and what the original intent was. Read the commit messages, check the PRs, check original issues/tickets.

3. **Resolve each hunk.** Preserve both intents where possible. Where incompatible, use the merge's stated goal and note the trade-off. If the goal does not settle a consequential conflict, ask about that conflict while continuing independent resolutions. Preserve the in-progress operation unless the user asks to abort it.

4. Discover the project's **automated checks** and run them, typically typecheck, then tests, then format. Fix anything the merge broke.

5. **Finish the merge/rebase.** Stage resolved paths explicitly and inspect the complete index before continuing. Preserve the operation's already-staged merge/rebase changes, but keep unrelated user edits and untracked files out of its commit. If unrelated edits share a resolved file or the index, separate only the resolution when possible; otherwise leave the affected step pending and explain the exact overlap. Finish the merge or continue the rebase through all remaining commits, verifying the final status and preservation of unrelated changes.
