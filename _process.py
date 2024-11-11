import os

# Example usage
directory = "./bytecodes"


def remove_empty_files(directory):
    # Check if directory exists
    if not os.path.exists(directory):
        print(f"Directory '{directory}' does not exist")
        return

    # Counter for empty files
    empty_count = 0

    # Walk through directory
    for root, dirs, files in os.walk(directory):
        for file in files:
            filepath = os.path.join(root, file)
            try:
                # Check if file size is 0 bytes
                if os.path.getsize(filepath) == 0:
                    os.remove(filepath)
                    print(f"Removed empty file: {filepath}")
                    empty_count += 1
            except OSError as e:
                print(f"Error processing {filepath}: {e}")

    print(f"\nTotal empty files removed: {empty_count}")


remove_empty_files(directory)
