#!/usr/bin/env python3
"""
Verify Chinese Documentation Links

This script verifies that all Chinese (.zh.md) documentation files
correctly link to Chinese versions of other documentation files.

Usage:
    python3 scripts/verify-chinese-doc-links.py
    
Exit codes:
    0 - All links are correct
    1 - Issues found
"""

import re
import sys
from pathlib import Path
from typing import List, Dict, Tuple

def find_markdown_links(content: str) -> List[Tuple[int, str, str]]:
    """
    Find all markdown links in content.
    
    Returns:
        List of tuples (line_number, link_text, link_path)
    """
    links = []
    lines = content.split('\n')
    
    for i, line in enumerate(lines, 1):
        # Match markdown links: [text](path)
        matches = re.finditer(r'\[([^\]]+)\]\(([^)]+)\)', line)
        for match in matches:
            link_text = match.group(1)
            link_path = match.group(2)
            links.append((i, link_text, link_path))
    
    return links

def is_local_md_link(link_path: str) -> bool:
    """Check if link is a local markdown file link."""
    return (
        '.md' in link_path and
        not link_path.startswith('http') and
        not link_path.startswith('#')
    )

def should_be_chinese(link_path: str, source_file: Path, docs_dir: Path) -> Tuple[bool, str]:
    """
    Check if a link should point to a Chinese version.
    
    Returns:
        (should_be_chinese, reason)
    """
    # Ignore demo-apps links (no Chinese versions exist)
    if 'demo-apps' in link_path:
        return False, "demo-apps link (no Chinese version)"
    
    # Already points to Chinese version
    if '.zh.md' in link_path:
        return False, "already Chinese"
    
    # Check if it's a docs internal link
    if link_path.startswith(('./')) or link_path.startswith('../'):
        # Try to resolve the path
        try:
            current_dir = source_file.parent
            # Remove any anchors
            clean_path = link_path.split('#')[0]
            target_path = (current_dir / clean_path).resolve()
            
            # Check if Chinese version exists
            zh_version = str(target_path).replace('.md', '.zh.md')
            if Path(zh_version).exists():
                return True, f"Chinese version exists: {Path(zh_version).name}"
        except Exception as e:
            return False, f"path resolution error: {e}"
    
    return False, "not a docs internal link"

def verify_file(file_path: Path, docs_dir: Path) -> List[Dict]:
    """
    Verify all links in a single Chinese documentation file.
    
    Returns:
        List of issues found
    """
    issues = []
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        return [{'file': str(file_path), 'error': f"Failed to read file: {e}"}]
    
    links = find_markdown_links(content)
    
    for line_num, link_text, link_path in links:
        if is_local_md_link(link_path):
            should_be_zh, reason = should_be_chinese(link_path, file_path, docs_dir)
            
            if should_be_zh:
                issues.append({
                    'file': str(file_path.relative_to(docs_dir.parent)),
                    'line': line_num,
                    'link_text': link_text,
                    'current_link': link_path,
                    'should_be': link_path.replace('.md', '.zh.md'),
                    'reason': reason
                })
    
    return issues

def main():
    """Main verification function."""
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
    
    print(f"Verifying {len(zh_files)} Chinese documentation files...")
    print()
    
    # Verify each file
    all_issues = []
    for zh_file in zh_files:
        issues = verify_file(zh_file, docs_dir)
        all_issues.extend(issues)
    
    # Report results
    if all_issues:
        print(f"❌ Found {len(all_issues)} issue(s):")
        print()
        
        for issue in all_issues:
            print(f"File: {issue['file']}:{issue['line']}")
            print(f"  Link text: {issue['link_text']}")
            print(f"  Current: {issue['current_link']}")
            print(f"  Should be: {issue['should_be']}")
            print(f"  Reason: {issue['reason']}")
            print()
        
        return 1
    else:
        print("✅ All links verified successfully!")
        print(f"   Checked {len(zh_files)} files")
        print("   All Chinese documentation correctly links to Chinese versions")
        return 0

if __name__ == '__main__':
    sys.exit(main())
