# Extra rules: you are working on an EXISTING project

This folder is a copy of Damen's real project. Treat it with care.

## Where things are
- The plan: {{PLAN}}
- Your notes (status, decisions, NEEDS_DAMEN, REPORT, DONE): {{META}}/  (outside the code - never commit them into the code)
- You are on git branch **{{BRANCH}}**. Stay on it. Never switch branches, never merge, never rebase other branches,
  never rewrite history, never push (the runner saves and hands back your branch for you).

## Before changing anything
1. Read the project's own guidance first if present: CLAUDE.md, AGENTS.md, README*, CONTRIBUTING*, docs/.
   Its rules and conventions win over your preferences. Anything it marks as protected/approved/frozen: do not touch.
2. Find out how to run its tests and checks, and run them once to see the starting state.
   Record the starting state (what passes, what fails) at the top of {{META}}/status.md.
3. Look at recent history (`git log --oneline -20`) to see what was done before.

## While working
- Make the smallest changes that achieve the plan. Don't reformat, rename or "tidy" code the plan doesn't need.
- Match the existing style, structure and tools. Don't add new frameworks or big dependencies without asking GPT.
- Every fix gets a test that would have caught it (regression test), where the project has tests.
- Commit in small steps with clear messages.
- The plan's own boundaries (e.g. "no production changes", "no real model calls") are hard rules.
- Don't start, stop or connect to anything already running on this machine (containers, services, databases).
  You MAY run the project's own tests in your private Docker (see the Docker rule), including integration tests
  that need disposable databases/containers.
  If a check needs something you can't run here (e.g. real credentials, real model calls), don't fake it:
  write it down under "Couldn't check here" in the report with exactly what Damen needs to run.

## Finishing (instead of "MVP done")
You're done when the plan's tasks are complete and the project's tests pass (or you've explained exactly why one can't
pass here). The REPORT.md must also include:
- Branch name and a short list of commits
- What changed and why (plain English)
- Test results: before vs after
- "Couldn't check here" list, with exact commands for Damen
- Anything Damen must decide before merging
