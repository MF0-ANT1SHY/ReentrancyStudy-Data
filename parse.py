import argparse
import logging
import os
from solcx import (
    get_available_solc_versions,
    install_solc_pragma,
    set_solc_version_pragma,
    compile_files,
)
from solcx.exceptions import SolcNotInstalled
from solidity_parser.parser import parse

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def get_solc_version_string(file):
    """Extract the Solidity pragma version from source file."""
    parsed = parse(file.read().decode("utf-8"))
    for children in parsed["children"]:
        if children["type"] == "PragmaDirective":
            return children["value"]
    return get_available_solc_versions()[0]


def compile_solidity_file(filename):
    """Compile a Solidity file and return the bytecode."""
    try:
        with open(filename, "rb") as file:
            # Get Solidity version from pragma
            solc_version = get_solc_version_string(file)

            # Install and set correct solc version
            try:
                set_solc_version_pragma(solc_version)
            except SolcNotInstalled:
                logger.info(f"Installing solc version {solc_version}...")
                install_solc_pragma(solc_version)
                set_solc_version_pragma(solc_version)
                logger.info("Installed")

            # Compile the contract
            logger.info(f"Compiling {filename}...")
            contracts = compile_files(
                [filename], optimize=True, optimize_runs=1000000000
            )
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


def process_directory(input_dir, output_dir):
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
                    bytecodes = compile_solidity_file(sol_path)
                    if bytecodes:
                        save_bytecodes(bytecodes, sol_path, out_subdir)
                        processed += 1
                    else:
                        failed += 1
                except Exception as e:
                    logger.error(f"Failed to process {sol_path}: {str(e)}")
                    failed += 1

    return processed, failed


def process_single_file(input_file, output_dir):
    """Process a single Solidity file."""
    try:
        logger.info(f"\nProcessing single file: {input_file}")
        bytecodes = compile_solidity_file(input_file)
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
    args = parser.parse_args()

    try:
        logger.info(f"Starting compilation process...")
        logger.info(f"Input path: {args.input_path}")
        logger.info(f"Output directory: {args.output_dir}")

        # Determine if input is file or directory
        if os.path.isfile(args.input_path):
            if not args.input_path.endswith(".sol"):
                logger.error("Input file must have .sol extension")
                return
            processed, failed = process_single_file(args.input_path, args.output_dir)
        elif os.path.isdir(args.input_path):
            processed, failed = process_directory(args.input_path, args.output_dir)
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
