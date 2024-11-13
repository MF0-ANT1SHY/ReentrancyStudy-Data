import os
import csv
import shutil

dest = "/home/shuo/repo/ReentrancyStudy-Data/remaining"
source = "/home/shuo/repo/Throbber-private-/datasets/Large/valid"
csv_file = "/home/shuo/repo/evaluation/Reentrancy_duration.csv"

def process_code_files(source_dir, dest_dir):
    # Initialize counters
    existed_files = 0
    copied_files = 0
    
    # Read duration.csv to get existing contracts
    existing_contracts = set()
    try:
        with open(csv_file, 'r') as f:
            csv_reader = csv.DictReader(f)
            for row in csv_reader:
                existing_contracts.add(row['contract'])
    except FileNotFoundError:
        print("duration.csv not found")
        return
        
    # Process *.code files
    for filename in os.listdir(source_dir):
        if filename.endswith('.code'):
            if filename in existing_contracts:
                existed_files += 1
            else:
                # Copy file to destination directory
                src_path = os.path.join(source_dir, filename)
                dst_path = os.path.join(dest_dir, filename)
                
                try:
                    shutil.copy2(src_path, dst_path)
                    copied_files += 1
                except Exception as e:
                    print(f"Error copying {filename}: {str(e)}")
    
    print(f"Existed files: {existed_files}")
    print(f"Copied files: {copied_files}")

# Example usage:
# process_code_files('/path/to/source/dir', '/path/to/dest/dir')
process_code_files(source, dest)