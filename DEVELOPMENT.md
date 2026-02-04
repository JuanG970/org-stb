# Development Guide

## Quick Start

```bash
# Run tests
./run-tests.sh

# Or run manually with Emacs
emacs -batch -l ert -l org-stb.el -l org-stb-test.el -f ert-run-tests-batch-and-exit
```

## TDD Workflow

1. **Write a failing test** in `org-stb-test.el`
2. **Run tests** to confirm it fails: `./run-tests.sh`
3. **Implement the feature** in `org-stb.el`
4. **Run tests** to confirm it passes
5. **Refactor** if needed (keep tests green)
6. **Commit** changes

## Code Style

- Use `lexical-binding: t`
- Prefix all functions with `org-stb-`
- Document all public functions with docstrings
- Keep functions small (under 20 lines)
- One function, one purpose (KISS)

## Testing Guidelines

- Test naming: `org-stb-test-<feature-name>`
- Use `should` for assertions
- Use `should-error` for expected errors
- Mock external dependencies when possible
- Keep tests fast (< 1 second each)

## Project Structure

```
org-stb/
├── org-stb.el          # Main implementation
│   ├── Core functions (shift-time, shift-hours)
│   ├── Interactive commands (shift-1-hour, etc)
│   └── Minor mode setup
├── org-stb-test.el     # Test suite
│   ├── Helper functions
│   ├── Unit tests
│   └── Integration tests
├── run-tests.sh        # Test runner
├── README.md           # User documentation
└── DEVELOPMENT.md      # This file
```

## Adding New Features

### Example: Add "shift by days"

1. **Write test first:**
```elisp
(ert-deftest org-stb-test-shift-days ()
  "Test shifting by days."
  (should (fboundp 'org-stb-shift-days))
  (should (commandp 'org-stb-shift-days)))
```

2. **Run test (should fail):**
```bash
./run-tests.sh
```

3. **Implement feature:**
```elisp
(defun org-stb-shift-days (days)
  "Shift the current agenda item by DAYS."
  (interactive "nShift by days: ")
  (org-stb-shift-time (* days 24 60)))
```

4. **Run test (should pass):**
```bash
./run-tests.sh
```

5. **Add to README and keybindings**

## Debugging

### Interactive testing in Emacs

```elisp
;; Load the package
(load-file "~/PersonalProjects/org-stb/org-stb.el")

;; Run a specific test
(ert 'org-stb-test-shift-hours)

;; Run all tests
(ert t)
```

### Enable edebug

Add `(debug)` in your function and run interactively.

## Performance

- Keep time complexity O(1) for single-item operations
- Keep time complexity O(n) for batch operations
- Avoid unnecessary agenda redraws
- Cache when possible

## Future Architecture

As we add simple line balancing:

```
org-stb/
├── org-stb.el              # Core time shifting
├── org-stb-balance.el      # Line balancing algorithms
├── org-stb-deps.el         # Dependency handling
└── org-stb-conflict.el     # Conflict resolution
```

Each module should:
- Be independently testable
- Follow KISS principle
- Reuse core functions (DRY)
- Have comprehensive tests (TDD)
