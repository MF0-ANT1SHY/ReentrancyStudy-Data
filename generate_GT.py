import re
import os
import csv
from pathlib import Path
import time
import pandas as pd

directory_path = "/home/shuo/repo/ReentrancyStudy-Data/reentrant_contracts"
output_file = "groundtruth.csv"


def extract_comments_and_contracts(solidity_code, file_path):
    # Extract filename without extension from file_path
    filename = os.path.basename(file_path)
    filename_without_ext = os.path.splitext(filename)[0]

    # Pattern to match contract definitions
    contract_pattern = r"contract\s+(\w+)(?:\s+is\s+[\w,\s]+)?[\s]*{?"
    library_pattern = r"library\s+(\w+)"

    # Pattern to match comments with <yes> <report> TYPE format
    comment_pattern = r"//\s*<yes>\s"
    comment_general_pattern = r"//*"
    comment_general_pattern_1 = r"\*"

    results = []
    current_contract = None

    # Split the code into lines
    lines = solidity_code.split("\n")

    for line_num, line in enumerate(lines, 1):
        # Check for contract definition
        contract_match = re.search(contract_pattern, line)
        contract_not_match = re.search(comment_general_pattern, line)
        if (
            contract_match
            or re.search(library_pattern, line)
            and not contract_not_match
            and not re.search(comment_general_pattern_1, line)
        ):
            # Combine filename and contract name
            contract_name = contract_match.group(1)
            current_contract = f"{filename_without_ext}_{contract_name}"

        # Check for special comment pattern
        comment_match = re.search(comment_pattern, line)
        if comment_match and current_contract:
            vulnerability_type = "Reentrancy"
            # Include file path, line number, vulnerability type, and contract name
            results.append([file_path, line_num, vulnerability_type, current_contract])

    return results


def process_directory(directory_path, output_file):
    all_results = []

    # Walk through directory and its subdirectories
    for root, _, files in os.walk(directory_path):
        for file in files:
            if file.endswith(".sol"):
                file_path = os.path.join(root, file)
                try:
                    # Read the Solidity file
                    with open(file_path, "r", encoding="utf-8") as f:
                        content = f.read()

                    # Process the file content
                    results = extract_comments_and_contracts(content, file_path)
                    all_results.extend(results)
                except Exception as e:
                    print(f"Error processing {file_path}: {str(e)}")

    if all_results:
        # Convert results to pandas DataFrame
        df = pd.DataFrame(
            all_results,
            columns=["File Path", "Line Number", "Vulnerability Type", "Contract Name"],
        )

        # Drop duplicates based on Vulnerability Type and Contract Name
        df_deduplicated = df.drop_duplicates(
            subset=["Vulnerability Type", "Contract Name"]
        )

        # Save original results
        with open(output_file, "w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            writer.writerow(
                ["File Path", "Line Number", "Vulnerability Type", "Contract Name"]
            )
            writer.writerows(all_results)
        print(f"Original results have been saved to {output_file}")

        # Save deduplicated results
        deduplicated_output = output_file.replace(".csv", "_deduplicated.csv")
        df_deduplicated.to_csv(deduplicated_output, index=False)
        print(f"Deduplicated results have been saved to {deduplicated_output}")

        # Print statistics
        print(f"\nStatistics:")
        print(f"Original number of entries: {len(df)}")
        print(f"Number of entries after deduplication: {len(df_deduplicated)}")
    else:
        print("No matching comments found in any files")


def main():
    # Validate directory path
    if not os.path.isdir(directory_path):
        print("Invalid directory path!")
        return

    # Process the directory
    process_directory(directory_path, output_file)


if __name__ == "__main__":
    main()
