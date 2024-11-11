import csv
import os
import glob


def get_sol_files_in_directory(directory_path):
    # Get all .sol files in the directory and subdirectories
    return glob.glob(os.path.join(directory_path, "**/*.sol"), recursive=True)


def read_sol_files_from_csv(csv_file):
    sol_files_in_csv = set()

    with open(csv_file, "r") as f:
        csv_reader = csv.DictReader(f)
        for row in csv_reader:
            # Get the file path from the 'File Path' column
            file_path = row["File Path"]
            sol_files_in_csv.add(file_path)

    return sol_files_in_csv


def find_missing_sol_files(directory_path, csv_file):
    # Get all .sol files in the directory
    all_sol_files = set(get_sol_files_in_directory(directory_path))

    # Get .sol files mentioned in the CSV
    sol_files_in_csv = read_sol_files_from_csv(csv_file)

    # Find files that are in the directory but not in the CSV
    missing_files = all_sol_files - sol_files_in_csv

    return missing_files


def main():
    # Replace these paths with your actual paths
    directory_path = "/home/shuo/repo/ReentrancyStudy-Data/reentrant_contracts/"
    csv_file = "groundtruth.csv"

    try:
        missing_files = find_missing_sol_files(directory_path, csv_file)

        if missing_files:
            print("The following .sol files are not in the CSV:")
            for file in sorted(missing_files):
                print(file)
        else:
            print("All .sol files in the directory are listed in the CSV.")

    except FileNotFoundError as e:
        print(f"Error: {e}")
    except Exception as e:
        print(f"An error occurred: {e}")


if __name__ == "__main__":
    main()
