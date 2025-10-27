#!/usr/bin/env python3
"""
Automated Batch Summarizer using GitHub Copilot CLI
This script processes multiple JSON files and generates summaries using Copilot
"""

import os
import sys
import json
import subprocess
import time
from pathlib import Path
from typing import List, Dict

class BatchSummarizer:
    def __init__(self, input_dir: str, output_dir: str = "summaries"):
        self.input_dir = Path(input_dir)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(exist_ok=True)
        
    def get_json_files(self) -> List[Path]:
        """Get all JSON files from input directory"""
        return list(self.input_dir.glob("*.json"))
    
    def extract_content_from_json(self, file_path: Path) -> str:
        """Extract main content from JSON file"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            # Extract content from main section
            if 'main' in data and 'content' in data['main']:
                content = data['main']['content']
                # Remove HTML tags for cleaner text
                import re
                content = re.sub(r'<[^>]+>', ' ', content)
                content = re.sub(r'&[^;]+;', ' ', content)
                content = ' '.join(content.split())  # Clean whitespace
                return content
            else:
                return str(data)
                
        except Exception as e:
            print(f"❌ Error reading {file_path}: {e}")
            return ""
    
    def summarize_with_copilot(self, content: str, file_name: str) -> str:
        """Use Copilot CLI to generate summary"""
        try:
            # Create a focused prompt for Gujarati content
            prompt = f"""
આ ગુજરાતી આધ્યાત્મિક સામગ્રીનો સાર બનાવો:

સામગ્રી: {content[:800]}

માર્ગદર્શન:
- ફક્ત ૨ મુખ્ય મુદ્દાઓ બનાવો
- દરેક મુદ્દો લગભગ ૧૦૦ શબ્દોનો હોવો જોઈએ
- તારીખ અને સ્થળનો ઉલ્લેખ કરો
- બુલેટ પોઇંટ ફોર્મેટ વાપરો
- ફક્ત ગુજરાતીમાં જવાબ આપો

સાર:
"""
            
            print(f"🤖 Using Copilot to summarize {file_name}...")
            
            # Use copilot suggest command
            result = subprocess.run(
                ['copilot', '-p', prompt],
                capture_output=True,
                text=True,
                timeout=120
            )
            
            if result.returncode == 0:
                summary = result.stdout.strip()
                # Clean up the output
                lines = summary.split('\n')
                clean_lines = []
                for line in lines:
                    line = line.strip()
                    if line and not line.startswith('?') and len(line) > 10:
                        clean_lines.append(line)
                
                if clean_lines:
                    return '\n'.join(clean_lines[:10])  # Take first 10 meaningful lines
                
            print(f"⚠️  Copilot didn't provide useful output, using fallback")
            return self.create_fallback_summary(content, file_name)
            
        except subprocess.TimeoutExpired:
            print(f"⏰ Copilot timed out for {file_name}, using fallback")
            return self.create_fallback_summary(content, file_name)
        except Exception as e:
            print(f"❌ Copilot error for {file_name}: {e}")
            return self.create_fallback_summary(content, file_name)
    
    def create_fallback_summary(self, content: str, file_name: str) -> str:
        """Create a simple fallback summary"""
        import re
        
        words = content.split()
        
        # Extract dates
        dates = re.findall(r'સંવત્.*?\d+', content)
        places = re.findall(r'(પીપલાણા|દરબારગઢ|ગઢડા|વરતાલ)', content)
        
        summary = f"# {file_name} - આપોઆપ સાર\n\n"
        
        if dates:
            summary += f"**તારીખ:** {dates[0]}\n"
        if places:
            summary += f"**સ્થળ:** {places[0]}\n"
        
        summary += f"\n**મૂળભૂત માહિતી:**\n"
        summary += f"• કુલ શબ્દો: {len(words)}\n"
        summary += f"• અંદાજિત વાંચન સમય: {max(1, len(words) // 200)} મિનિટ\n\n"
        
        # Extract key spiritual terms
        spiritual_terms = ['ભગવાન', 'સંત', 'ભક્ત', 'આત્મા', 'વૈરાગ્ય', 'સત્સંગ']
        found_terms = [term for term in spiritual_terms if term in content]
        
        if found_terms:
            summary += "**મુખ્ય વિષયો:**\n"
            for term in found_terms[:5]:
                summary += f"• {term} સંબંધિત ચર્ચા\n"
        
        return summary
    
    def process_single_file(self, file_path: Path) -> bool:
        """Process a single JSON file"""
        print(f"\n📖 Processing: {file_path.name}")
        
        # Extract content
        content = self.extract_content_from_json(file_path)
        if not content:
            print(f"❌ No content found in {file_path.name}")
            return False
        
        # Generate summary
        summary = self.summarize_with_copilot(content, file_path.stem)
        
        # Save summary
        output_file = self.output_dir / f"{file_path.stem}_summary.md"
        try:
            output_file.write_text(summary, encoding='utf-8')
            print(f"✅ Summary saved to: {output_file}")
            return True
        except Exception as e:
            print(f"❌ Error saving summary: {e}")
            return False
    
    def process_all_files(self):
        """Process all JSON files in the input directory"""
        files = self.get_json_files()
        
        if not files:
            print(f"❌ No JSON files found in {self.input_dir}")
            return
        
        print(f"🚀 Found {len(files)} JSON files to process")
        print(f"📁 Output directory: {self.output_dir}")
        
        successful = 0
        
        for i, file_path in enumerate(files, 1):
            print(f"\n{'='*60}")
            print(f"Processing {i}/{len(files)}: {file_path.name}")
            print(f"{'='*60}")
            
            if self.process_single_file(file_path):
                successful += 1
            
            # Add delay between files to avoid rate limiting
            if i < len(files):  # Don't wait after the last file
                print("⏳ Waiting 3 seconds...")
                time.sleep(3)
        
        print(f"\n🎯 BATCH PROCESSING COMPLETE")
        print(f"✅ Successfully processed: {successful}/{len(files)} files")
        print(f"📂 Summaries saved in: {self.output_dir}")

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Batch Summarizer with Copilot CLI')
    parser.add_argument('input_dir', 
                       help='Directory containing JSON files to summarize')
    parser.add_argument('--output-dir', default='summaries',
                       help='Output directory for summaries (default: summaries)')
    parser.add_argument('--interactive', action='store_true',
                       help='Ask for confirmation before processing each file')
    
    args = parser.parse_args()
    
    # Validate input directory
    if not Path(args.input_dir).exists():
        print(f"❌ Input directory not found: {args.input_dir}")
        sys.exit(1)
    
    # Check if Copilot is available
    try:
        result = subprocess.run(['copilot', '--version'], capture_output=True)
        if result.returncode != 0:
            print("❌ Copilot CLI not available")
            sys.exit(1)
        print("✅ Copilot CLI is ready")
    except FileNotFoundError:
        print("❌ Copilot CLI not installed")
        sys.exit(1)
    
    # Create and run batch summarizer
    summarizer = BatchSummarizer(args.input_dir, args.output_dir)
    
    if args.interactive:
        files = summarizer.get_json_files()
        print(f"Found {len(files)} files. Process all? (y/N): ", end="")
        if input().strip().lower() not in ['y', 'yes']:
            print("❌ Cancelled by user")
            sys.exit(0)
    
    summarizer.process_all_files()

if __name__ == "__main__":
    main()