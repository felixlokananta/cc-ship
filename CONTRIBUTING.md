# Contributing to cc-ship

Thanks for your interest in improving cc-ship!

## Reporting bugs

Open an issue using the **Bug report** template. Include:
- Which skill or agent misbehaved (`/ship`, `/shipplan`, `@planner`, `@implementer`)
- The exact prompt you ran
- What happened vs. what you expected
- Your Claude Code version (`claude --version`)

## Suggesting changes

Open an issue using the **Feature request** template before writing any code, so we can align on the approach first.

## Making changes

1. Fork the repo and create a branch from `main`.
2. Edit the relevant file:
   - Skill behaviour → `skills/ship/SKILL.md` or `skills/shipplan/SKILL.md`
   - Planner behaviour → `agents/planner.md`
   - Implementer behaviour → `agents/implementer.md`
3. Test locally:
   ```bash
   # Symlink into Claude Code (first time only)
   bash install.sh

   # Run the skill against a real project
   cd ~/some-project
   # In Claude Code: /ship add a hello-world function
   ```
4. If you changed agent behaviour or the plan format, update `CLAUDE.md`.
5. Open a PR — the pull request template will guide you through the checklist.

## Commit style

Use [Conventional Commits](https://www.conventionalcommits.org/):
`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`

## Code of conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md). Be kind.
