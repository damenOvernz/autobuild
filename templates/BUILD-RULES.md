# AutoBuild rules (you are building unattended)

Damen is NOT watching. Never wait for input, never ask him questions in chat. Nobody will reply.

## Your job
Build what {{PLAN}} describes, in this folder, until it actually works.
- {{PLAN}} is the source of truth. If it has a "Definition of done" / finish line, that is your target.
  If it doesn't, write a sensible one at the top of {{META}}/decisions.md and work to it.
- Prefer simple, boring, well-known tools. Get something working end to end first, then fill in.

## Memory between sessions (important)
You work in rounds; each round is a fresh session. At the START of every round read:
  {{META}}/status.md, {{META}}/decisions.md
Keep {{META}}/status.md up to date as you go (short, plain English):
  - Done so far
  - Working on now
  - Next steps
  - Problems / blockers
Commit to git after each working milestone with a clear message.

## When you are unsure
1. Small choice (naming, library pick, layout detail): decide yourself, keep going.
2. Real product or design question (what a feature should do, which approach fits the plan):
   run in the shell:   ask-gpt "your question, with the context GPT needs"
   GPT is the architect who designed this with Damen. Follow its answer.
3. Log every meaningful decision in {{META}}/decisions.md as one line:
   `- [date] Decision - why (source: me / GPT / Damen)`

## When to stop and wake Damen
Write {{META}}/NEEDS_DAMEN.md and END the session immediately if:
- ask-gpt's answer starts with ESCALATE, or
- the next step needs: spending money, a paid service/account signup, real customer data,
  real passwords/API keys, legal/compliance calls, or deleting anything outside this folder, or
- you are truly blocked and GPT can't unblock you.
NEEDS_DAMEN.md must be short and plain English (Damen is not technical):
  - The question (one sentence)
  - Options (2-3, one line each)
  - Your recommendation and why
  - What you'll do once he answers
Don't stop for anything you can reasonably decide yourself or with GPT.

## Safety limits (never break these)
- Stay inside this project folder. Don't touch other projects or system settings.
- This machine also runs LIVE business services. Never stop, restart, reconfigure, connect to or
  send requests to anything you didn't start yourself. Before using a port, check it's free
  (e.g. `ss -ltn`); if it's taken, pick another free port in the 20000-29999 range.
- Don't deploy anything to the public internet, don't push to remote git repos.
- Never use real secrets. Use a .env.example with placeholders; use local/test databases and fake data.
- Don't install system-wide software with sudo. Project-level packages (npm, pip in a venv, etc.) are fine.
- If a test service needs a running server, start it, test it, then stop it.
- Docker: if `docker` works for you, it is AutoBuild's own PRIVATE Docker (separate from the server's real one).
  Use it only for disposable test containers/databases. Never use --network host, --privileged, or mount
  anything outside this project. Never try to reach /var/run/docker.sock or the server's main Docker.
  Remove what you start when you're done. If `docker` doesn't work, treat Docker-based checks as
  "couldn't check here" and list the exact commands for Damen.

## Finishing
The MVP is done only when you have VERIFIED it: it installs, starts, the core flows in the plan work,
and tests pass. Then:
1. Write {{META}}/REPORT.md in plain English for a non-technical reader:
   - What was built (short)
   - How to start it (exact commands, copy-paste ready)
   - What works / what's not done yet
   - Key decisions made (and which ones GPT made)
   - Suggested next steps
2. Create the empty file {{META}}/DONE
3. Commit everything to git.
