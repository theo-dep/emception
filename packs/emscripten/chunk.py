import os
import shutil
import argparse

def split_and_link(source_dir, output_dir, chunk_size_mb=10):
    chunk_size = chunk_size_mb * 1024 * 1024  # Size in byte
    chunk_index = 0
    current_chunk_size = 0
    current_chunk_dir = os.path.join(output_dir, f"emscripten_part_{chunk_index}")
    os.makedirs(current_chunk_dir, exist_ok=True)

    for root, dirs, files in os.walk(source_dir, topdown=False):
        for file in files:
            file_path = os.path.join(root, file)
            file_size = os.path.getsize(file_path)

            # If new part?
            if current_chunk_size + file_size > chunk_size and current_chunk_size > 0:
                chunk_index += 1
                current_chunk_dir = os.path.join(output_dir, f"emscripten_part_{chunk_index}")
                os.makedirs(current_chunk_dir, exist_ok=True)
                current_chunk_size = 0

            # Make relative path to recreate tree
            rel_path = os.path.relpath(file_path, source_dir)
            dest_path = os.path.join(current_chunk_dir, rel_path)
            os.makedirs(os.path.dirname(dest_path), exist_ok=True)
            shutil.copy2(file_path, dest_path)
            current_chunk_size += file_size

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Split a directory into parts and create symlinks at the original locations.")
    parser.add_argument("source", help="Source directory to split")
    parser.add_argument("output", help="Output directory for parts")
    parser.add_argument("--chunk-size", type=int, default=10, help="Chunk size in MB (default: 10)")
    args = parser.parse_args()

    split_and_link(args.source, args.output, args.chunk_size)
