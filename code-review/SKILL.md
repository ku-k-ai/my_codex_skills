---
name: code-review
description: "Review a branch, PR, commit range, or uncommitted work against repository standards and the requested behavior. Report the two review axes separately."
---

Two-axis, read-only review of the changes the user requested:

- **Standards**: does the code conform to this repo's documented coding standards?
- **Spec**: does the code faithfully implement the originating issue / spec?

Both axes run as **parallel sub-agents** so they don't pollute each other's context, then this skill aggregates their findings.

Use the supplied spec and existing tracker configuration when available. Missing `docs/agents/issue-tracker.md` does not require repository setup before reviewing the available changes.

## Process

### 1. Pin the review scope

Inspect `git status --short` and use the requested scope. Preserve the index and worktree: collecting review evidence does not require staging or committing it.

- **Branch or PR:** compare the intended head with its merge-base against the known target branch, using `git diff <base>...<head>` and `git log <base>..<head> --oneline`.
- **Exact commit or range:** use the requested endpoints; use `git show <commit>` for a single commit. Do not substitute a merge-base comparison for an explicitly requested snapshot comparison.
- **Uncommitted work / WIP:** collect both `git diff --cached` and `git diff`, plus the list from `git ls-files --others --exclude-standard`. Read relevant untracked source files without adding them to Git; exclude secrets and generated artifacts. Review the final worktree contents as well as the separate staged state when they differ.
- **Changes since a base including WIP:** combine the committed comparison above with the WIP evidence, checking the final contents so layered edits are not mistaken for separate defects.

Use a base supplied by the user or established by PR/task context. Ask only when the intended comparison remains ambiguous; a clear WIP request needs no base question. Validate any refs, record the commands, resolved commits, and included paths once, and pass the same evidence to both reviewers. An empty committed diff is not an empty WIP review: check all included layers and untracked files before reporting no changes. If files change during review, refresh affected evidence before concluding.

### 2. Identify the spec source

Use the user-provided spec or task requirements first; otherwise look for the originating spec:

1. Issue references in the commit messages, using the available tracker or repository configuration.
2. A spec under the repository's existing documentation paths matching the changed feature.
3. If no requirements are available, report "no spec available" for that axis and continue the standards review. Ask for missing requirements only when they are needed to settle a finding, without blocking independent review.

### 3. Identify the standards sources

Anything in the repo that documents how code should be written, such as `CODING_STANDARDS.md` or `CONTRIBUTING.md`.

On top of whatever the repo documents, the Standards axis always carries the **smell baseline** below: a fixed set of Fowler code smells (_Refactoring_, ch.3) that applies even when a repo documents nothing. Two rules bind it:

- **The repo overrides.** A documented repo standard always wins; where it endorses something the baseline would flag, suppress the smell.
- **Always a judgement call.** Each smell is a labelled heuristic ("possible Feature Envy"), never a hard violation. Like any standard here, skip anything tooling already enforces.

Each smell reads *what it is* → *how to fix*; match it against the diff:

- **Mysterious Name**: a function, variable, or type whose name doesn't reveal what it does or holds. → rename it; if no honest name comes, the design's murky.
- **Duplicated Code**: the same logic shape appears in more than one hunk or file in the change. → extract the shared shape, call it from both.
- **Feature Envy**: a method that reaches into another object's data more than its own. → move the method onto the data it envies.
- **Data Clumps**: the same few fields or params keep travelling together (a type wanting to be born). → bundle them into one type, pass that.
- **Primitive Obsession**: a primitive or string standing in for a domain concept that deserves its own type. → give the concept its own small type.
- **Repeated Switches**: the same `switch`/`if`-cascade on the same type recurs across the change. → replace with polymorphism, or one map both sites share.
- **Shotgun Surgery**: one logical change forces scattered edits across many files in the diff. → gather what changes together into one module.
- **Divergent Change**: one file or module is edited for several unrelated reasons. → split so each module changes for one reason.
- **Speculative Generality**: abstraction, parameters, or hooks added for needs the spec doesn't have. → delete it; inline back until a real need shows.
- **Message Chains**: long `a.b().c().d()` navigation the caller shouldn't depend on. → hide the walk behind one method on the first object.
- **Middle Man**: a class or function that mostly just delegates onward. → cut it, call the real target direct.
- **Refused Bequest**: a subclass or implementer that ignores or overrides most of what it inherits. → drop the inheritance, use composition.

### 4. Spawn both sub-agents in parallel

**Standards sub-agent prompt** should include:

- The recorded comparison commands, commit list when applicable, and staged/unstaged/untracked evidence included in the scope.
- The list of standards-source files you found in step 3, **plus the smell baseline from step 3** pasted in full (the sub-agent has no other access to it).
- The brief: "Report, per file/hunk where relevant, (a) every place the diff violates a documented standard: cite the standard (file + the rule); and (b) any baseline smell you spot: name it and quote the hunk. Distinguish hard violations from judgement calls: documented-standard breaches can be hard, but baseline smells are always judgement calls, and a documented repo standard overrides the baseline. Skip anything tooling enforces. Under 400 words."

**Spec sub-agent prompt** should include:

- The same recorded comparison commands and complete scoped evidence used by the Standards reviewer.
- The path or fetched contents of the spec.
- The brief: "Report: (a) requirements the spec asked for that are missing or partial; (b) behaviour in the diff that wasn't asked for (scope creep); (c) requirements that look implemented but where the implementation looks wrong. Quote the spec line for each finding. Under 400 words."

If the spec is missing, skip the Spec sub-agent and note this in the final report.

### 5. Aggregate

Present the two reports under `## Standards` and `## Spec` headings, verbatim or lightly cleaned. Do **not** merge or rerank findings, because the two axes are deliberately separate (see _Why two axes_).

End with a one-line summary: total findings per axis, and the worst issue _within each axis_ (if any). Don't pick a single winner across axes: that's the reranking the separation exists to prevent.

## Why two axes

A change can pass one axis and fail the other:

- Code that follows every standard but implements the wrong thing → **Standards pass, Spec fail.**
- Code that does exactly what the issue asked but breaks the project's conventions → **Spec pass, Standards fail.**

Reporting them separately stops one axis from masking the other.
