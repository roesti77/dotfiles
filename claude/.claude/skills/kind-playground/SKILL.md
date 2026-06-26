---
name: kind-playground
description: "Scaffold a new local Kubernetes playground project from the kind+Cilium+Gateway API+cert-manager+mkcert template. Use when the user wants to bootstrap a fresh project based on this standard template."
---

# kind-playground

Scaffold a new project directory from the template stored in this skill at
`template/`. The template contains a working single-node kind cluster setup
with Cilium (kube-proxy replaced), Gateway API, cert-manager wired to mkcert,
and a shared Gateway terminating TLS for `*.localhost.direct`.

## What to do

1. Ask the user via `AskUserQuestion` for:
   - **Project name** (becomes the directory name and gets substituted into
     cluster name, README title, etc.)
   - **Parent directory** where to create the new project folder
     (default: `~/repos/company`, but offer the current working directory and
     a custom path as alternatives)
2. Validate the target directory `<parent>/<project>` does not already exist.
   If it does, ask the user whether to abort or pick a different name.
3. Copy the entire `template/` directory tree from this skill's directory
   (`~/.claude/skills/kind-playground/template/`) into the target, preserving
   structure and hidden files like `.envrc`.
4. Replace the literal placeholder `__PROJECT_NAME__` with the chosen project
   name in every file under the new project. Use:

   ```sh
   grep -rl __PROJECT_NAME__ <target> | xargs sed -i '' "s/__PROJECT_NAME__/<project>/g"
   ```

   (macOS `sed` requires the empty `''` after `-i`.)
5. Run `git init` inside the new project so direnv/devbox have a git root.
6. Report back: target path, what was created, and the next commands the user
   should run (`direnv allow`, then `task kind:prepare-local-cluster`).

## Notes

- Do not modify files outside the new target directory.
- The placeholder is a literal `__PROJECT_NAME__` and appears in: `README.md`,
  `manifests/kind/kind-config.yml`, `manifests/kind/taskfile.yml`. The cluster
  name becomes `<project>-playground`.
- Do not parametrize the domain (`localhost.direct`), Cilium version, or
  cluster topology — the user can edit those in the generated files if needed.
- Follow the `coding-rules` skill for any extra files you generate.
