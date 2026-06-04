# Scoring Rubric

Each baseline and candidate output is scored from 0 to 100. Score the generated
Spec Kit artifacts, not the agent personality or terminal transcript.

## Evaluation Target

The benchmark evaluates how well an agent follows the selected Spec Kit skill
workflow for the scenario prompt and skill command. The expected artifacts and
quality patterns are defined by that selected skill.

Do not score against an unstated ideal artifact style. Score against the
combination of:

- the scenario prompt,
- the loaded Spec Kit skill instructions and templates,
- the generated Spec Kit artifacts,
- this rubric.

Skill-compliant patterns must not be treated as defects merely because a
different skill, stricter evaluator, or narrower artifact style would avoid
them. For example, if a selected skill asks for measurable outcomes, documented
assumptions, clarification questions, implementation plans, task checklists, or
cross-artifact analysis, those patterns are valid for that run when they are
plausible and consistent with the scenario and skill.

Penalize skill-compliant patterns only when they:

- conflict with the scenario,
- introduce implementation details or platform choices,
- are unreasonable for the selected skill and requested artifact,
- create unsupported product commitments that materially change scope,
- are internally inconsistent with the rest of the artifact set,
- or are marked as validated despite unresolved quality issues.

## Categories

Before scoring, define the selected skill's scoring profile:

- required artifacts and prerequisite artifacts,
- primary artifact-quality dimension,
- scenario/coverage dimension,
- scope/risk/assumption dimension,
- validation/readiness dimension,
- any skill-specific category mapping notes.

Use the generic point allocation below for every skill, but interpret each
category through that selected skill profile.

### Workflow Completion (20 points)

- 20: Full workflow completed and all expected artifacts were produced.
- 15: Artifacts produced, but one required metadata or checklist detail is weak.
- 10: The main artifact exists, but required supporting artifacts or pointers
  are missing.
- 0: Workflow did not complete or no usable artifact was produced.

Expected artifacts for `/speckit-specify` runs:

- `specs/<feature-id>/spec.md`
- `specs/<feature-id>/checklists/requirements.md`
- `.specify/feature.json`

For other Spec Kit skills, replace this list with the artifacts required by the
selected skill command and its prerequisites.

### Primary Artifact Quality (25 points)

- 25: The primary artifact is clear, complete, internally consistent, and fits
  the selected skill.
- 18: The primary artifact is mostly clear but misses some important expected
  behavior, decisions, analysis, or task detail.
- 10: The primary artifact is vague, mixed with inappropriate detail, or
  incomplete for the selected skill.
- 0: The primary artifact is absent or unusable.

Reasonable defaults or required sections requested by the skill are not defects
by themselves. Penalize them only when they are harmful under the evaluation
target above.

### Scenario And Coverage Quality (20 points)

- 20: The artifact covers the selected skill's main scenario, dependency, or
  acceptance surface in a way that is independently reviewable.
- 15: The artifact covers the main surface but has weak prioritization,
  dependency handling, or testability.
- 10: Coverage is shallow, repetitive, or misses important flows,
  dependencies, risks, or acceptance cases.
- 0: Coverage is absent or not actionable.

For skills that do not produce user stories or acceptance criteria, map this
category to the selected skill's scenario coverage, dependency coverage, or
acceptance coverage expectations.

### Scope, Assumptions, Risks, And Edge Cases (15 points)

- 15: Scope is bounded, assumptions are explicit, and meaningful edge cases are
  identified.
- 10: Some assumptions or edge cases are present but important ones are missing.
- 5: Scope is unclear or assumptions are mostly implicit.
- 0: Scope and edge cases are absent.

Assumptions, edge cases, risks, dependencies, and constraints should be scored
according to the selected skill. Do not penalize an inferred default solely
because the exact value was not supplied in the scenario prompt when the skill
asks the agent to make informed guesses or document assumptions.

### Validation Criteria And Readiness (10 points)

- 10: Validation criteria, readiness criteria, or success criteria are
  measurable or objectively reviewable, skill-appropriate, and scenario-aligned.
- 7: Criteria are present but incomplete or uneven.
- 4: Criteria are vague or partly inappropriate for the selected skill.
- 0: Criteria are absent or unusable.

For `/speckit-specify`, measurable success criteria, including reasonable
numeric criteria, are valid when they are user-facing, technology-agnostic,
reasonable, and do not conflict with the scenario. For other skills, map this
category to the selected skill's expected validation criteria, planning
constraints, task readiness criteria, or analysis metrics.

### Validation Discipline (10 points)

- 10: Validation output is complete, aligned with the artifacts, and honestly
  reflects artifact quality.
- 7: Validation output is present but generic or lightly justified.
- 4: Validation output exists but misses important issues.
- 0: Validation output is missing or not relevant.

Validation artifacts should validate against the selected skill's quality
criteria and the scenario. Penalize overclaiming when an output marks an item as
passed or ready despite unresolved issues under this rubric, but do not require
validation artifacts to fail items for skill-compliant patterns.

## Finding Severity

Use these severity levels in comparison reports:

- **Critical**: Prevents workflow completion or makes the spec unusable.
- **Major**: Materially weakens correctness, completeness, or testability.
- **Minor**: Local issue that should be fixed but does not invalidate the spec.
- **Preference**: Style or wording difference with no clear quality impact.

Only Critical and Major findings should normally drive prompt optimization.
