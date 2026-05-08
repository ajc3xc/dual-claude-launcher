# Claude Code MCP Server — Design & Handoff Document

## The Idea

Claude Desktop + Desktop Commander is excellent for orchestration, system ops, and
human-in-the-loop iteration. Claude Code is excellent for autonomous coding tasks —
reading codebases, fixing bugs, writing tests, iterating without hand-holding.

The gap: you can't call Claude Code from Claude Desktop today. You have to context
switch to a terminal, run it manually, come back. This project bridges that gap by
wrapping Claude Code as an MCP server — so Claude Desktop can spawn, direct, and
monitor Claude Code sessions programmatically as just another tool call.

## What It Does

Three core MCP tools:

### `claude_code_run`
Spawns a Claude Code session against a target directory with a given prompt.
Returns a session ID immediately (non-blocking).

```
Input:
  - working_dir: string       # repo/project path
  - prompt: string            # the task to execute
  - session_id?: string       # optional, resumes existing session

Output:
  - session_id: string
  - status: "started"
  - pid: number
```

### `claude_code_status`
Polls a running session. Returns current status and tail of output.

```
Input:
  - session_id: string

Output:
  - status: "running" | "complete" | "failed" | "waiting_for_input"
  - output_tail: string       # last N lines of output
  - exit_code?: number
```

### `claude_code_output`
Gets full output of a session, optionally from a line offset for streaming.

```
Input:
  - session_id: string
  - offset?: number           # line offset for incremental reads

Output:
  - lines: string[]
  - total_lines: number
  - complete: boolean
```

Optional fourth tool:

### `claude_code_kill`
Terminates a running session.

```
Input:
  - session_id: string

Output:
  - killed: boolean
```

## Architecture

```
Claude Desktop (chat)
      │
      │  MCP tool calls
      ▼
claude-code-mcp (Node.js MCP server)
      │
      │  child_process.spawn()
      ▼
claude CLI (Claude Code)
      │
      │  reads/writes
      ▼
Target repo / filesystem
```

The MCP server is a thin Node.js process that:
1. Receives tool calls from Claude Desktop via stdio MCP protocol
2. Spawns `claude` CLI as a child process per session
3. Buffers stdout/stderr to a temp file per session ID
4. Responds to status/output polls by reading that buffer
5. Manages session lifecycle (start, poll, kill, cleanup)

## File Structure

```
claude-code-mcp/
├── README.md
├── package.json
├── tsconfig.json
├── src/
│   ├── index.ts              # MCP server entrypoint
│   ├── tools/
│   │   ├── run.ts            # claude_code_run tool
│   │   ├── status.ts         # claude_code_status tool
│   │   ├── output.ts         # claude_code_output tool
│   │   └── kill.ts           # claude_code_kill tool
│   ├── session-manager.ts    # spawns + tracks claude processes
│   └── types.ts              # shared types
└── sessions/                 # runtime output buffers (gitignored)
```

## MCP Config Entry

Add to `claude_desktop_config.json`:

```json
"claude-code-mcp": {
  "command": "node",
  "args": ["C:\\path\\to\\claude-code-mcp\\dist\\index.js"]
}
```

Or via npx once published:

```json
"claude-code-mcp": {
  "command": "npx",
  "args": ["-y", "claude-code-mcp"]
}
```

## Key Implementation Notes

### Claude Code CLI invocation
Claude Code is invoked as:
```
claude --print --dangerously-skip-permissions -p "<prompt>"
```
- `--print` outputs to stdout instead of interactive mode
- `--dangerously-skip-permissions` skips the "are you sure" prompts for autonomous use
- Working directory set via `cwd` option in spawn call

Check exact flags with `claude --help` — these may have changed.

### Session ID
Just a UUID generated at spawn time. Used as the key in a Map of active sessions
and as the filename for the output buffer in `sessions/`.

### Output buffering
Pipe stdout + stderr to a file at `sessions/{session_id}.log`. Status and output
tools just read from that file. Simple, no in-memory buffering needed.

### Blocking vs non-blocking
`claude_code_run` returns immediately with the session ID. The caller (Claude Desktop)
is expected to poll `claude_code_status` until complete. This mirrors how Desktop
Commander handles long-running processes.

### Waiting for input detection
Claude Code sometimes pauses and asks a question. Detect this by watching for
absence of new output for >10 seconds while process is still running. Surface as
`status: "waiting_for_input"` so Claude Desktop knows to send a follow-up prompt
via a new `claude_code_run` call with the same session ID.

## The Parallel Execution Pattern

Once built, the Claude Desktop workflow becomes:

```
User: "Refactor the auth module and add tests"

Claude Desktop:
  1. claude_code_run(working_dir="C:\myrepo", prompt="refactor auth module, add tests")
     → session_id: "abc-123"

  2. [continues other work in Desktop Commander while Claude Code runs]

  3. claude_code_status(session_id="abc-123")
     → status: "running", output_tail: "Reading auth.ts..."

  4. [polls every 30s or on user request]

  5. claude_code_status(session_id="abc-123")
     → status: "complete", exit_code: 0

  6. claude_code_output(session_id="abc-123")
     → full output of what Claude Code did
```

This is the loop that collapses the planning + coding layers into one conversation.

## Biggest Risks / Unknowns

1. **Claude Code CLI flags** — `--print` and non-interactive mode behavior needs
   verification. May need to pipe stdin from /dev/null to prevent hanging.

2. **Session resumption** — Claude Code has its own session system. Whether
   `--resume session_id` works headlessly needs testing.

3. **Output volume** — Claude Code is verbose. Output files can get large on long
   tasks. May need truncation or line limits on the output tool.

4. **Auth** — Claude Code needs to be authenticated on the machine already.
   The MCP server inherits the user's environment so this should just work,
   but needs verification.

5. **Windows paths** — spawn behavior on Windows with PowerShell vs cmd vs
   the claude.exe location needs testing. Claude Code installs to a different
   path than Claude Desktop.

## Estimated Build Time

- Day 1: Verify Claude Code CLI headless behavior, nail the spawn + buffer pattern
- Day 2: Build the 3-4 MCP tools, wire up session manager
- Day 3: Error handling, waiting_for_input detection, cleanup
- Day 4: README, demo, publish to npm as `claude-code-mcp`
- Day 5: Buffer for unknowns (especially risk #1 and #3)

## Relationship to dual-claude-launcher

This is the natural next layer on top of dual-claude-launcher:

```
dual-claude-launcher    →   two Claude Desktop windows running in parallel
claude-code-mcp         →   each window can now spawn Claude Code sessions
                            for autonomous coding tasks
```

Together: full greenfield dev stack in a conversation. No Cursor, no separate
terminal, no context switching. Claude Desktop orchestrates, Claude Code executes.

## Repo to create

`github.com/ajc3xc/claude-code-mcp`

Separate repo from dual-claude-launcher. Reference each other in READMEs.
