#!/usr/bin/env bash
set -euo pipefail

cd /workspace
test -f README.md

install_dir=/opt/profile-preview
sudo mkdir -p "$install_dir"
sudo chown -R "$(id -u):$(id -g)" "$install_dir"

cat > "$install_dir/package.json" <<'EOF'
{
  "name": "profile-preview",
  "private": true,
  "type": "module",
  "dependencies": {
    "marked": "18.1.1"
  }
}
EOF

cat > "$install_dir/server.mjs" <<'EOF'
import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { marked } from "marked";

const port = Number(process.env.PORT || 4321);
const readmePath = process.env.README_PATH || "/workspace/README.md";

const page = (body) => `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Profile README preview</title>
  <style>
    :root { color-scheme: light; }
    body { margin: 0; font: 16px/1.5 system-ui, sans-serif; color: #1f2328; background: #f6f8fa; }
    main { max-width: 860px; margin: 32px auto; padding: 32px; background: #fff; border: 1px solid #d0d7de; border-radius: 12px; }
    h1, h2, h3 { line-height: 1.25; }
    table { border-collapse: collapse; width: 100%; }
    th, td { border: 1px solid #d0d7de; padding: 8px 12px; text-align: left; }
    code { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; background: #f6f8fa; padding: 0.1em 0.35em; border-radius: 6px; }
    pre { background: #f6f8fa; padding: 16px; overflow: auto; border-radius: 8px; }
    pre code { background: transparent; padding: 0; }
    img { max-width: 100%; height: auto; }
    a { color: #0969da; }
  </style>
</head>
<body>
  <main>${body}</main>
</body>
</html>`;

const server = createServer(async (req, res) => {
  const url = new URL(req.url || "/", `http://127.0.0.1:${port}`);
  if (url.pathname === "/health") {
    res.writeHead(200, { "content-type": "text/plain; charset=utf-8" });
    res.end("ok");
    return;
  }
  if (url.pathname !== "/") {
    res.writeHead(404, { "content-type": "text/plain; charset=utf-8" });
    res.end("not found");
    return;
  }
  try {
    const markdown = await readFile(readmePath, "utf8");
    const rendered = marked.parse(markdown);
    const body = typeof rendered === "string" ? rendered : await rendered;
    res.writeHead(200, { "content-type": "text/html; charset=utf-8" });
    res.end(page(body));
  } catch (error) {
    const message = error instanceof Error ? error.message : "Failed to render README";
    res.writeHead(500, { "content-type": "text/plain; charset=utf-8" });
    res.end(message);
  }
});

server.listen(port, "0.0.0.0", () => {
  console.log(`profile preview listening on 0.0.0.0:${port}`);
});
EOF

cd "$install_dir"
npm install --omit=dev
test -f "$install_dir/node_modules/marked/package.json"
node --check "$install_dir/server.mjs"
echo "profile preview installed"
