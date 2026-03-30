# Security Policy

## Supported Versions

| Version | Supported          |
|---------|--------------------|
| main    | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in Mercury Server, **please do not open a public issue.**

Instead, report it privately by emailing the maintainers or using GitHub's
[private vulnerability reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability) feature on this repository.

Please include:

- A description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

We will acknowledge your report within **48 hours** and aim to release a fix within **7 days** for critical issues.

## Security Considerations

Mercury Server is a lightweight HTTP/1.1 server written in Zig. Current security measures include:

- **Header size limits** to prevent buffer overflow attacks
- **Body size limits** to prevent memory exhaustion
- **Path traversal protection** on static file serving
- **Connection timeouts** to mitigate slowloris-style attacks

### Known Limitations

- No TLS support — use a reverse proxy (e.g., nginx, Caddy) for HTTPS termination
- No authentication or authorization framework built-in
- No rate limiting — should be handled at the infrastructure layer

## Responsible Disclosure

We follow a responsible disclosure model. We ask that you:

1. Give us reasonable time to fix the issue before any public disclosure
2. Make a good faith effort to avoid privacy violations, data destruction, or service disruption
3. Do not exploit the vulnerability beyond what is necessary to demonstrate it
