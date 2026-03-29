package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"time"
)

const version = "2.0.0"

func main() {
	if len(os.Args) < 2 {
		usage()
		os.Exit(1)
	}
	switch os.Args[1] {
	case "serve":
		runServer(os.Args[2:])
	case "pull":
		runPull(os.Args[2:])
	case "version":
		fmt.Printf("img-transfer %s\n", version)
	default:
		usage()
	}
}

func usage() {
	fmt.Print(`img-transfer v` + version + ` - VM镜像动态迁移工具

用法:
  img-transfer serve [options]   服务端(有镜像的机器)
  img-transfer pull [options]    客户端(Codespaces拉取)
  img-transfer version           版本

服务端(本地机器):
  img-transfer serve -dir /vm -port 8080 -delete-after

客户端(Codespaces):
  img-transfer pull -server http://host:8080 -file disk.img -workers 4
`)
}

// ======================== SERVER ========================

func runServer(args []string) {
	fs := flag.NewFlagSet("serve", flag.ExitOnError)
	port := fs.Int("port", 8080, "监听端口")
	dir := fs.String("dir", ".", "镜像目录")
	delAfter := fs.Bool("delete-after", false, "下载完成后删除源文件")
	token := fs.String("token", "", "访问令牌(可选)")
	fs.Parse(args)

	s := &Server{
		Dir:         *dir,
		DeleteAfter: *delAfter,
		Token:       *token,
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/health", s.auth(s.handleHealth))
	mux.HandleFunc("/list", s.auth(s.handleList))
	mux.HandleFunc("/info/", s.auth(s.handleInfo))
	mux.HandleFunc("/download/", s.auth(s.handleDownload))
	mux.HandleFunc("/complete/", s.auth(s.handleComplete))

	fmt.Printf(`
╔══════════════════════════════════════════════════╗
║        img-transfer server v%s                ║
╠══════════════════════════════════════════════════╣
║  Port:    %-39d ║
║  Dir:     %-39s ║
║  Delete:  %-39v ║
╚══════════════════════════════════════════════════╝

`, version, *port, *dir, *delAfter)

	fmt.Printf("[*] http://0.0.0.0:%d\n\n", *port)
	http.ListenAndServe(fmt.Sprintf(":%d", *port), mux)
}

type Server struct {
	Dir         string
	DeleteAfter bool
	Token       string
}

func (s *Server) auth(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if s.Token != "" {
			t := r.Header.Get("Authorization")
			if t != "Bearer "+s.Token {
				http.Error(w, "unauthorized", 401)
				return
			}
		}
		next(w, r)
	}
}

func (s *Server) handleHealth(w http.ResponseWriter, r *http.Request) {
	json.NewEncoder(w).Encode(map[string]string{"status": "ok", "version": version})
}

func (s *Server) handleList(w http.ResponseWriter, r *http.Request) {
	entries, _ := os.ReadDir(s.Dir)
	var files []map[string]interface{}
	for _, e := range entries {
		if e.IsDir() || strings.HasPrefix(e.Name(), ".") {
			continue
		}
		info, _ := e.Info()
		files = append(files, map[string]interface{}{
			"name": e.Name(),
			"size": info.Size(),
		})
	}
	json.NewEncoder(w).Encode(files)
}

func (s *Server) handleInfo(w http.ResponseWriter, r *http.Request) {
	name := filepath.Base(strings.TrimPrefix(r.URL.Path, "/info/"))
	path := filepath.Join(s.Dir, name)
	info, err := os.Stat(path)
	if err != nil {
		http.Error(w, "not found", 404)
		return
	}
	json.NewEncoder(w).Encode(map[string]interface{}{
		"name": name,
		"size": info.Size(),
	})
}

func (s *Server) handleDownload(w http.ResponseWriter, r *http.Request) {
	name := filepath.Base(strings.TrimPrefix(r.URL.Path, "/download/"))
	path := filepath.Join(s.Dir, name)

	f, err := os.Open(path)
	if err != nil {
		http.Error(w, "not found", 404)
		return
	}
	defer f.Close()

	info, _ := f.Stat()
	size := info.Size()

	w.Header().Set("Content-Length", strconv.FormatInt(size, 10))
	w.Header().Set("Accept-Ranges", "bytes")

	rangeHeader := r.Header.Get("Range")
	if rangeHeader != "" {
		start, end, ok := parseRange(rangeHeader, size)
		if !ok {
			http.Error(w, "invalid range", 416)
			return
		}
		f.Seek(start, io.SeekStart)
		w.Header().Set("Content-Range", fmt.Sprintf("bytes %d-%d/%d", start, end-1, size))
		w.Header().Set("Content-Length", strconv.FormatInt(end-start, 10))
		w.WriteHeader(206)
		io.CopyN(w, f, end-start)
		return
	}

	w.Header().Set("Content-Disposition", fmt.Sprintf(`attachment; filename="%s"`, name))
	io.Copy(w, f)
}

