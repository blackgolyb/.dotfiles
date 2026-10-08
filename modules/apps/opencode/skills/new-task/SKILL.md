---
name: new-task
description: Use when starting a new task - from an issue/ticket in any project management tool (Linear, Jira, GitHub Issues, ...), an existing task.md, or a direct request. Investigates the codebase read-only, asks all clarifying questions, asks about creating a worktree, then writes task.md and plan.md at the repo root.
---

# Starting a new task

You are in intake and planning mode. Do NOT implement anything. Investigation is
read-only until plan.md is written and the user explicitly approves starting.

## Step 1 — Worktree

Handle this FIRST, before intake or investigation:

- If the user has NOT already mentioned a worktree or branch for this task,
  ask: "Should I create an isolated worktree + branch for this task?"
- If they already answered or mentioned a branch, follow that — do not re-ask
- If yes: create it inside the repo at `.worktrees/<branch-name>`:
  `git worktree add .worktrees/<branch-name> -b <branch-name>`
  Put `*` in `.worktrees/.gitignore` (do NOT touch the repo's own .gitignore),
  then do all remaining steps inside the new worktree

## Step 2 — Intake

Determine what you were given:

1. **Ticket/issue from a project management tool** (Linear, Jira, GitHub
   Issues, GitLab, ... — an ID like `ENG-123`, a tracker URL, or "work on
   ticket ..."): fetch the full description with whatever tooling this project
   has — an MCP server, a CLI (`gh issue view`, `jira issue view`, ...), or by
   opening the URL. If no tool is available, ask the user to paste the ticket
   content.
2. **`task.md` exists** at the repo root: read it. This is the user's own task
   description.
3. **Both a ticket and an existing `task.md`** — compare before anything else:
   - Same task (task.md describes the ticket): proceed. Treat task.md as the
     base; refresh stale details from the ticket.
   - Mismatch (different feature, contradictory scope): STOP. Never silently
     overwrite task.md. Ask the user which is the source of truth:
     - update task.md from the ticket
     - keep task.md as-is and ignore the ticket details
     - treat them as two separate tasks (and which one comes first)
4. **Only a verbal/written request**: derive the task from it.

If the source is a ticket or just verbal/written and there is no matching `task.md`, create
`task.md` at the repo root with ONLY the essential description:

- Goal (1–3 sentences)
- Source (ticket ID / URL)
- Requirements and acceptance criteria
- Constraints

No ticket comment dumps, no history, no plan content — that goes in plan.md.

## Step 3 — Investigate (read-only)

- Explore the relevant code, existing conventions, and similar implementations
- Check git history for related work
- Identify files that will likely be touched, risks, and unknowns

## Step 4 — Clarifying questions

- Ask everything needed to plan confidently: scope boundaries, edge cases,
  behavior decisions, priorities, out-of-scope items
- Batch related questions together; use the question tool when the answers are
  enumerable choices
- Do not write plan.md until the questions are answered

## Step 5 — Write `plan.md`

Write `plan.md` at the repo root:

- Goal (one sentence)
- Approach (the decided one; alternatives rejected, briefly)
- Ordered implementation steps — each verifiable, with exact file paths
- Verification (commands / tests to run)
- Worktree decision (create it: yes/no, branch name, path)
- Risks / assumptions (non-blocking only)

If a plan.md from a previous task already exists, ask before replacing it.

## Step 6 — Hand off

State where task.md and plan.md are, summarize the plan briefly, and ask the
user to approve before any implementation begins. Implementation is NOT part of
this skill.
