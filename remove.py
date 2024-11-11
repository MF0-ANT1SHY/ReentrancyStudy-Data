import csv
import os


def process_csv(csv_file_path, directory_path):
    # Lists to store existed and non-existed files
    existed_files = []
    non_existed_files = []

    # Read CSV file
    with open(csv_file_path, "r") as file:
        csv_reader = csv.DictReader(file)

        for row in csv_reader:
            # Get contract name from the row
            contract_name = row["Contract Name"]

            # Replace first '_' with '_sol_'
            first_underscore_pos = contract_name.find("_")
            if first_underscore_pos != -1:
                modified_name = (
                    contract_name[:first_underscore_pos]
                    + "_sol_"
                    + contract_name[first_underscore_pos + 1 :]
                )

                # Create hex filename
                hex_filename = modified_name + ".hex"

                # Check if file exists in directory
                file_path = os.path.join(directory_path, hex_filename)

                if os.path.exists(file_path):
                    existed_files.append(hex_filename)
                else:
                    non_existed_files.append(hex_filename)

    # Print results
    print("Existed files:")
    for file in existed_files:
        print(f"- {file}")

    print("\nNon-existed files:")
    for file in non_existed_files:
        print(f"- {file}")

    # Return results if needed for further processing
    return existed_files, non_existed_files


# Example usage
if __name__ == "__main__":
    csv_file_path = "groundtruth.csv"  # Replace with your CSV file path
    directory_path = "bytecodes"  # Replace with directory path to check files

    process_csv(csv_file_path, directory_path)