func parseRange(h string, size int64) (start, end int64, ok bool) {
	if !strings.HasPrefix(h, "bytes=") {
		return 0, 0, false
	}
	parts := strings.SplitN(h[6:], "-", 2)
	if len(parts) != 2 {
		return 0, 0, false
	}
	if parts[0] == "" {
		suffix, err := strconv.ParseInt(parts[1], 10, 64)
		if err != nil {
			return 0, 0, false
		}
		if suffix > size {
			suffix = size
		}
		return size - suffix, size, true
	}
	start, err := strconv.ParseInt(parts[0], 10, 64)
	if err != nil {
		return 0, 0, false
	}
	if parts[1] == "" {
		return start, size, true
	}
	end, err = strconv.ParseInt(parts[1], 10, 64)
	if err != nil {
		return 0, 0, false
	}
	end++
	if end > size {
		end = size
	}
	return start, end, true
}

func (s *Server) handleComplete(w http.ResponseWriter, r *http.Request) {
	name := filepath.Base(strings.TrimPrefix(r.URL.Path, "/complete/"))
	path := filepath.Join(s.Dir, name)

	fmt.Printf("[*] Transfer complete: %s\n", name)

	if s.DeleteAfter {
		if err := os.Remove(path); err != nil {
			fmt.Printf("[-] Delete failed: %s (%v)\n", name, err)
			json.NewEncoder(w).Encode(map[string]interface{}{
				"deleted": false,
				"error":   err.Error(),
			})
			return
		}
		fmt.Printf("[+] Deleted: %s\n", name)
	}

	json.NewEncoder(w).Encode(map[string]interface{}{
		"deleted": s.DeleteAfter,
		"file":    name,
	})
}

// ======================== CLIENT ========================

func runPull(args []string) {
	fs := flag.NewFlagSet("pull", flag.ExitOnError)
	server := fs.String("server", "", "服务端地址")
	file := fs.String("file", "", "远程文件名")
	out := fs.String("out", "", "本地保存路径")
	workers := fs.Int("workers", 4, "并行下载线程数")
	token := fs.String("token", "", "访问令牌")
	delAfter := fs.Bool("delete", false, "下载完成后请求服务端删除")
	chunkMB := fs.Int("chunk", 64, "每块大小(MB)")
	fs.Parse(args)

	if *server == "" || *file == "" {
		fmt.Fprintln(os.Stderr, "用法: img-transfer pull -server <url> -file <name>")
		os.Exit(1)
	}
	if *out == "" {
		*out = *file
	}

	client := &Client{
		Server:    strings.TrimRight(*server, "/"),
		File:      *file,
		Out:       *out,
		Workers:   *workers,
		Token:     *token,
		Delete:    *delAfter,
		ChunkSize: int64(*chunkMB) * 1024 * 1024,
	}
	client.Run()
}

type Client struct {
	Server    string
	File      string
	Out       string
	Workers   int
	Token     string
	Delete    bool
	ChunkSize int64
}

type Chunk struct {
	Index int
	Start int64
	End   int64
}

