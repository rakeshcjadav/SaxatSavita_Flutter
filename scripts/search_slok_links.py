import json
import re
import os
import glob
import shutil
from datetime import datetime

def search_and_remove_a_tags_in_slok(json_file_path, remove_tags=False):
    """Search for <a> tags inside <slok> tags and optionally remove them."""
    try:
        with open(json_file_path, 'r', encoding='utf-8') as file:
            data = json.load(file)
        
        content = data.get('main', {}).get('content', '')
        if not content:
            return [], False
        
        original_content = content
        
        # Regex to find <slok> tags and their content
        slok_pattern = r'<slok>(.*?)</slok>'
        slok_matches = re.findall(slok_pattern, content, re.DOTALL)
        
        results = []
        content_modified = False
        
        for i, slok_content in enumerate(slok_matches):
            # Check if this slok contains <a> tags
            a_tag_pattern = r'<a\s+href="([^"]*)"[^>]*>(.*?)</a>'
            a_matches = re.findall(a_tag_pattern, slok_content, re.DOTALL)
            
            if a_matches:
                results.append({
                    'file': json_file_path,
                    'slok_index': i + 1,
                    'slok_content': slok_content.strip(),
                    'a_tags': a_matches
                })
                
                if remove_tags:
                    # Remove <a> tags from this slok, keeping only the text content
                    cleaned_slok_content = re.sub(r'<a\s+href="[^"]*"[^>]*>(.*?)</a>', r'\1', slok_content)
                    
                    # Replace the original slok content with cleaned content
                    original_slok_tag = f'<slok>{slok_content}</slok>'
                    cleaned_slok_tag = f'<slok>{cleaned_slok_content}</slok>'
                    content = content.replace(original_slok_tag, cleaned_slok_tag)
                    content_modified = True
        
        # Save the modified content back to file if changes were made
        if remove_tags and content_modified:
            data['main']['content'] = content
            with open(json_file_path, 'w', encoding='utf-8') as file:
                json.dump(data, file, ensure_ascii=False, indent=4)
        
        return results, content_modified
    
    except Exception as e:
        print(f"Error processing {json_file_path}: {e}")
        return [], False

def create_backup(directory_path):
    """Create a backup of the directory before making changes."""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = f"{directory_path}_backup_{timestamp}"
    
    try:
        shutil.copytree(directory_path, backup_path)
        print(f"✅ Backup created: {backup_path}")
        return backup_path
    except Exception as e:
        print(f"❌ Failed to create backup: {e}")
        return None

def search_all_json_files(directory_path, remove_tags=False):
    """Search all JSON files in the directory and optionally remove <a> tags from <slok> tags."""
    pattern = os.path.join(directory_path, '**/*.json')
    json_files = glob.glob(pattern, recursive=True)
    
    all_results = []
    files_with_matches = 0
    files_modified = 0
    total_files = len(json_files)
    
    for json_file in json_files:
        results, was_modified = search_and_remove_a_tags_in_slok(json_file, remove_tags)
        if results:
            all_results.extend(results)
            files_with_matches += 1
        if was_modified:
            files_modified += 1
    
    return all_results, files_with_matches, files_modified, total_files

def confirm_action():
    """Ask user to confirm the removal action."""
    print("\n⚠️  WARNING: This will modify your JSON files!")
    print("   A backup will be created before making changes.")
    
    while True:
        response = input("\nDo you want to proceed with removing <a> tags from <slok> tags? (y/N): ").lower().strip()
        if response in ['y', 'yes']:
            return True
        elif response in ['n', 'no', '']:
            return False
        else:
            print("Please enter 'y' for yes or 'n' for no.")

# Main execution
if __name__ == "__main__":
    # Search in the saxatsavita directory
    directory = "saxatsavita"
    
    print("🔍 Searching for <a> tags inside <slok> tags...")
    print("=" * 60)
    
    # First, do a search-only pass to see what we're dealing with
    results, files_with_matches, _, total_files = search_all_json_files(directory, remove_tags=False)
    
    if results:
        print(f"✅ Found {len(results)} <slok> tags containing <a> tags in {files_with_matches} files:")
        print()
        
        for result in results:
            print(f"📁 File: {result['file']}")
            print(f"📜 Slok #{result['slok_index']}")
            print(f"📝 Content: {result['slok_content']}")
            print(f"🔗 Links found:")
            for href, text in result['a_tags']:
                print(f"   • '{text}' → {href}")
            print("-" * 40)
        
        # Ask if user wants to remove the tags
        if confirm_action():
            # Create backup first
            backup_path = create_backup(directory)
            if backup_path:
                # Now remove the tags
                print("\n🔧 Removing <a> tags from <slok> tags...")
                _, _, files_modified, _ = search_all_json_files(directory, remove_tags=True)
                
                print(f"✅ Successfully removed <a> tags from {files_modified} files!")
                print(f"📁 Backup saved at: {backup_path}")
                
                # Verify the changes
                print("\n🔍 Verifying changes...")
                verification_results, _, _, _ = search_all_json_files(directory, remove_tags=False)
                if not verification_results:
                    print("✅ Verification passed: No <a> tags found in <slok> tags anymore!")
                else:
                    print(f"⚠️  Warning: Still found {len(verification_results)} <a> tags in <slok> tags!")
            else:
                print("❌ Cannot proceed without backup. Operation cancelled.")
        else:
            print("❌ Operation cancelled by user.")
    
    else:
        print("✅ No <slok> tags containing <a> tags found.")
    
    print(f"\n📊 Summary:")
    print(f"   • Total files searched: {total_files}")
    print(f"   • Files with <a> tags in <slok>: {files_with_matches}")
    print(f"   • Total problematic sloks: {len(results)}")