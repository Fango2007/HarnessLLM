# Agent Prompt Patch Metadata

Purpose:
Track reusable candidate patch families across benchmark agents.

Previous experiment traces and results have been reset. There are no active
baseline assessments, candidate reports, or selected best patches. Do not treat
prior reports or removed run outputs as current evidence.

## Patch Families

| Agent Key | Patch Family | Patch Directory | Run-Local Target | Runner Flag |
| --- | --- | --- | --- | --- |
| `vibe` | `AGENTS.md` append patch | `5-prompts/0-agents/patches/vibe/` | `AGENTS.md` | `--agent vibe --patch FILE` |
| `claude-code` | `CLAUDE.md` append patch | `5-prompts/0-agents/patches/claude-code/` | `CLAUDE.md` | `--agent claude-code --patch FILE` |

## Current Candidate State

| Agent Key | Status | Notes |
| --- | --- | --- |
| `vibe` | Reset | No candidate patch or best candidate is currently selected. |
| `claude-code` | Reset | No candidate patch or best candidate is currently selected. |

## Update Rule

When creating a new candidate patch:

- Store it under the patch directory for the candidate agent key.
- Record the previous patch or baseline it is based on.
- Link the comparison report or experiment result that motivated it.
- Summarize only material patch changes, not formatting edits.
- State whether the patch is `Prepared`, `Evaluated`, `Accepted`, or
  `Rejected`.
- Create or update `5-prompts/0-agents/patches/best-candidates.md` only when a
  patch becomes the best accepted patch for its agent and scenario.
- Keep this file as metadata only; do not place full patch text here.
