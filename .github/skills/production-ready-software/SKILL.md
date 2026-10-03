---
name: production-ready-software
description: Interview the owner and plan, build, or harden new or existing software for a production release. Use when asked to define a product, make an existing app production-ready, audit readiness, or guide an agent through specification, verification, and release.
---

# Production-ready software

Guide the owner from an idea or an existing codebase to an explicitly approved specification, an executable delivery plan, and evidence-based release decisions. This is an interactive process, not a promise of bug-free software. Do not mistake generated code, a passing test suite, or a polished UI for production readiness.

## Operating rules

- Start by asking whether this is a **new product** or an **existing product**, the intended audience and deployment environment, and whether the owner wants **planning only**, a **readiness assessment**, or **implementation after approval**. Ask where the specification should live; propose `docs/production-readiness.md` in the target repository if they have no preference. Do not create or modify files in a different repository without access and permission.
- For an existing product, inspect available source, README, configuration, tests, CI, deployment instructions, and issue reports before proposing changes. Separate **observed facts** (cite paths or commands), **owner-stated requirements**, **unknowns**, and **proposals**. Do not assume a feature works because documentation says it does. Preserve working behavior unless the owner approves a change.
- Interview in manageable batches, one stage at a time. Ask concrete questions relevant to the product; suggest options and trade-offs when the owner is unsure. Record each applicable topic as decided, deferred with an owner and follow-up gate, or explicitly not applicable with a reason. Never silently default a consequential decision. Follow up on contradictory, vague, or unanswered requirements. Do not request passwords, tokens, production data, or other secrets.
- At the end of **every stage**, summarize decisions, assumptions, open questions, risks, and the proposed next stage. Ask the owner to correct anything wrong and explicitly confirm that stage before moving on. A prior "make it production-ready" request is **not** stage approval. If the owner changes a confirmed decision, update downstream decisions and obtain fresh confirmation. Do not proceed while blocking questions remain. Stop and wait for a reply; do not simulate the owner's answer.
- Before **any implementation**, present the complete consolidated specification and prioritized plan, including acceptance criteria, verification, rollout, and rollback. Ask for explicit approval of both the spec and plan and separately confirm authorization to edit code. Planning approval does not authorize a release or destructive operation. Respect any higher-priority restrictions on edits or tools.
- Persist the confirmed specification and decisions in **one Markdown file** at the approved path in the target repository, updating that file in place. For a planning-only request, provide the plan in the conversation first; write the file only if file creation is requested or explicitly approved. Never put secrets or private user data in the document. If the conversation ends early, offer a checkpoint of confirmed decisions and unanswered questions rather than inventing answers.

## Interview stages and confirmation gates

Use these stages in order. Adapt wording and depth to the product; ask about all applicable aspects, including user-visible failure paths. Each gate requires the owner to review a recap and say explicitly that it is correct before continuing.

### 1. Outcome and scope

Ask: What problem is solved, for whom, and why now? Who owns product and technical decisions? What constitutes success, and what is explicitly out of scope? What is the first supported release, its constraints, and its must-have versus later features? Is this a prototype, internal tool, public service, desktop/mobile app, library, or regulated product? Who is allowed to use it and how many concurrent users or installations are expected?

For existing software, ask what already works, what fails (with reproducible steps), what must not change, and what existing users and data must be preserved. Inventory observed behavior and gaps; avoid recommending a rewrite without evidence.

**Gate:** Confirm users, outcomes, scope, current-state facts, and unresolved constraints.

### 2. User journeys and interaction contract

Ask for each role and critical journey: entry point, prerequisites, steps, buttons and navigation, expected visible result, failure messages, recovery, cancellation, retry, and accessibility needs. Include empty/loading/offline states, invalid input, double submission, stale state, keyboard and touch if applicable. What is the intended appearance and usability bar? Which browsers, devices, OS versions, languages, locales, and assistive technologies are supported?

For every must-have interaction, define observable acceptance criteria (including negative cases) and identify the human who will approve the experience. Do not mark a journey complete merely because an endpoint responds.

**Gate:** Walk through the journeys and confirm the interaction/visual criteria, exclusions, and unanswered UX decisions.

### 3. Data, integrations, and architecture

