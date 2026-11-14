# MR2 Global Update — dispatch package

Prepared 2026-11-14. This directory retains the **original GitHub Project blueprint** and dispatch drafts; it is not a GitHub API import payload. Live setup has since been completed as recorded below. Reading these files does not perform any setup actions.

## Live setup

The [migration repository](https://github.com/URC-kaist/mr2-stack-jazzy) and [Project](https://github.com/orgs/URC-kaist/projects/2) are now created. See [live-resources.json](live-resources.json) for actual URLs and state. The blueprint and issue drafts below remain the preparation record.

## Review entry points

- [English briefing](../../content/docs/global-update-project/en/_index.md).
- [Korean briefing](../../content/docs/global-update-project/ko/_index.md), translated from the English version.
- Developer starting cards: [English](../../content/docs/global-update-project/en/start.md) · [한국어](../../content/docs/global-update-project/ko/start.md).
- Worked migration example: [English](../../content/docs/global-update-project/en/controller-example.md) · [한국어](../../content/docs/global-update-project/ko/controller-example.md).
- Project configuration: [project.json](project.json).
- Issue drafts: [English](issues.en.json) · [Korean](issues.ko.json).
- Dispatch text: [English](dispatch.en.md) · [Korean](dispatch.ko.md).
- Local migration repository: [repository-plan.md](repository-plan.md).

English is the drafting source, recorded in local commit `8e4d9a6`; the Korean package carries the same decision and evidence status. The Hugo site uses adjacent language sections without changing its global language configuration. Front matter `draft: false` makes these pages buildable for review; it does not publish local changes. The downloadable Project/issue JSON files under `static/projects/global-update-project/` are publication copies of the canonical drafts here; update both copies together.

## Blueprint use

The SW leader/team chooses the Project owner and repository destination, creates the Project later, then transfers the agreed issue drafts to real repositories. The JSON stores proposal metadata, not GitHub-generated IDs. `depends_on` names acceptance prerequisites; investigation/preparation may start earlier. Issue owners are deliberately unset. Role suggestions describe skills, not assignments.

Start with the proposed Status, Workstream, Priority and Required environment fields plus normal issue assignees. Use issue bodies for commands, dependencies, estimates and evidence. Add roadmap dates after the team's URC 2027 milestones/capacity are known. Physical verification can remain in separate issues after an implementation PR merges.

## Publication handoff

1. Review the English source and corresponding Korean pages for terminology and policy consistency.
2. Review the local history-preserving migration repository and choose the integration baseline/topology.
3. Confirm leader/HW/operator coordination and the first issue allocation.
4. Preview/build the documentation and verify downloadable evidence/draft files.
5. At actual dispatch, substitute real published URLs and record who owns subsequent updates.

The requested deliverable here is project-description dispatch and agenda visibility. Actual Jetson provisioning, target implementation, joint hardware acceptance and rover cutover are subsequent project work.
