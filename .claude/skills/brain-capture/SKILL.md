---
name: brain-capture
description: Use during work in this trading-playground repo to capture noteworthy moments into the knowledge brain. Decisions and hard rules write immediately with dedup; observations and findings batch as draft artifacts in .brain-drafts/ for later review via /brain-sweep.
---

# brain-capture

Project-scoped skill for the trading-playground repo. Adds structure to
how a Claude session contributes to the knowledge brain: tiered inline
capture during the session, plus an explicit sweep at the end.

This skill layers on top of the root `CLAUDE.md` brain protocol. The root
file says *when* to query/write; this file says *how to tier, draft, and
sweep*.

## Sections

The rest of this file is added in subsequent tasks:

- §1 Tier classification
- §2 Inline-immediate protocol
- §3 Inline-batch protocol and draft format
- §4 Sweep protocol
- §5 Inferred-trigger heuristic
- §6 Don't-draft-this rules
- §7 Edge cases

## §1 Tier classification

Every brain-worthy moment falls into one of two tiers. Decide tier
*before* writing anything.

**IMMEDIATE tier — write to brain right now:**

- Explicit decisions: "let's never X", "we've decided X", "X is
  non-negotiable", "going forward X"
- Hard rules — anything carrying confidence ≥ 0.95
- Constraints that would belong in a strategy spec (e.g. "no pyramiding",
  "skip session if VIX > 35")
- Risk-veto contracts and architectural layering rules

**BATCH tier — write a draft artifact for sweep review:**

- Empirical observations from this session ("today's open slippage felt
  closer to 0.4 ticks than 0.25")
- External references shared in conversation (paper quotes, book excerpts)
- Findings from analysis we did together this session
- Anything carrying confidence < 0.95

If unsure: default to BATCH. Drafts can be promoted to immediate writes
during sweep; rushed immediate writes can't be unwound.

## §2 Inline-immediate protocol

When an IMMEDIATE-tier moment is detected:

1. Pick the **most distinctive keyword** from the content. Heuristic:
   highest-information noun. Strategy names (`supertrend`), instruments
   (`mes`), parameters (`atr`), or domain nouns (`slippage`, `drawdown`)
   beat verbs and adjectives. If ambiguous, fall back to the most
   specific tag.
2. Run `brain_query(<keyword>)` (single keyword — multi-word phrases
   miss; see root `CLAUDE.md`).
3. Show the user the proposed write *and* any related existing nodes:

   ```
   Proposed brain_write:
     content: "<exact content>"
     tags: [<tags>]
     source_type: <human | session>
     source_ref: <ref>
     confidence: <>=0.95>

   Existing related nodes (top 3):
     kn-<id1>  conf <c>  "<one-line excerpt>"
     kn-<id2>  ...

   Write new / supersede <id> / skip?
   ```

4. On `write new` → call `brain_write` with the proposed payload.
5. On `supersede <id>` → call `brain_write` with `supersedes: <id>` (or
   the current `brain_write` semantic equivalent — note the original
   node id in the new node's content if no native field exists).
6. On `skip` → drop it. No file written.

**Confidence regression guard.** If the proposed `supersede` lowers
confidence (new < existing), surface it explicitly:
*"This would lower confidence from 0.95 → 0.7. Confirm?"* Don't silently
regress.

## §3 Inline-batch protocol

When a BATCH-tier moment is detected:

1. Compose the draft content as if it were the body of a brain node — one
   atomic fact, written so the exact string can pass to `brain_write`.
2. Pick a slug: 3-5 hyphenated lowercase words capturing the topic
   (e.g. `mes-open-slippage`, `atr-period-comparison`).
3. Build the filename: `<ISO-timestamp>-<slug>.md`. Timestamp format:
   `YYYY-MM-DDTHH-MM-SS` (e.g. `2026-04-25T10-04-12-mes-open-slippage.md`).
   On collision append `-2`, `-3`.
4. Write the file under `.brain-drafts/`. Create the directory if it
   doesn't exist.
5. Mention the draft in **one** line of conversation:
   *"Drafted to brain buffer: `<slug>`."* Do not ask for approval.
   Continue the conversation.

### Draft frontmatter spec

Every draft artifact has YAML frontmatter followed by content:

```yaml
---
tags: [<lowercase-hyphenated>, ...]
source_type: human | session | ingestion
source_ref: <citable-origin-or-session-tag>
confidence: <0.0-1.0>
tier: batch
dedup_check: <true if confidence >= 0.8 else false>
supersedes: null
---
<one atomic fact, plain prose, no headings>
```

**Field rules:**

- `tags` must follow existing patterns. Query the brain with broad terms
  before inventing new tags; reuse over invent.
- `source_type` is `human` if the user told you directly, `session` if
  derived from this conversation's analysis, `ingestion` if extracted
  from a doc/source the user shared in chat.
- `source_ref` is a citable origin string. For session-derived items,
  use `session:<YYYY-MM-DD>_<topic-slug>`. For user-cited papers/docs,
  use the format from the seeded nodes (e.g. `Aronson 2007, Ch.6`).
- `confidence`: 0.95+ for hard rules (but those are immediate-tier, not
  batch); 0.7-0.85 for empirical findings; 0.5-0.7 for observations and
  hypotheses.
- `dedup_check` is set to `true` automatically when `confidence >= 0.8`,
  which gates the dedup query during sweep.
- `supersedes` is `null` at draft time. Sweep populates it if a dedup
  match is chosen.

A working reference artifact lives at `example-draft.md` in this
directory.
