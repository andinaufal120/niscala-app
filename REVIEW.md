# Review instructions

Key words in all capitals (MUST, SHOULD, MAY, etc.) follow BCP 14 (RFC 2119, RFC 8174), as in `CLAUDE.md`.

## What Important means here

Reserve Important for findings that would break behavior or break a project rule that `CLAUDE.md` marks MUST or MUST NOT:

- Incorrect logic, crashes, or data loss
- Re-implementing a backend rule instead of rendering what the API returns
- Hand-edits to the generated API client
- Changes under `test/` in an implementation commit
- Code that contradicts `docs/SPEC.md`
- English glossary terms shown in the UI
- Breaking a rule in `docs/ACCESSIBILITY.md` §2. For UI changes, check the §3.3 items by reading the diff; tests don't catch them.

Doc drift SHOULD be marked Important: a PR that changes behavior, structure, or conventions described in `docs/SPEC.md`, `docs/ACCESSIBILITY.md`, `ARCHITECTURE.md`, `CLAUDE.md`, or `REVIEW.md` without updating that doc in the same PR. `README.md` drift is Nit.

Report findings only. Don't edit code, push commits, or apply fixes unless explicitly told to.

Everything else, including style, naming, and refactoring suggestions, is Nit at most.

## Don't push complexity

The project favors the simplest code that satisfies the request. Don't report:

- Missing abstractions, extension points, or configurability for cases the spec doesn't require
- Extra validation, error handling, or defensive checks for situations that can't occur
- Alternative designs that are equivalent rather than better

A suggestion that adds code without fixing a real defect is not a finding.

## Cap the nits

Report at most three Nits per review. If you found more, say "plus N similar items" in the summary instead of posting them inline. If everything you found is a Nit, lead the summary with "No blocking issues."

After the first review of a PR, post Important findings only.

## Do not report

- Anything `flutter analyze` or `dart format` already enforces
- Generated files, `pubspec.lock`, and anything under `build/` or `.dart_tool/`
- Failing tests in a test-only commit from `test-writer`, as long as the PR's final commit passes
