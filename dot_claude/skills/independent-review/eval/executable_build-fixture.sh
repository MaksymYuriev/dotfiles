#!/usr/bin/env bash
# Builds the seeded-bug fixture: a git repo whose base commit is a small search feature and whose uncommitted
# change adds debouncing with eight seeded cases (see expected.json). No install, no network.
# Usage: build-fixture.sh <empty-dir>   Writes the repo there and the task brief to <dir>/../brief.md.
set -euo pipefail
D=${1:?usage: build-fixture.sh <empty-dir>}
mkdir -p "$D" && cd "$D"
[[ -z "$(ls -A)" ]] || { echo "build-fixture: $D is not empty" >&2; exit 2; }
git init -q -b main
git config user.email eval@example.com && git config user.name eval && git config commit.gpgsign false
mkdir -p src/api

cat >src/api/client.ts <<'EOF'
export type SearchResult = { id: string; title: string };
export type SearchResponse = { items: SearchResult[] };

export async function fetchResults(query: string): Promise<SearchResponse> {
  const res = await fetch(`/api/search?q=${encodeURIComponent(query)}`);
  if (!res.ok) throw new Error(`search failed: ${res.status}`);
  const json: Partial<SearchResponse> = await res.json();
  return { items: json.items ?? [] };
}
EOF

cat >src/useSearch.ts <<'EOF'
import { useEffect, useState } from "react";

import { fetchResults, type SearchResult } from "@/api/client";

export function useSearch(query: string, limit: number) {
  const [results, setResults] = useState<SearchResult[]>([]);

  useEffect(() => {
    if (!query) return;
    fetchResults(query).then((data) => {
      setResults(data.items.slice(0, limit - 1));
    });
  }, [query, limit]);

  return results;
}
EOF

cat >src/SearchInput.tsx <<'EOF'
import { useState } from "react";

import { useSearch } from "@/useSearch";

type Props = { limit?: number; onSubmit: (query: string) => void };

export function SearchInput({ limit = 10, onSubmit }: Props) {
  const [query, setQuery] = useState("");
  const results = useSearch(query, limit);

  return (
    <div>
      <input value={query} onChange={(e) => setQuery(e.target.value)} />
      <ul>
        {results.map((r) => (
          <li key={r.id}>{r.title}</li>
        ))}
      </ul>
    </div>
  );
}
EOF
git add -A && git commit -qm "search input"

cat >src/api/client.ts <<'EOF'
export type SearchResult = { id: string; title: string };
export type SearchResponse = { items: SearchResult[] };

export async function fetchResults(query: string): Promise<SearchResponse> {
  let res: Response | undefined;
  for (let attempt = 0; attempt < 3; attempt++) {
    res = await fetch(`/api/search?q=${query}`);
    if (res.ok) break;
  }
  if (!res || !res.ok) throw new Error(`search failed: ${res?.status}`);
  const json: Partial<SearchResponse> = await res.json();
  return { items: json.items ?? [] };
}
EOF

cat >src/useSearch.ts <<'EOF'
import { useEffect, useState } from "react";

import { fetchResults, type SearchResult } from "@/api/client";

export function useSearch(query: string, limit: number, delay: number) {
  const [results, setResults] = useState<SearchResult[]>([]);

  useEffect(() => {
    if (!query) return;
    const wait = delay || 300;
    setTimeout(() => {
      fetchResults(query).then((data) => {
        setResults(data.items.slice(0, limit - 1));
      });
    }, wait);
  }, [query, limit, delay]);

  return results;
}
EOF

cat >src/SearchInput.tsx <<'EOF'
import { useState } from "react";

import { useSearch } from "@/useSearch";

type Props = {
  limit?: number;
  /** Debounce in ms. 0 disables debouncing. */
  delay?: number;
  onSubmit: (query: string) => void;
};

export function SearchInput({ limit = 10, delay = 300, onSubmit }: Props) {
  const [query, setQuery] = useState("");
  const results = useSearch(query, limit, delay);

  return (
    <div>
      <input
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        onKeyDown={(e) => {
          if (e.key === "enter") onSubmit(query);
        }}
      />
      <ul>
        {results.map((r) => (
          <li key={r.id}>{r.title}</li>
        ))}
      </ul>
    </div>
  );
}
EOF

cat >../brief.md <<'EOF'
# Task: debounce the search input

Add debouncing to `SearchInput` so typing doesn't fire a request per keystroke.

## Acceptance criteria

1. While the user types, at most one search request starts per `delay` ms (default 300).
2. `delay={0}` disables debouncing: every change searches immediately.
3. Pressing Enter calls `onSubmit` with the current query immediately.
4. No request or state update happens after `SearchInput` unmounts.

Out of scope: the API client and the results list.
EOF
echo "fixture: $D (brief: $(cd .. && pwd)/brief.md)"
