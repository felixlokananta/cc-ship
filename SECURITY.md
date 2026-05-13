# Security Policy

## Scope

cc-ship is a prompt-only repository — it contains no running servers, no stored credentials, and no user data. The primary security concern is **prompt injection**: malicious content in a GitHub issue or codebase that causes `@planner` or `@implementer` to take unintended actions.

## Supported versions

Only the latest commit on `main` is supported.

## Reporting a vulnerability

**Do not open a public GitHub issue for security reports.**

Please report vulnerabilities privately via [GitHub Security Advisories](https://github.com/felixlokananta/cc-ship/security/advisories/new) or email **felixlokananta@gmail.com**.

Include:
- A description of the vulnerability
- Steps to reproduce (e.g., a crafted prompt or issue body that triggers the behaviour)
- The potential impact

You can expect an acknowledgement within 72 hours and a resolution or status update within 14 days.
