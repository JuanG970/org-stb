# org-stb roadmap — prioritized backlog

Planning artifact only: no code, tests, or configuration are changed by this
document. Findings were gathered on 2026-11-01 from `d815df9` (master) with
GNU Emacs 29.3 and Org 9.6.15 on Linux.

## How the evidence was collected

- `./run-tests.sh` — 10 tests, 10 "as expected", 0 unexpected.
- `grep -n "fboundp\|commandp" org-stb-test.el` — every assertion checks only
  that a symbol is bound or interactive.
- Byte-compilation: `emacs -batch -Q -L . -f batch-byte-compile org-stb.el` —
  no warnings, no errors.
- Behavior probes in `emacs -batch -Q`: build a real `*Org Agenda*` buffer from
  a three-entry org file, then call the public commands and inspect the
  visiting buffer. Probe outputs are quoted verbatim below.

## P0 — Replace existence-only tests with behavioral assertions

**Problem.** The suite is green but cannot fail. `org-stb-test-shift-time-forward`
binds `original` from `org-stb-test--get-scheduled-time` and never compares it;
the assertion is `(should (fboundp 'org-stb-shift-time))`. Its own comment says
full timestamp testing "requires org-agenda context". The other nine tests are
`fboundp`/`commandp`/keymap lookups.

**Evidence.** `./run-tests.sh` passes 10/10 while the batch defect and the
deadline-only no-op below both escape detection.

**Proposed change.** Add an ERT fixture that creates a temp org file, sets
`org-agenda-files`, calls `org-agenda-list`, moves to a known agenda line, runs
the command, and asserts the exact heading/timestamp text after the call.
Cover: forward and backward single shifts, a shift on a scheduled line, and a
non-agenda call signalling `user-error`.

**Acceptance criteria.**
- At least five tests assert resulting buffer text, not symbol existence.
- Deliberately breaking `org-stb-shift-time` (returning nil) makes the suite fail.
- `org-stb-test--get-scheduled-time` is either used in assertions or removed.

## P1 — Handle deadline-only agenda items instead of doing nothing

**Problem.** `org-stb-shift-time` reads only the `SCHEDULED` property. Agenda
lines generated from `DEADLINE` still call it, so the command silently returns
without moving anything or telling the user.

**Evidence.** Probe with `* TODO DeadlineOnly` / `DEADLINE: <2026-02-04 Wed 15:00>`:
agenda line `Deadline: TODO DeadlineOnly`; `SCHEDULED` is nil and `DEADLINE` is
set; after `org-stb-shift-time 60` the command "returned without error" and the
file buffer was byte-identical.

**Proposed change.** Resolve the timestamp to shift from the marker position
(or fall back `SCHEDULED` → `DEADLINE`), shift exactly that timestamp, and show
a clear message when an entry has neither.

**Acceptance criteria.**
- A deadline-only agenda line shifts its `DEADLINE` by the requested minutes.
- An entry with no timestamp at all signals a `user-error` with a readable message.
- Tests cover both paths and assert the resulting text.

## P1 — Make batch shifting count entries, not agenda lines

**Problem.** `org-stb-shift-all-forward` counts agenda lines that carry an
`org-marker`, so an entry with both `SCHEDULED` and `DEADLINE` is reported
twice, and the "Shifted N items" message overstates the work.

**Evidence.** Three entries (two scheduled, one scheduled plus deadline) gave
`Shifted 4 items by 30 minutes`; the buffer then held four moved timestamps,
including the deadline of entry three.

**Proposed change.** Deduplicate markers/entries before shifting (or collect
unique markers first), shift each entry once, and report the unique-entry
count. Decide and document whether shifting an entry moves its deadline as
well; implement that decision in one place.

**Acceptance criteria.**
- Same three-entry fixture reports `Shifted 3 items`.
- Each entry's `SCHEDULED` and agreed companion timestamp move exactly once.
- A behavioral test pins both the message and the final buffer text.

## P2 — Packaging and CI baseline

**Problem.** The package cannot be published or trusted as-is: the header URL
is `https://github.com/yourusername/org-stb`, the README tells users to clone
into `~/PersonalProjects/org-stb`, there is no `LICENSE`, no `.github/`
workflow, and no package descriptor beyond the `;; Version:` header.

**Evidence.** File listing at `d815df9`: `.gitignore`, `DEVELOPMENT.md`,
`README.md`, `SUMMARY.md`, `examples.el`, `org-stb-test.el`, `org-stb.el`,
`run-tests.sh`. The byte-compile probe is clean, so a two-command CI job
(byte-compile plus `./run-tests.sh`) needs no extra tooling.

**Proposed change.** Fix URL and install instructions, add a license file
consistent with the author's intent, and add one GitHub Actions workflow
running byte-compilation and the ERT suite on `ubuntu-latest` with the
distribution Emacs. No secrets, no network beyond package setup.

**Acceptance criteria.**
- Header URL and README resolve to the real repository path.
- A license file exists and is referenced from the README.
- CI runs on push and pull request and fails on a deliberately broken test.

## P2 — Remove documentation drift

**Problem.** `SUMMARY.md` is a one-off implementation report that duplicates
`DEVELOPMENT.md` and documents a personal Doom config snippet that is not part
of the package; `DEVELOPMENT.md` still shows a `should (fboundp ...)` example
as the recommended test pattern, which contradicts P0.

**Evidence.** `SUMMARY.md` lines 1–40 describe `~/.doom.d/config.el` changes;
`DEVELOPMENT.md` "Example: Add shift by days" writes an existence test.

**Proposed change.** Fold anything still useful into `DEVELOPMENT.md`, delete
`SUMMARY.md`, and update the TDD example to a behavioral assertion.

**Acceptance criteria.**
- `SUMMARY.md` removed or reduced to a changelog pointer.
- The DEVELOPMENT.md example test fails when the feature is absent.
- README feature list matches implemented commands.

## Deferred — README "Planned" features

Line balancing, dependency-aware rescheduling, gap detection, and conflict
resolution stay out of scope until P0 and P1 land. Each should arrive as its
own issue with behavioral tests and a documented definition of "balanced";
none has a date or commitment here.
