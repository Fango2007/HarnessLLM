# Scoring Rubric

Each baseline and candidate output is scored from 0 to 100. Score the generated
Spec Kit artifacts, not the agent personality or terminal transcript.

## Categories

### Workflow Completion (20 points)

- 20: Full workflow completed and all expected artifacts were produced.
- 15: Artifacts produced, but one required metadata or checklist detail is weak.
- 10: Main spec exists, but checklist or feature pointer is missing.
- 0: Workflow did not complete or no usable spec was produced.

Expected artifacts:

- `specs/<feature-id>/spec.md`
- `specs/<feature-id>/checklists/requirements.md`
- `.specify/feature.json`

### Requirement Quality (25 points)

- 25: Requirements are clear, testable, complete, and technology-agnostic.
- 18: Requirements are mostly clear but miss some important behavior or edge
  cases.
- 10: Requirements are vague, mixed with implementation details, or incomplete.
- 0: Requirements are absent or unusable.

### User Scenarios And Acceptance Criteria (20 points)

- 20: Prioritized user stories are independently testable and cover the main
  user value.
- 15: User stories cover the main flow but have weak prioritization or tests.
- 10: Scenarios are shallow, repetitive, or miss important flows.
- 0: Scenarios are absent or not actionable.

### Scope, Assumptions, And Edge Cases (15 points)

- 15: Scope is bounded, assumptions are explicit, and meaningful edge cases are
  identified.
- 10: Some assumptions or edge cases are present but important ones are missing.
- 5: Scope is unclear or assumptions are mostly implicit.
- 0: Scope and edge cases are absent.

### Success Criteria (10 points)

- 10: Success criteria are measurable, user-focused, and technology-agnostic.
- 7: Criteria are measurable but incomplete or uneven.
- 4: Criteria are vague or partly implementation-focused.
- 0: Success criteria are absent or unusable.

### Validation Discipline (10 points)

- 10: Checklist is complete, aligned with the spec, and honestly reflects
  artifact quality.
- 7: Checklist is present but generic or lightly justified.
- 4: Checklist exists but misses important issues.
- 0: Checklist is missing or not relevant.

## Finding Severity

Use these severity levels in comparison reports:

- **Critical**: Prevents workflow completion or makes the spec unusable.
- **Major**: Materially weakens correctness, completeness, or testability.
- **Minor**: Local issue that should be fixed but does not invalidate the spec.
- **Preference**: Style or wording difference with no clear quality impact.

Only Critical and Major findings should normally drive prompt optimization.
