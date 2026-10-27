<img src="https://simgen.dev/agentdecoy/logo.svg" width="72" height="72" alt="AgentDecoy logo">

# AgentDecoy scan

[![Marketplace](https://img.shields.io/badge/GitHub%20Marketplace-AgentDecoy%20scan-d4a017?logo=github)](https://github.com/marketplace/actions/agentdecoy-scan) [![release](https://img.shields.io/github/v/release/KyleClouthier/agentdecoy-action?color=d4a017)](https://github.com/KyleClouthier/agentdecoy-action/releases) [![self-test](https://github.com/KyleClouthier/agentdecoy-action/actions/workflows/self-test.yml/badge.svg)](https://github.com/KyleClouthier/agentdecoy-action/actions/workflows/self-test.yml) [![leak clock](https://img.shields.io/badge/leaked%20AI%20key%20used%20in-3%20seconds-red)](https://simgen.dev/agentdecoy/leak-clock/)

> Free and open source. If it catches something for you, a star helps other people find it.

**Security for the AI-agent era, in your deploy pipeline.** This Action scans your site or app after every deploy the way a hostile AI agent would, and fails the build when it finds something the agent could steal, abuse or be told to do.

![AgentDecoy: scan, catch, identify, shut out](docs/agentdecoy-how-it-works.png)

An AI attack agent does not get tired. It asks thousands of sites for the same files (`.env`, `.git/config`, and now `.cursor/mcp.json` and `.mcp.json`), copies any key it finds, connects to any MCP or AI server that answers, and keeps going while its owner sleeps. On October 24, 2026 one took a decoy AWS key from our own site and used it to try for admin rights 2 hours 39 minutes later.

AI-built apps make this easy for them. One prompt can put a key in the browser, deploy the coding tool's config with the site, or ship source maps that hand over every prompt. This Action catches that before an agent does.

## What it checks

17 AI-era checks, in three groups. It does not check traditional items such as security headers or TLS: other tools cover those well.

| Group | Checks |
| --- | --- |
| **Steal** | Secret files left public (.env, .git, cloud keys, backups), keys in page code (17 formats, AI keys and the Supabase service_role key included), AI coding-tool configs (.cursor/mcp.json, .mcp.json, .vscode/mcp.json, .claude/settings.json), source maps, system prompts in page code, AI rule files (CLAUDE.md, AGENTS.md, .cursorrules) |
| **Abuse** | MCP servers answering without sign-in, self-hosted AI servers with no key (Ollama, OpenAI-compatible), AI called from the browser or open AI routes, unguarded login and sign-up forms, open API docs with write actions, dev servers in production, Supabase or Firebase keys in the page |
| **Trick** | Hidden or invisible instructions aimed at AI agents (hidden elements, HTML comments, Unicode tag characters), A2A agent cards, robots.txt lines that map private paths |

| Threat level | Means |
| --- | --- |
| **Critical** | Something an agent can take or use right now: a leaked key or file, an AI tool config, an open MCP or AI server, hidden orders for AI agents. Fix today. |
| **Elevated** | Something an agent can abuse or learn from: open forms, AI routes, source maps, a system prompt, open API docs, a dev server. |
| **Guarded** | Notes worth a look, such as a database key whose rules decide what is readable. |
| **Low** | Nothing found from the outside. |

This is the same scan as the free one at [simgen.dev/agentdecoy](https://simgen.dev/agentdecoy/). It only reads what any visitor can read: it never logs in, submits a form, calls an MCP tool or a model, or reads a database row.

## New: the repo check

A fake OpenAI key committed to a public GitHub repo was used **15 seconds** after the repo went public. The same key in a public Gist: **3 seconds**. ([live results](https://simgen.dev/agentdecoy/leak-clock/))

So the Action now also checks the repo it runs in, before anything is pushed or deployed: committed `.env` files, OpenAI, Anthropic, AWS, Stripe, GitHub, Slack and Google keys in tracked files, private key files, and AI tool configs (`.cursor/mcp.json`, `.mcp.json`, `.vscode/mcp.json`, `.claude/settings.local.json`) that carry tokens. It shows the file and line, never the full secret. It warns by default; set `repo-fail: true` to fail the build.

## Use

```yaml
name: AgentDecoy
on:
  push:
    branches: [main]
  schedule:
    - cron: '0 9 * * 1'   # every Monday
jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4          # needed for the repo check
      - uses: KyleClouthier/agentdecoy-action@v3
        with:
          site: example.com      # leave out to run only the repo check
          fail-on: elevated
          repo-fail: true
```

Run it after your deploy job (`needs: deploy`) so it scans what just went live.

## Inputs

| Input | Required | Default | What it does |
| --- | --- | --- | --- |
| `site` | no | | The site to scan. Leave it out to run only the repo check. |
| `repo-check` | no | `true` | Check the checked-out repo for committed secrets and AI tool configs with credentials |
| `repo-fail` | no | `false` | Fail the build when the repo check finds something (otherwise it warns) |
| `fail-on` | no | `critical` | Threat level that fails the build: `critical`, `elevated` or `guarded` |
| `api-key` | no | | An AgentDecoy Pro or Agency API key: 120 scans an hour instead of 10. Store it as a secret: `api-key: ${{ secrets.AGENTDECOY_KEY }}` |
| `min-grade` | no | | Older setting, still honoured: lowest defense grade that passes (A to F). Leave it out to use `fail-on`. |

## Outputs

| Output | What it holds |
| --- | --- |
| `threat-level` | `critical`, `elevated`, `guarded` or `low` |
| `ways-in` | How many critical and elevated findings |
| `findings` | The finding ids, comma separated, for example `script_secrets,open_mcp` |
| `score` | Defense score out of 100 |
| `grade` | Defense grade letter, kept for older workflows |
| `repo-findings` | How many committed secrets or AI tool credentials the repo check found |

Critical findings show as errors on the run page, elevated ones as warnings, and the run summary lists them all with a link to the full report and its fixes.

## Scanning finds the holes. Decoys catch who comes through them.

A scan tells you what an agent *would* find. [AgentDecoy](https://simgen.dev/agentdecoy/guard/) tells you who is actually trying, as it happens:

- **Catch.** Decoy keys, files, AI tool configs, logins, API docs, an MCP server and AI agent panels that look real and report back the moment anyone takes or uses them.
- **Identify.** Every catch is labelled a script, a person or an AI agent (response timing, verified Web Bot Auth signatures, how the fake login was filled), with how far it got and whose network it came from.
- **Shut out.** An address caught using a stolen secret on one protected site is refused on logins and forms across every protected site within the hour. Every site that joins makes every other site safer.

Free installs: `npm install agentdecoy` then `npx agentdecoy init` for Next.js, Vercel, Netlify, Firebase and Express ([source](https://github.com/KyleClouthier/agentdecoy)), a [WordPress plugin](https://simgen.dev/agentdecoy/guard/), and a Cloudflare Worker for closed builders. Public totals: the [Agent Attack Index](https://simgen.dev/agentdecoy/attack-index/).

## Details for the owner

The public result says what kind of thing was found and how many, never which file, key, tool or route, so the scan is no help to attackers. Install AgentDecoy on the site and the install proves it is yours: your dashboard then runs a free deep scan with every detail, up to 30 pages, and a count of which database tables a signed-out visitor can read (counts only, never rows). [Pro](https://simgen.dev/agentdecoy/#pricing) runs it every Monday and emails you the day a new way in opens. 7 days free.

Built by [Kyle Clouthier](https://simgen.dev/), Clouthier Simulation Labs. MIT licence.
