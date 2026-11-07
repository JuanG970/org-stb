# org-stb - Simple Time Balancing for Org Agenda

A lightweight Emacs package for rescheduling org-agenda items with ease.

## Philosophy

**Core Principles:**
- **KISS** (Keep It Simple, Stupid): Minimal, focused functionality
- **DRY** (Don't Repeat Yourself): Reusable, composable functions
- **TDD** (Test-Driven Development): Comprehensive test coverage using ERT

## Features

### Current (v0.1.0)

- ✅ Shift individual items by any time amount (minutes/hours)
- ✅ Shift `DEADLINE` when an item has no `SCHEDULED`, with a clear error when it has neither
- ✅ Shift all scheduled items in chain
- ✅ Predefined quick actions (1 hour, 30 min)
- ✅ Customizable time increments
- ✅ Backward shifts (move items earlier)

### Planned

- 🔄 Simple line balancing manufacturing scheduling
- 🔄 Dependency-aware rescheduling
- 🔄 Gap detection and filling
- 🔄 Time conflict resolution

## Installation

### Manual

1. Clone the repository:
```bash
git clone https://github.com/yourusername/org-stb.git ~/PersonalProjects/org-stb
```

2. Add to your Doom Emacs config (`packages.el`):
```elisp
(package! org-stb
  :recipe (:local-repo "~/PersonalProjects/org-stb"))
```

3. Add to `config.el`:
```elisp
(use-package! org-stb
  :after org-agenda
  :config
  (org-stb-setup))
```

## Usage

### Interactive Commands

In org-agenda buffers with `org-stb-mode` enabled:

| Keybinding | Command | Description |
|------------|---------|-------------|
| `C-c s h` | `org-stb-shift-1-hour` | Shift item forward 1 hour |
| `C-c s H` | `org-stb-shift-back-1-hour` | Shift item backward 1 hour |
| `C-c s m` | `org-stb-shift-30-min` | Shift item forward 30 minutes |
| `C-c s M` | `org-stb-shift-back-30-min` | Shift item backward 30 minutes |
| `C-c s a` | `org-stb-shift-all-hours` | Shift all items by N hours |
| `C-c s i` | `org-stb-shift-by-increment` | Shift by default increment |

### Programmatic API

```elisp
;; Shift current item by 90 minutes
(org-stb-shift-time 90)

;; Shift current item by 2 hours
(org-stb-shift-hours 2)

;; Shift all items forward by 3 hours
(org-stb-shift-all-hours 3)

;; Shift backward by 45 minutes
(org-stb-shift-time -45)
```

### Configuration

```elisp
;; Set default increment to 15 minutes
(setq org-stb-default-increment 15)
```

## Development

### Running Tests

```bash
# Run all tests
emacs -batch -l ert -l org-stb.el -l org-stb-test.el -f ert-run-tests-batch-and-exit

# Run specific test
emacs -batch -l ert -l org-stb.el -l org-stb-test.el \
  --eval "(ert-run-tests-batch-and-exit 'org-stb-test-shift-time-forward)"
```

### Test Structure

Tests follow ERT conventions:
- `org-stb-test-` prefix for all tests
- Unit tests for individual functions
- Integration tests for workflows
- Helper functions for test setup/teardown

## Architecture

```
org-stb/
├── org-stb.el          # Main package code
├── org-stb-test.el     # ERT test suite
├── README.md           # This file
└── .gitignore          # Git ignore rules
```

### Core Functions

1. **`org-stb-shift-time`** - Base function for time manipulation
2. **`org-stb-shift-hours`** - Convenience wrapper for hour-based shifts
3. **`org-stb-shift-all-forward`** - Batch operation for multiple items

All higher-level functions build on these primitives (DRY principle).

## Contributing

1. Write tests first (TDD)
2. Keep functions small and focused (KISS)
3. Reuse existing functions (DRY)
4. Document with docstrings
5. Update tests and README

## License

GPL-3.0-or-later

## Author

Juan Gonzalez

---

*"The best scheduling is simple scheduling"*
