# Contributing

---

## Code of conduct

This is a corporate security awareness tool. Treat all contributors and content with professionalism.

---

## Before you start

1. Read `PRODUCT_SPEC.md`, `ARCHITECTURE.md`, and `CLAUDE.md` (or `AGENTS.md` for backend work).
2. Check for an open issue or draft PR that covers your change.
3. For new features, open a discussion issue before writing code.
4. No agent may merge its own pull request. Human review is required on every PR.

---

## Branch naming

```
feature/<short-description>
fix/<short-description>
docs/<short-description>
chore/<short-description>
```

---

## Commit messages

```
<type>(<scope>): <short description>

Body (optional): explain the why, not the what.
```

Types: `feat`, `fix`, `docs`, `test`, `chore`, `refactor`, `security`

---

## Pull request checklist

Before opening a PR:

- [ ] All tests pass locally
- [ ] `flutter analyze` passes (Flutter changes)
- [ ] `dart format --set-exit-if-changed .` passes (Flutter changes)
- [ ] `npm run type-check && npm run lint` passes (admin portal changes)
- [ ] `ruff check && mypy` passes (backend changes)
- [ ] No secrets, credentials, or PII in the diff
- [ ] Localization keys added for all new user-visible strings
- [ ] Accessibility considered
- [ ] Documentation updated if behavior changed
- [ ] Threat model updated if data flows changed

---

## Adding a new dependency

1. Justify the dependency in the PR description.
2. Check the license is compatible with corporate policy.
3. Run dependency scan before merging.
4. Update `docs/adr/` with an ADR if it is an architectural dependency.

---

## ADR process

Any significant technology or architecture decision requires an Architecture Decision Record in `docs/adr/`. Use the template at `docs/adr/TEMPLATE.md`. ADRs are accepted by the product owner, not individual contributors.
