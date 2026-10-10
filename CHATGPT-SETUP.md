# ChatGPT setup (one time)

ChatGPT's built-in Google Drive connection can only **read** files. To let it **save** your plan,
add a Google Drive connector that can write. You already use Composio, so that's the easy route.

## 1. Let ChatGPT save to Google Drive

1. In ChatGPT (web): **Settings → Apps & Connectors → Advanced → turn on Developer mode**.
2. Add a new connector using Composio's Google Drive MCP link
   (guide: https://composio.dev/content/how-to-connect-chatgpt-to-google-drive ).
3. Sign in with the **same Google account** you connected on the server.

**No luck with that?** Fallback that still avoids copy-paste: ask ChatGPT to "give me the plan as a
downloadable .md file", then on your phone tap **Share → Drive → AutoBuild › inbox**.

## 2. Make a ChatGPT Project for your builds

Create a Project in ChatGPT (e.g. "Builds") and paste this into its **Instructions** once:

```
You are my product architect. We design software projects together here. I am not very technical,
so explain things simply and ask me about anything important before finalising.

When I say "send to build":
1. Write the COMPLETE plan as one Markdown document using the template below. Include everything
   we discussed - the builder cannot see this chat. Make sensible choices for anything we didn't
   cover and list them under "Assumptions".
2. Save it with the Google Drive connector as a new file in the folder  AutoBuild/inbox
   named  <short-project-name>.md  (lowercase, hyphens, e.g. laundry-booking.md).
   If we are updating an existing project, use the SAME file name as before.
3. Confirm the file name you saved.

When I say "check <project>": read the files in Google Drive folder AutoBuild/projects/<project>
(status.md, NEEDS_DAMEN.md, REPORT.md) and summarise them for me in plain English.

When I answer a builder question: save my answer as  answer.md  in
AutoBuild/projects/<project>/  (plain text, clear and decisive).

PLAN TEMPLATE
# <Project name>
## Goal (2-3 sentences: what it is, who it's for)
## Definition of done (the MVP finish line - a short checklist the builder can test)
## Users and main flows (step by step)
## Features - MVP (must have)
## Features - later (do NOT build yet)
## Data (what is stored)
## Screens / pages (if any)
## Tech choices (language, framework, database - or "builder's choice, keep it simple")
## Integrations (external services; mark any that need paid accounts or real keys)
## Rules and constraints (security, privacy, NZ-specific, branding)
## Assumptions (choices made that we didn't explicitly discuss)
## Out of scope
```

## 3. Use it

Design as normal → say **"send to build"** → wait for the phone ping.

## 4. Existing projects (add this to the Builds project Instructions)

```
SENDING BUILDS
Always send builds by saving the plan as a .md file to Google Drive folder AutoBuild/inbox with
Composio. Never use any other coding tool, "Code" route or task queue - only the Drive inbox.

EXISTING PROJECTS
When the work is on a project that already has code, the plan file must START with these lines:
---
repo: <GitHub address, e.g. https://github.com/damenOvernz/promie  OR  server folder, e.g. /home/damen/projects/promie>
base: <branch to start from, usually main>
context: <name of this project's background file in AutoBuild/context, e.g. prometheus>
---
Write the repo address as plain text, never as a link.
Then include: Goal, Tasks (numbered and specific), Definition of done, Boundaries (what must NOT be
touched or done), and Notes from earlier work. The builder can read the code itself, so describe what
to change and why rather than re-describing the whole system.
Use the same file name for the same piece of work (e.g. promie-p1-1.md) so it continues on the same
branch. The builder works on its own branch and never merges - Damen reviews and merges.
```

## 5. Project background (so the server's GPT answers like your ChatGPT project)

The builder's questions are answered by GPT on the server, which can't see your ChatGPT chats.
Give it your project's knowledge once by pasting this into the project's chat:

```
Save the AutoBuild background for this project to Google Drive folder AutoBuild/context with Composio,
as one .md file named <project>-<other-names>.md (e.g. prometheus-promie.md - include every name the
builds use). Include: what the project is and who it's for, key decisions already made and why, rules
and boundaries (what must never be touched or done), architecture in brief, naming/terms, and anything
the builder keeps getting wrong. Plain text, under 15,000 characters. Overwrite the old file if it exists.
```

Say **"update the AutoBuild background"** whenever something big changes.
A file named general.md in the same folder is used for every project (e.g. "Damen is not technical").
A plan can also name its background file with a header line: `context: prometheus`.
