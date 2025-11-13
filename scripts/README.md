# Documentation Maintenance Scripts

This directory contains utility scripts for maintaining the documentation quality and consistency.

## Chinese Documentation Link Verification

Two scripts are provided to ensure that Chinese documentation (`.zh.md` files) correctly link to Chinese versions of other documentation files.

### verify-chinese-doc-links.py

Verifies that all links in Chinese documentation files point to the correct Chinese versions.

**Usage:**
```bash
python3 scripts/verify-chinese-doc-links.py
```

**Exit Codes:**
- `0` - All links are correct
- `1` - Issues found

**Example Output:**
```
Verifying 18 Chinese documentation files...

✅ All links verified successfully!
   Checked 18 files
   All Chinese documentation correctly links to Chinese versions
```

### fix-chinese-doc-links.py

Automatically fixes links in Chinese documentation to point to Chinese versions.

**Usage:**
```bash
# Dry run - see what would be changed
python3 scripts/fix-chinese-doc-links.py --dry-run

# Apply fixes
python3 scripts/fix-chinese-doc-links.py
```

**Options:**
- `--dry-run` - Show what would be changed without making actual changes

**Example Output:**
```
Processing 18 Chinese documentation files...

✅ No fixes needed! All links are already correct.
```

## How It Works

### Link Detection

The scripts scan all `.zh.md` files recursively in the `docs/` folder and check for:

1. **Local markdown links**: Links that start with `./` or `../` and point to `.md` files
2. **Documentation links**: Links within the `docs/` folder (not `demo-apps/`)
3. **Available Chinese versions**: Checks if a `.zh.md` version exists for the target file

### Rules

- ✅ Links in `.zh.md` files should point to `.zh.md` versions when available
- ✅ Links to `demo-apps/` are excluded (no Chinese versions available)
- ✅ Already correct `.zh.md` links are left unchanged
- ✅ External URLs and anchor-only links are ignored

### Example

**Before (incorrect):**
```markdown
See the [Getting Started Guide](./getting-started.md) for details.
```

**After (correct):**
```markdown
See the [Getting Started Guide](./getting-started.zh.md) for details.
```

## Maintenance

### When to Run

Run these scripts:
- Before committing changes to Chinese documentation
- After adding new documentation files
- As part of CI/CD to ensure consistency

### CI Integration

To integrate into your CI pipeline:

```yaml
- name: Verify Chinese documentation links
  run: python3 scripts/verify-chinese-doc-links.py
```

## Current Status

As of the last check:
- ✅ All 18 Chinese documentation files verified
- ✅ 121 markdown links analyzed
- ✅ 0 issues found
- ✅ All links correctly point to Chinese versions

The repository documentation is in excellent condition with proper bilingual link management.
