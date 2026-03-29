#!/usr/bin/env python3
"""
img-transfer - VM镜像动态迁移工具
Rewritten in Python from Go version
"""

import argparse
import hashlib
import http.server
import json
import os
import socketserver
import sys
import threading
import time
import urllib.parse
import urllib.request
import urllib.error
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from typing import Dict, List, Optional, Tuple

VERSION = "2.0.0"


def human_readable_size(size: int) -> str:
    """Convert size to human readable format."""
    float_size = float(size)
    for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
        if float_size < 1024.0:
            return f"{float_size:.1f} {unit}"
        float_size /= 1024.0
    return f"{float_size:.1f} PB"


class RangeHandler(http.server.SimpleHTTPRequestHandler):
    """HTTP handler that supports range requests."""

    def __init__(self, *args, directory: str = ".", delete_after: bool = False, token: str = "", **kwargs):
        self.directory = directory
        self.delete_after = delete_after
        self.token = token
        super().__init__(*args, **kwargs)

    def translate_path(self, path: str) -> str:
        """Translate URL path to filesystem path."""
        # Remove query and fragment
        path = path.split('?', 1)[0]
        path = path.split('#', 1)[0]
        # Normalize path
        path = os.path.normpath(urllib.parse.unquote(path))
        # Ensure it's within the directory
        full_path = os.path.join(self.directory, path.lstrip('/'))
        # Security check: prevent directory traversal
        if not os.path.commonpath([self.directory, full_path]) == self.directory:
            self.send_error(403, "Forbidden")
            return self.directory
        return full_path

    def do_GET(self):
        """Handle GET requests with range support."""
        # Auth check
        if self.token:
            auth_header = self.headers.get('Authorization', '')
            if auth_header != f"Bearer {self.token}":
                self.send_error(401, "Unauthorized")
                return

        # Health check
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            response = {"status": "ok", "version": VERSION}
            self.wfile.write(json.dumps(response).encode())
            return

        # List files
        if self.path == '/list':
            self.handle_list()
            return

        # File info
        if self.path.startswith('/info/'):
            self.handle_info()
            return

        # File download
        if self.path.startswith('/download/'):
            self.handle_download()
            return

        # Transfer complete notification
        if self.path.startswith('/complete/'):
            self.handle_complete()
            return

        # Default: serve files (for backward compatibility)
        super().do_GET()

    def handle_list(self):
        """Handle /list endpoint."""
        try:
            entries = []
            for entry in os.scandir(self.directory):
                if entry.is_file() and not entry.name.startswith('.'):
                    info = entry.stat()
                    entries.append({
                        "name": entry.name,
                        "size": info.st_size
                    })
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(entries).encode())
        except Exception as e:
            self.send_error(500, str(e))

    def handle_info(self):
        """Handle /info/{filename} endpoint."""
        filename = self.path[6:]  # Remove '/info/'
        filepath = os.path.join(self.directory, filename)
        if not os.path.isfile(filepath):
            self.send_error(404, "File not found")
            return
        try:
            info = os.stat(filepath)
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            response = {
                "name": filename,
                "size": info.st_size
            }
            self.wfile.write(json.dumps(response).encode())
        except Exception as e:
            self.send_error(500, str(e))

    def handle_download(self):
        """Handle /download/{filename} endpoint with range support."""
        filename = self.path[10:]  # Remove '/download/'
        filepath = os.path.join(self.directory, filename)
        if not os.path.isfile(filepath):
            self.send_error(404, "File not found")
            return

        try:
            file_size = os.path.getsize(filepath)
            range_header = self.headers.get('Range')

            if range_header:
                # Parse range header: bytes=start-end
                if not range_header.startswith('bytes='):
                    self.send_error(416, "Range Not Satisfiable")
                    return
                range_spec = range_header[6:]
                if '-' not in range_spec:
                    self.send_error(416, "Range Not Satisfiable")
                    return
                start_str, end_str = range_spec.split('-', 1)
                start = int(start_str) if start_str else 0
                end = int(end_str) if end_str else file_size - 1
                if start < 0 or end >= file_size or start > end:
                    self.send_error(416, "Range Not Satisfiable")
                    return
                length = end - start + 1

                self.send_response(206)
                self.send_header('Content-Range', f'bytes {start}-{end}/{file_size}')
                self.send_header('Content-Length', str(length))
                self.send_header('Accept-Ranges', 'bytes')
                self.send_header('Content-Disposition', f'attachment; filename="{filename}"')
                self.end_headers()

                with open(filepath, 'rb') as f:
                    f.seek(start)
                    remaining = length
                    while remaining > 0:
                        chunk_size = min(8192, remaining)
                        data = f.read(chunk_size)
                        if not data:
                            break
                        self.wfile.write(data)
                        remaining -= len(data)
            else:
                # Full file download
                self.send_response(200)
                self.send_header('Content-Length', str(file_size))
                self.send_header('Accept-Ranges', 'bytes')
                self.send_header('Content-Disposition', f'attachment; filename="{filename}"')
                self.end_headers()
                with open(filepath, 'rb') as f:
                    self.copyfile(f, self.wfile)
        except Exception as e:
            self.send_error(500, str(e))

    def handle_complete(self):
        """Handle /complete/{filename} endpoint."""
        filename = self.path[10:]  # Remove '/complete/'
        filepath = os.path.join(self.directory, filename)
        if not os.path.isfile(filepath):
            self.send_error(404, "File not found")
            return

        print(f"[*] Transfer complete: {filename}")

        deleted = False
        error = None
        if self.delete_after:
            try:
                os.remove(filepath)
                print(f"[+] Deleted: {filename}")
                deleted = True
            except Exception as e:
                error = str(e)
                print(f"[-] Delete failed: {filename} ({e})")

        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        response = {
            "deleted": deleted,
            "file": filename,
        }
        if error:
            response["error"] = error
        self.wfile.write(json.dumps(response).encode())

    def copy_data(self, source, destination):
        """Copy data from source to destination."""
        while True:
            data = source.read(8192)
            if not data:
                break
            destination.write(data)

    def log_message(self, format, *args):
        """Override to use print instead of stderr."""
        sys.stdout.write("%s - - [%s] %s\n" % (
            self.address_string(),
            self.log_date_time_string(),
            format % args))
        sys.stdout.flush()