func (c *Client) Run() {
	fmt.Printf("[*] Querying %s...\n", c.Server)
	size, err := c.getFileInfo()
	if err != nil {
		fmt.Fprintf(os.Stderr, "[-] %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("[*] File: %s (%d MB)\n", c.File, size/1024/1024)
	fmt.Printf("[*] Output: %s\n", c.Out)
	fmt.Printf("[*] Workers: %d\n", c.Workers)

	var chunks []Chunk
	for start := int64(0); start < size; start += c.ChunkSize {
		end := start + c.ChunkSize
		if end > size {
			end = size
		}
		chunks = append(chunks, Chunk{Index: len(chunks), Start: start, End: end})
	}

	tmpFile := c.Out + ".tmp"
	done := make(map[int]bool)
	if stat, err := os.Stat(tmpFile); err == nil && stat.Size() == size {
		progressFile := c.Out + ".progress"
		if data, err := os.ReadFile(progressFile); err == nil {
			for _, line := range strings.Split(string(data), "\n") {
				if idx, err := strconv.Atoi(strings.TrimSpace(line)); err == nil {
					done[idx] = true
				}
			}
		}
	}

	if _, err := os.Stat(tmpFile); os.IsNotExist(err) {
		f, _ := os.Create(tmpFile)
		f.Truncate(size)
		f.Close()
	}

	var pending []Chunk
	for _, ch := range chunks {
		if !done[ch.Index] {
			pending = append(pending, ch)
		}
	}

	fmt.Printf("[*] Chunks: %d total, %d done, %d pending\n\n", len(chunks), len(done), len(pending))

	if len(pending) == 0 {
		fmt.Println("[*] All chunks already downloaded")
	} else {
		var downloaded atomic.Int64
		for _, ch := range chunks {
			if done[ch.Index] {
				downloaded.Add(ch.End - ch.Start)
			}
		}

		progressMu := sync.Mutex{}
		progressFile := c.Out + ".progress"

		appendProgress := func(idx int) {
			progressMu.Lock()
			f, _ := os.OpenFile(progressFile, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
			fmt.Fprintf(f, "%d\n", idx)
			f.Close()
			progressMu.Unlock()
		}

		ch := make(chan Chunk, len(pending))
		for _, c := range pending {
			ch <- c
		}
		close(ch)

		var wg sync.WaitGroup
		var failErr atomic.Value

		startTime := time.Now()

		for i := 0; i < c.Workers; i++ {
			wg.Add(1)
			go func() {
				defer wg.Done()
				for chunk := range ch {
					if failErr.Load() != nil {
						return
					}
					if err := c.downloadChunk(tmpFile, chunk); err != nil {
						failErr.Store(fmt.Errorf("chunk %d: %w", chunk.Index, err))
						return
					}
					appendProgress(chunk.Index)
					n := downloaded.Add(chunk.End - chunk.Start)
					pct := float64(n) / float64(size) * 100
					speed := float64(n) / time.Since(startTime).Seconds() / 1024 / 1024
					fmt.Printf("\r[*] %.1f%% (%d/%d MB) %.1f MB/s", pct, n/1024/1024, size/1024/1024, speed)
				}
			}()
		}
		wg.Wait()
		fmt.Println()

		if err, ok := failErr.Load().(error); ok {
			fmt.Fprintf(os.Stderr, "\n[-] %v\n", err)
			fmt.Println("[*] Run again to resume")
			os.Exit(1)
		}
	}

	if err := os.Rename(tmpFile, c.Out); err != nil {
		fmt.Fprintf(os.Stderr, "[-] Rename failed: %v\n", err)
		os.Exit(1)
	}
	os.Remove(c.Out + ".progress")

	fmt.Printf("\n[+] Saved: %s\n", c.Out)

	if c.Delete {
		fmt.Println("[*] Notifying server to delete source...")
		c.notifyComplete()
	}
}

func (c *Client) getFileInfo() (int64, error) {
	url := c.Server + "/info/" + c.File
	req, _ := http.NewRequest("GET", url, nil)
	if c.Token != "" {
		req.Header.Set("Authorization", "Bearer "+c.Token)
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return 0, err
	}
	defer resp.Body.Close()
	if resp.StatusCode != 200 {
		return 0, fmt.Errorf("server returned %d", resp.StatusCode)
	}
	var info struct {
		Name string `json:"name"`
		Size int64  `json:"size"`
	}
	json.NewDecoder(resp.Body).Decode(&info)
	return info.Size, nil
}

func (c *Client) downloadChunk(file string, chunk Chunk) error {
	url := c.Server + "/download/" + c.File
	req, _ := http.NewRequest("GET", url, nil)
	req.Header.Set("Range", fmt.Sprintf("bytes=%d-%d", chunk.Start, chunk.End-1))
	if c.Token != "" {
		req.Header.Set("Authorization", "Bearer "+c.Token)
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 206 && resp.StatusCode != 200 {
		return fmt.Errorf("server returned %d", resp.StatusCode)
	}

	f, err := os.OpenFile(file, os.O_WRONLY, 0644)
	if err != nil {
		return err
	}
	defer f.Close()

	f.Seek(chunk.Start, io.SeekStart)
	_, err = io.CopyN(f, resp.Body, chunk.End-chunk.Start)
	return err
}

func (c *Client) notifyComplete() {
	url := c.Server + "/complete/" + c.File
	req, _ := http.NewRequest("POST", url, nil)
	if c.Token != "" {
		req.Header.Set("Authorization", "Bearer "+c.Token)
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		fmt.Printf("[-] Notify failed: %v\n", err)
		return
	}
	defer resp.Body.Close()

	var result map[string]interface{}
	json.NewDecoder(resp.Body).Decode(&result)
	if deleted, _ := result["deleted"].(bool); deleted {
		fmt.Println("[+] Server deleted source file")
	}
}
