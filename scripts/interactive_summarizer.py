#!/usr/bin/env python3
"""
Simple Interactive Summarizer for Kiran files
Process files one by one with user confirmation
"""

import os
import sys
import json
import subprocess
from pathlib import Path

def extract_content_from_json(file_path: Path) -> str:
    """Extract main content from JSON file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        if 'main' in data and 'content' in data['main']:
            content = data['main']['content']
            # Remove HTML tags
            import re
            content = re.sub(r'<[^>]+>', ' ', content)
            content = re.sub(r'&[^;]+;', ' ', content)
            content = ' '.join(content.split())
            return content
        return str(data)
    except Exception as e:
        print(f"Error reading {file_path}: {e}")
        return ""

def create_simple_summary(content: str, file_name: str) -> str:
    """Create a simple summary"""
    import re
    
    # Extract key information
    dates = re.findall(r'સંવત્.*?\d+', content)
    places = re.findall(r'(પીપલાણા|દરબારગઢ|ગઢડા|વરતાલ|હળિયાદ)', content)
    
    # Count words
    words = content.split()
    word_count = len(words)
    
    # Create summary template
    summary = f"# કિરણ {file_name.replace('kiran_', '').replace('.json', '')} - સાર\n\n"
    
    if dates:
        summary += f"**તારીખ:** {dates[0]}\n"
    if places:
        summary += f"**સ્થળ:** {places[0]}\n\n"
    
    summary += "**મુખ્ય મુદ્દાઓ:**\n"
    
    # Try to extract meaningful sentences for bullet points
    sentences = re.split(r'[।\.!?]', content)
    meaningful_sentences = []
    
    for sentence in sentences:
        sentence = sentence.strip()
        if len(sentence.split()) > 8:  # At least 8 words
            meaningful_sentences.append(sentence)
    
    # Take first 2 meaningful sentences as bullet points
    for i, sentence in enumerate(meaningful_sentences[:2], 1):
        # Clean and truncate sentence
        clean_sentence = ' '.join(sentence.split()[:15])  # Max 15 words
        if clean_sentence:
            summary += f"• {clean_sentence}...\n"
    
    if not meaningful_sentences:
        # Fallback to word-based analysis
        spiritual_terms = ['ભગવાન', 'સંત', 'ભક્ત', 'આત્મા', 'વૈરાગ્ય', 'સત્સંગ', 'ધર્મ', 'મુક્તિ']
        found_terms = [term for term in spiritual_terms if term in content]
        
        for term in found_terms[:2]:
            summary += f"• {term} સંબંધિત વિચારણા\n"
    
    summary += f"\n**શબ્દ સંખ્યા:** {word_count}\n"
    summary += f"**અંદાજિત વાંચન સમય:** {max(1, word_count // 200)} મિનિટ\n"
    
    return summary

def main():
    # Get input directory
    input_dir = Path("scripts/saxatsavita/part1")
    output_dir = Path("kiran_summaries")
    output_dir.mkdir(exist_ok=True)
    
    if not input_dir.exists():
        print(f"❌ Directory not found: {input_dir}")
        return
    
    # Get all JSON files
    json_files = sorted(list(input_dir.glob("kiran_*.json")))
    
    if not json_files:
        print("❌ No kiran JSON files found")
        return
    
    print(f"🎯 Interactive Kiran Summarizer")
    print(f"📁 Found {len(json_files)} kiran files")
    print(f"📂 Output directory: {output_dir}")
    print(f"{'='*50}")
    
    processed = 0
    
    for i, file_path in enumerate(json_files, 1):
        print(f"\n📖 File {i}/{len(json_files)}: {file_path.name}")
        
        # Show file info
        content = extract_content_from_json(file_path)
        if content:
            word_count = len(content.split())
            print(f"   📊 Words: {word_count}")
            print(f"   🔍 Preview: {content[:100]}...")
        
        # Ask user
        choice = input(f"\n   Process this file? (y/n/q): ").strip().lower()
        
        if choice == 'q':
            print("❌ Quit requested by user")
            break
        elif choice == 'y':
            # Process the file
            summary = create_simple_summary(content, file_path.name)
            
            # Save summary
            output_file = output_dir / f"{file_path.stem}_summary.md"
            try:
                output_file.write_text(summary, encoding='utf-8')
                print(f"   ✅ Summary saved: {output_file.name}")
                processed += 1
            except Exception as e:
                print(f"   ❌ Error saving: {e}")
        else:
            print("   ⏭️  Skipped")
    
    print(f"\n🎯 COMPLETED")
    print(f"✅ Processed: {processed} files")
    print(f"📂 Summaries in: {output_dir}")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n❌ Cancelled by user")
        sys.exit(0)