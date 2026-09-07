---
name: implement
description: "Implement a piece of work based on a spec or set of tickets."
---

Implement the work described by the user in the spec or tickets.

Use /tdd when the requested work calls for test-first behavior, preferring existing or already-agreed public boundaries.

Run checks appropriate to the changed behavior and all checks required by the repository. Broaden beyond affected tests when the impact or a failure warrants it; a small non-behavioral change need not run the full suite by default.

Review the completed work with /code-review using the scope that includes the implementation, including uncommitted files. Fix valid findings caused by this change, rerun affected checks, and reassess affected findings. Completion means the requested behavior works, required verification is complete, and any remaining limitations are reported.

When committing is part of the requested workflow, commit only this task's changes to the intended branch after inspecting the staged diff. Preserve unrelated edits and follow the user's existing author and co-author settings.