def run_server(directory: str, port: int, delete_after: bool, token: str):
    """Run the server."""
    os.chdir(directory)
    handler = lambda *args, **kwargs: RangeHandler(
        *args,
        directory=directory,
        delete_after=delete_after,
        token=token,
        **kwargs
    )
    with socketserver.TCPServer(("", port), handler) as httpd:
        print(f"""
╔═══════════════════════════════════════════════════╗
║        img-transfer server v{VERSION}                ║
╠═══════════════════════════════════════════════════╣
║  Port:    {port:<39} ║
║  Dir:     {directory:<39} ║
║  Delete:  {delete_after:<39} ║
╚═══════════════════════════════════════════════════╝

""")
        print(f"[*] http://0.0.0.0:{port}\n")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n[*] Server stopped.")
            httpd.shutdown()


class Client:
    """Client for downloading files."""

    def __init__(self, server: str, file: str, out: str, workers: int, token: str, delete: bool, chunk_mb: int):
        self.server = server.rstrip('/')
        self.file = file
        self.out = out
        self.workers = workers
        self.token = token
        self.delete = delete
        self.chunk_size = chunk_mb * 1024 * 1024  # Convert MB to bytes
        self.progress_file = f"{out}.progress"
        self.temp_file = f"{out}.tmp"

    def run(self):
        """Run the client download process."""
        print(f"[*] Querying {self.server}...")
        try:
            size = self.get_file_info()
        except Exception as e:
            print(f"[-] {e}", file=sys.stderr)
            sys.exit(1)

        print(f"[*] File: {self.file} ({human_readable_size(size)})")
        print(f"[*] Output: {self.out}")
        print(f"[*] Workers: {self.workers}\n")

        # Calculate chunks
        chunks = []
        for start in range(0, size, self.chunk_size):
            end = start + self.chunk_size
            if end > size:
                end = size
            chunks.append({
                'index': len(chunks),
                'start': start,
                'end': end
            })

        # Check for existing progress
        done = set()
        if os.path.exists(self.temp_file):
            temp_stat = os.stat(self.temp_file)
            if temp_stat.st_size == size:
                if os.path.exists(self.progress_file):
                    try:
                        with open(self.progress_file, 'r') as f:
                            for line in f:
                                line = line.strip()
                                if line.isdigit():
                                    done.add(int(line))
                    except Exception:
                        pass  # Ignore progress file errors

        pending = [c for c in chunks if c['index'] not in done]
        print(f"[*] Chunks: {len(chunks)} total, {len(done)} done, {len(pending)} pending\n")

        if len(pending) == 0:
            print("[*] All chunks already downloaded")
        else:
            progressMu = threading.Lock()
            progressFile = self.out + ".progress"
            downloaded = 0
            # Initialize with already downloaded chunks
            for c in chunks:
                if c['index'] in done:
                    with progressMu:
                        downloaded += c['end'] - c['start']
            start_time = time.time()

            def append_progress(idx):
                with progressMu:
                    with open(progressFile, 'a') as f:
                        f.write(f"{idx}\n")

            def download_chunk(chunk):
                """Download a single chunk."""
                url = f"{self.server}/download/{self.file}"
                req = urllib.request.Request(url)
                req.add_header('Range', f"bytes={chunk['start']}-{chunk['end']-1}")
                if self.token:
                    req.add_header('Authorization', f"Bearer {self.token}")

                try:
                    with urllib.request.urlopen(req, timeout=30) as response:
                        if response.status not in (200, 206):
                            raise Exception(f"Server returned {response.status}")
                        data = response.read(chunk['end'] - chunk['start'])
                        with open(self.temp_file, 'r+b') as f:
                            f.seek(chunk['start'])
                            f.write(data)
                    with progressMu:
                        nonlocal downloaded
                        downloaded += chunk['end'] - chunk['start']
                        n = downloaded
                        append_progress(chunk['index'])
                    # Calculate and print progress without holding the lock
                    pct = n / size * 100
                    elapsed = time.time() - start_time
                    if elapsed > 0:
                        speed = n / elapsed / 1024 / 1024  # MB/s
                        print(f"\r[*] {pct:.1f}%% ({n//1024//1024}/{size//1024//1024} MB) {speed:.1f} MB/s", end="", flush=True)
                    else:
                        print(f"\r[*] {pct:.1f}%% ({n//1024//1024}/{size//1024//1024} MB)", end="", flush=True)
                    return True
                except Exception as e:
                    print(f"\n[-] Chunk {chunk['index']} failed: {e}", file=sys.stderr)
                    return False

            # Download chunks in parallel
            with ThreadPoolExecutor(max_workers=self.workers) as executor:
                futures = {executor.submit(download_chunk, chunk): chunk for chunk in pending}
                for future in as_completed(futures):
                    if not future.result():
                        print("[*] Run again to resume")
                        sys.exit(1)
                # Wait for all futures to complete
                for future in futures:
                    future.result()

            # Move to newline after progress
            print()

        # Rename temp file to output
        try:
            os.rename(self.temp_file, self.out)
        except Exception as e:
            print(f"[-] Rename failed: {e}", file=sys.stderr)
            sys.exit(1)

        # Clean up progress file
        if os.path.exists(self.progress_file):
            os.remove(self.progress_file)

        print(f"\n[+] Saved: {self.out}")

        # Notify server to delete source if requested
        if self.delete:
            print("[*] Notifying server to delete source...")
            self.notify_complete()

    def get_file_info(self) -> int:
        """Get file size from server."""
        url = f"{self.server}/info/{self.file}"
        req = urllib.request.Request(url)
        if self.token:
            req.add_header('Authorization', f"Bearer {self.token}")
        try:
            with urllib.request.urlopen(req, timeout=10) as response:
                if response.status != 200:
                    raise Exception(f"Server returned {response.status}")
                data = json.loads(response.read().decode())
                return data['size']
        except Exception as e:
            raise Exception(f"Failed to get file info: {e}")

    def notify_complete(self):
        """Notify server that transfer is complete."""
        url = f"{self.server}/complete/{self.file}"
        req = urllib.request.Request(url, method='POST')
        if self.token:
            req.add_header('Authorization', f"Bearer {self.token}")
        try:
            with urllib.request.urlopen(req, timeout=10) as response:
                data = json.loads(response.read().decode())
                if data.get('deleted'):
                    print("[+] Server deleted source file")
                elif 'error' in data:
                    print(f"[-] Server delete failed: {data['error']}")
        except Exception as e:
            print(f"[-] Notify failed: {e}")


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description='img-transfer - VM镜像动态迁移工具')
    parser.add_argument('command', choices=['serve', 'pull', 'version'], help='Command to run')
    parser.add_argument('--dir', default='.', help='Image directory (for serve)')
    parser.add_argument('--port', type=int, default=8080, help='Listen port (for serve)')
    parser.add_argument('--delete-after', action='store_true', help='Delete source after download (for serve)')
    parser.add_argument('--token', default='', help='Access token (optional)')
    parser.add_argument('--server', help='Server address (for pull)')
    parser.add_argument('--file', help='Remote filename (for pull)')
    parser.add_argument('--out', help='Local save path (for pull, defaults to remote filename)')
    parser.add_argument('--workers', type=int, default=4, help='Parallel download threads (for pull)')
    parser.add_argument('--chunk', type=int, default=64, help='Chunk size in MB (for pull)')
    parser.add_argument('--delete', action='store_true', help='Request server delete after download (for pull)')

    args = parser.parse_args()

    if args.command == 'version':
        print(f"img-transfer {VERSION}")
        return

    if args.command == 'serve':
        run_server(args.dir, args.port, args.delete_after, args.token)
    elif args.command == 'pull':
        if not args.server or not args.file:
            print("用法: img-transfer pull -server <url> -file <name>", file=sys.stderr)
            sys.exit(1)
        out = args.out if args.out else args.file
        client = Client(
            server=args.server,
            file=args.file,
            out=out,
            workers=args.workers,
            token=args.token,
            delete=args.delete,
            chunk_mb=args.chunk
        )
        client.run()


if __name__ == '__main__':
    main()