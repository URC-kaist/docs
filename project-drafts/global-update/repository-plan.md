# Local migration repository

Prepared at `/home/menny/mr2-stack-jazzy`, preserving the existing repository's history and license. GitHub creation is **pending at the user's instruction**.

| Property | Value |
| --- | --- |
| Active branch | `migration/jazzy` |
| Upstream | Fetch: `https://github.com/URC-kaist/mr2-stack.git`; push disabled locally |
| Publishing remote | None |
| Provisional audited base | `74422f36c55140519f111cf6709f1725711b536a` |
| Local audit tag | `audit/2026-11-14` |
| Application migration | Not started; changes are limited to README and bilingual migration handoff notes |

The local repository is a history-preserving migration workspace, not yet a GitHub-recognized fork. A GitHub fork can be created later after owner/name and canonical issue location are selected. The team decides whether accepted code returns upstream or becomes the next canonical deployment repository.

## Review the workspace

```bash
git -C ~/mr2-stack-jazzy status --short --branch
git -C ~/mr2-stack-jazzy remote -v
git -C ~/mr2-stack-jazzy log -2 --oneline
git -C ~/mr2-stack-jazzy submodule status
```

Do not interpret baseline source or upstream branch claims as a completed target port. Resolve the operational reference, rover-direct integration and selected deployment profile before converging sector changes.

After a team-approved GitHub destination exists, add it as `origin` and publish the reviewed branch intentionally. This preparation does not create that destination or push any branch. Existing `~/mr2-stack` remains unchanged.
