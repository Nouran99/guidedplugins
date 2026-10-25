---
name: "install-roles"
description: "Install the 22 subagent roles of Clean Code into Codex, where a plugin cannot activate them by itself. Run only when the user asks for it by name."
---
# Install the Clean Code subagent roles

A Codex plugin cannot activate subagent roles. This plugin ships its 22 roles as files in the `roles/` folder next to this SKILL.md, and this skill copies them to where Codex reads custom roles.

1. Ask where to install them, unless the user already said: for all projects (`${CODEX_HOME:-$HOME/.codex}/agents`) or only for the current project (`<project root>/.codex/agents`, which Codex reads only in trusted projects). Default to all projects.
2. Copy the files, never overwriting one that already exists, so nothing the user wrote is lost:

   ```bash
   dest="${CODEX_HOME:-$HOME/.codex}/agents"   # or <project root>/.codex/agents
   mkdir -p "$dest"
   for f in <the roles folder next to this SKILL.md>/*.toml; do [ -e "$dest/$(basename "$f")" ] || cp "$f" "$dest/"; done
   ```

   The destination is outside what the Codex sandbox lets a session write (it keeps `.codex` read-only, even inside the project), so ask for approval to run the command and do not look for another way around the sandbox. If it cannot run (for example in `codex exec`, where nobody can approve), print the command with the real paths filled in and ask the user to run it.

3. Tell the user which roles were installed and which were skipped because a file of that name was already there. Codex reads roles when a session starts, so they are available from the next session.
4. Tell the user the cost: Codex lists every installed role in each request, about 5 KB for these 22 roles, so install the books they actually use. To remove them, delete exactly the files that are in the `roles/` folder from the destination.

A role is a prompt, not a sandbox: Codex does not let a role file restrict tools. The read-only roles keep to that only by their instructions. For enforcement, start Codex with `codex --sandbox read-only`.

Do nothing else: do not edit `config.toml` and do not install roles of other plugins.