Ask: What data is collected, stored, shared, retained, exported, and deleted? What is the source of truth and how are migrations and backups handled? Which external APIs, payments, files, emails, local processes, or devices are involved? What are the expected volumes, performance budgets, availability needs, concurrency, timeouts, and offline behavior? Where will it run (each user's machine, a private network, or a public service)? Who installs, updates, and uninstalls it?

For existing software, map actual components, dependencies, storage, entry points, deployment topology, and known technical debt. Distinguish observed implementation from the desired design. Identify compatibility, data migration, and rollback needs before proposing structural changes.

**Gate:** Confirm the system boundary, data lifecycle, supported environments, and integration failure behavior.

### 4. Safety, privacy, and operations

Ask about authentication and authorization (or why not needed), least privilege, secret management, input validation, dependency and supply-chain risk, abuse or misuse cases, and the impact of any destructive or automated action. Ask what sensitive information enters logs or telemetry, what consent and privacy obligations apply, and whether legal/compliance review is needed; refer legal determinations to qualified people. Ask who owns monitoring, support, incident response, backup restore tests, updates, security patches, and end-of-life.

Require a documented threat and failure review appropriate to the deployment. For local software, still consider browser-to-local-service requests, permissions, terminal/process actions, and risks to files on the user's machine. For public software, include network exposure, account lifecycle, rate limiting, and tenant boundaries where relevant.

**Gate:** Confirm security boundaries, privacy decisions, operational owners, and any release blockers.

### 5. Quality strategy and delivery plan

Ask what validation already exists and what has actually run. Agree on tests for critical business logic, integrations, UI journeys, installation/update/uninstall, supported environments, accessibility, performance, recovery, and security-sensitive paths. For every acceptance criterion, identify a verification method (automated, manual with steps, or both) and a responsible reviewer. Include test data, reproducible bug reports, regression tests for fixes, and a real-environment trial where mocks cannot establish correctness.

Propose prioritized, small deliverables with dependencies and explicit done criteria. For existing software, first capture baseline behavior and high-risk regressions; avoid unrelated feature work. Specify how agent changes will be reviewed by someone other than the implementing pass, which checks must pass, and what evidence will be recorded. Do not claim that any plan guarantees no bugs.

**Gate:** Present the consolidated specification and plan. Ask the owner to approve **both** explicitly and, if requested, separately authorize implementation. Do not begin editing code before authorization.

### 6. Implement, verify, and release (only when authorized)

Work through one approved deliverable at a time. Before each deliverable, restate its scope, acceptance criteria, and verification; ask for confirmation if scope or risk changed. Use the project's existing tooling and conventions. Test as early as possible; report commands, results, untested paths, and limitations honestly. Review regressions and security implications. Demonstrate key interactions in the supported environment, and ask the owner to verify that the actual behavior matches expectations before moving to the next deliverable.

For release, require an owner-approved checklist: tests and manual journeys passed, supported-environment trials, installation/upgrade/rollback validated, backups and restore checked where applicable, security/privacy issues triaged, documentation and known limitations accurate, monitoring/support owner identified, and staged rollout/feedback plan agreed. Mark unmet items as blockers or explicitly accepted risks with an owner; never silently waive them. Ask for separate explicit approval before deployment, publishing, destructive migrations, or enabling automatic actions.

**Gate:** Record evidence, outstanding risks, release decision, and post-release follow-up. If a gate fails, fix or revise the plan and reconfirm it.

## Specification file structure

Keep the approved Markdown file readable and actionable, not a transcript. Update it after each confirmed stage when writing is authorized:

1. Status and scope (new/existing, planning/implementation, stage approvals).
2. Product goals, stakeholders, supported environments, exclusions, and success measures.
3. Existing-state inventory with evidence (if applicable).
4. Roles, user journeys, interaction states, and testable acceptance criteria.
5. Data lifecycle, architecture/integrations, nonfunctional targets, and compatibility.
6. Security, privacy, operational responsibilities, and threat/failure review.
7. Test matrix linking each critical criterion to a method, owner, and result/evidence.
8. Ordered deliverables, dependencies, verification gates, rollout, and rollback.
9. Decisions, assumptions, open questions, deferred items, risks, and explicit owner sign-offs.

Use `Not applicable — <reason>` rather than leaving sections empty. Label unverified claims clearly and keep a dated decision trail when requirements change. Do not mark a check passed without evidence. When transferred to another repository, use the same skill to interview that product independently; never copy this project's assumptions into it.
