import argparse
import logging
import os
import csv
import re
from solcx import install_solc, set_solc_version, compile_files
from solcx.exceptions import SolcNotInstalled

logger = logging.getLogger()
logger.setLevel(logging.INFO)

info_csv = "/home/shuo/repo/ReentrancyStudy-Data/contract_information_etherscan.csv"


def get_solc_version_from_csv(contract_address, csv_path=info_csv):
    """Get solc version from info.csv based on contract address."""
    try:
        with open(csv_path, "r") as file:
            csv_reader = csv.DictReader(file)
            for row in csv_reader:
                if row["ContractAddress"].lower() == contract_address.lower():
                    compiler_version = row["CompilerVersion"]
                    # Extract version number (0.x.x) from format like 'v0.4.17+commit.bdeb9e52'
                    version_match = re.search(r"v(0\.\d+\.\d+)", compiler_version)
                    if version_match:
                        return version_match.group(1)
    except Exception as e:
        logger.error(f"Error reading CSV file: {str(e)}")
    return None


def compile_solidity_file(filename, csv_path="info.csv"):
    """Compile a Solidity file and return the bytecode."""
    try:
        # Extract contract address from filename
        contract_address = os.path.splitext(os.path.basename(filename))[0]

        # Get Solidity version from CSV
        solc_version = get_solc_version_from_csv(contract_address, csv_path)

        if not solc_version:
            logger.error(f"Could not find compiler version for {contract_address}")
            return None

        # Install and set correct solc version
        try:
            logger.info(f"Setting solc version to {solc_version}...")
            set_solc_version(solc_version)
        except SolcNotInstalled:
            logger.info(f"Installing solc version {solc_version}...")
            install_solc(solc_version)
            set_solc_version(solc_version)
            logger.info("Installed")

        # Compile the contract
        logger.info(f"Compiling {filename}...")
        contracts = compile_files([filename])
        logger.info("Compiled successfully")

        # Extract bytecode for each contract
        bytecodes = {}
        for name, contract in contracts.items():
            runtime_bytecode = contract["bin-runtime"]
            bytecodes[name] = runtime_bytecode

        return bytecodes
    except Exception as e:
        logger.error(f"Error compiling {filename}: {str(e)}")
        return None


def save_bytecodes(bytecodes, source_filename, output_dir):
    """Save bytecodes to .hex files in the specified output directory."""
    if not bytecodes:
        return

    # Create output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)

    base_filename = os.path.splitext(os.path.basename(source_filename))[0]

    for contract_path, bytecode in bytecodes.items():
        # Extract contract name from full path
        contract_name = contract_path.split(":")[-1]
        # Create filename in format: filename_sol_contractname.hex
        hex_filename = f"{base_filename}_sol_{contract_name}.hex"
        hex_path = os.path.join(output_dir, hex_filename)

        # Save bytecode to file
        with open(hex_path, "w") as f:
            f.write(bytecode)
        logger.info(f"Saved bytecode to {hex_path}")


def process_directory(input_dir, output_dir, csv_path="info.csv"):
    """Process all .sol files in the input directory and its subdirectories."""
    # Get absolute paths
    input_dir = os.path.abspath(input_dir)
    output_dir = os.path.abspath(output_dir)

    # Create output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)

    # Counter for processed files
    processed = 0
    failed = 0

    # Walk through directory
    for root, _, files in os.walk(input_dir):
        for file in files:
            if file.endswith(".sol"):
                sol_path = os.path.join(root, file)
                logger.info(f"\nProcessing: {sol_path}")

                # Create corresponding output subdirectory structure
                rel_path = os.path.relpath(root, input_dir)
                out_subdir = os.path.join(output_dir, rel_path)

                # Compile and save
                try:
                    bytecodes = compile_solidity_file(sol_path, csv_path)
                    if bytecodes:
                        save_bytecodes(bytecodes, sol_path, out_subdir)
                        processed += 1
                    else:
                        failed += 1
                except Exception as e:
                    logger.error(f"Failed to process {sol_path}: {str(e)}")
                    failed += 1

    return processed, failed


def process_single_file(input_file, output_dir, csv_path="info.csv"):
    """Process a single Solidity file."""
    try:
        logger.info(f"\nProcessing single file: {input_file}")
        bytecodes = compile_solidity_file(input_file, csv_path)
        if bytecodes:
            save_bytecodes(bytecodes, input_file, output_dir)
            return 1, 0  # processed, failed
        return 0, 1
    except Exception as e:
        logger.error(f"Failed to process {input_file}: {str(e)}")
        return 0, 1


def main():
    parser = argparse.ArgumentParser(description="Solidity Contracts Compiler")
    parser.add_argument(
        "input_path",
        type=str,
        help="Path to Solidity file or directory containing Solidity files",
    )
    parser.add_argument(
        "--output-dir",
        "-o",
        type=str,
        default="bytecodes",
        help="Output directory for bytecode files (default: bytecodes)",
    )
    parser.add_argument(
        "--csv-path",
        "-c",
        type=str,
        default="info.csv",
        help="Path to info.csv file (default: info.csv)",
    )
    args = parser.parse_args()

    try:
        logger.info(f"Starting compilation process...")
        logger.info(f"Input path: {args.input_path}")
        logger.info(f"Output directory: {args.output_dir}")
        logger.info(f"CSV path: {args.csv_path}")

        # Check if info.csv exists
        if not os.path.exists(args.csv_path):
            logger.error(f"info.csv not found at {args.csv_path}")
            return

        # Determine if input is file or directory
        if os.path.isfile(args.input_path):
            if not args.input_path.endswith(".sol"):
                logger.error("Input file must have .sol extension")
                return
            processed, failed = process_single_file(
                args.input_path, args.output_dir, args.csv_path
            )
        elif os.path.isdir(args.input_path):
            processed, failed = process_directory(
                args.input_path, args.output_dir, args.csv_path
            )
        else:
            logger.error("Input path does not exist")
            return

        logger.info(f"\nCompilation completed:")
        logger.info(f"Successfully processed: {processed} files")
        logger.info(f"Failed: {failed} files")

    except Exception as e:
        logger.error(f"Process failed: {str(e)}")


if __name__ == "__main__":
    main()
