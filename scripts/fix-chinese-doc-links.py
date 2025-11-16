#!/usr/bin/env python3
"""
Fix Chinese Documentation Links

This script automatically fixes links in Chinese (.zh.md) documentation files
to point to Chinese versions of other documentation files.

Usage:
    python3 scripts/fix-chinese-doc-links.py [--dry-run]
    
Options:
    --dry-run    Show what would be changed without making changes
    
Exit codes:
    0 - Success (or no changes needed)
    1 - Error occurred
"""

import re
import sys
import argparse
from pathlib import Path
from typing import List, Dict, Tuple

def find_markdown_links(content: str) -> List[Tuple[int, str, str, int, int]]:
    """
    Find all markdown links in content with their positions.
    
    Returns:
        List of tuples (line_number, link_text, link_path, start_pos, end_pos)
    """
    links = []
    lines = content.split('\n')
    char_pos = 0
    
    for i, line in enumerate(lines, 1):
        # Match markdown links: [text](path)
        matches = re.finditer(r'\[([^\]]+)\]\(([^)]+)\)', line)
        for match in matches:
            link_text = match.group(1)
            link_path = match.group(2)
            start = char_pos + match.start()
            end = char_pos + match.end()
            links.append((i, link_text, link_path, start, end))
        
        char_pos += len(line) + 1  # +1 for newline
    
    return links

def is_local_md_link(link_path: str) -> bool:
    """Check if link is a local markdown file link."""
    return (
        '.md' in link_path and
        not link_path.startswith('http') and
        not link_path.startswith('#')
    )

def should_fix_link(link_path: str, source_file: Path) -> Tuple[bool, str, str]:
    """
    Check if a link should be fixed to point to Chinese version.
    
    Returns:
        (should_fix, new_link_path, reason)
    """
    # Ignore demo-apps links (no Chinese versions exist)
    if 'demo-apps' in link_path:
        return False, link_path, "demo-apps link"
    
    # Already points to Chinese version
    if '.zh.md' in link_path:
        return False, link_path, "already Chinese"
    
    # Check if it's a docs internal link
    if link_path.startswith(('./')) or link_path.startswith('../'):
        # Try to resolve the path
        try:
            current_dir = source_file.parent
            # Split anchor from path
            parts = link_path.split('#')
            clean_path = parts[0]
            anchor = f"#{parts[1]}" if len(parts) > 1 else ""
            
            target_path = (current_dir / clean_path).resolve()
            
            # Check if Chinese version exists
            zh_version = str(target_path).replace('.md', '.zh.md')
            if Path(zh_version).exists():
                # Construct new link path
                new_path = clean_path.replace('.md', '.zh.md') + anchor
                return True, new_path, "Chinese version exists"
        except Exception as e:
            return False, link_path, f"error: {e}"
    
    return False, link_path, "not fixable"

def fix_file(file_path: Path, dry_run: bool = False) -> Tuple[int, List[str]]:
    """
    Fix all links in a single Chinese documentation file.
    
    Returns:
        (number_of_fixes, list_of_changes)
    """
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        return 0, [f"Error reading file: {e}"]
    
    original_content = content
    changes = []
    fixes = 0
    
    # Find all links
    links = find_markdown_links(content)
    
    # Process links in reverse order to maintain positions
    for line_num, link_text, link_path, start, end in reversed(links):
        if is_local_md_link(link_path):
            should_fix, new_path, reason = should_fix_link(link_path, file_path)
            
            if should_fix:
                # Replace the link path in content
                old_link = f"[{link_text}]({link_path})"
                new_link = f"[{link_text}]({new_path})"
                
                content = content[:start] + new_link + content[end:]
                fixes += 1
                changes.append(f"  Line {line_num}: {link_path} → {new_path}")
    
    # Write back if there were changes and not dry run
    if fixes > 0 and not dry_run:
        try:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
        except Exception as e:
            return 0, [f"Error writing file: {e}"]
    
    return fixes, changes

def main():
    """Main fix function."""
    parser = argparse.ArgumentParser(
        description='Fix Chinese documentation links to point to .zh.md versions'
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Show what would be changed without making changes'
    )
    args = parser.parse_args()
    
    # Find docs directory
    script_dir = Path(__file__).parent
    repo_root = script_dir.parent
    docs_dir = repo_root / 'docs'
    
    if not docs_dir.exists():
        print(f"Error: docs directory not found at {docs_dir}", file=sys.stderr)
        return 1
    
    # Find all Chinese documentation files
    zh_files = sorted(docs_dir.rglob("*.zh.md"))
    
    if not zh_files:
        print("No Chinese documentation files found!", file=sys.stderr)
        return 1
    
    mode_str = "(DRY RUN)" if args.dry_run else ""
    print(f"Processing {len(zh_files)} Chinese documentation files... {mode_str}")
    print()
    
    # Fix each file
    total_fixes = 0
    files_changed = 0
    
    for zh_file in zh_files:
        fixes, changes = fix_file(zh_file, dry_run=args.dry_run)
        
        if fixes > 0:
            files_changed += 1
            total_fixes += fixes
            rel_path = zh_file.relative_to(repo_root)
            print(f"{'Would fix' if args.dry_run else 'Fixed'} {rel_path}:")
            for change in changes:
                print(change)
            print()
    
    # Report results
    if total_fixes > 0:
        print(f"{'Would fix' if args.dry_run else 'Fixed'} {total_fixes} link(s) in {files_changed} file(s)")
        if args.dry_run:
            print("\nRun without --dry-run to apply changes")
    else:
        print("✅ No fixes needed! All links are already correct.")
    
    return 0

if __name__ == '__main__':
    sys.exit(main())
