# AI-assisted git commit using Codex

if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
  echo "gcai: not inside a git repository"
  return 1
end

if git diff --cached --quiet
  echo "gcai: no staged changes to commit"
  return 1
end

set -l no_verify false
if test (count $argv) -gt 0
  if test $argv[1] = "--no-verify"
    set no_verify true
    set -e argv[1]
  else
    echo "gcai: unknown option $argv[1]"
    return 1
  end
end

set diff (git diff --cached)
set prompt "You are a senior engineer writing a git commit message for the staged diff below. Produce text in this exact format: A single short first line summary (<=72 chars), then a blank line, then a concise list of semantic changes (bullets or short paragraphs). Do not add quotes, prefixes, git trailers, or commentary. Only describe changes present in the staged diff.\n\n$diff"

set response (codex --sandbox danger-full-access --ask-for-approval never exec -- $prompt)
if test $status -ne 0
  echo "gcai: Codex invocation failed"
  return 1
end

set message (string trim -- $response)

if test -z "$message"
  echo "gcai: empty commit message from Codex"
  return 1
end

if test $no_verify = true
  git commit --no-verify -m "$message"
else
  git commit -m "$message"
end
