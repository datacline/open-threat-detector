# Security Policy

## Supported Versions

We release patches for security vulnerabilities. Currently supported versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

The Open Threat Detector team takes security bugs seriously. We appreciate your efforts to responsibly disclose your findings.

### Please Do

- **Email security concerns** to: [security@example.com] (replace with actual email)
- **Provide detailed information**:
  - Description of the vulnerability
  - Steps to reproduce the issue
  - Potential impact
  - Suggested fix (if you have one)
  - Your contact information for follow-up

### Please Don't

- **Do NOT** open a public GitHub issue for security vulnerabilities
- **Do NOT** disclose the vulnerability publicly until we've had a chance to address it
- **Do NOT** exploit the vulnerability beyond what is necessary to demonstrate it

## Response Timeline

- **Initial Response**: Within 48 hours of report
- **Status Update**: Within 7 days with assessment
- **Fix Timeline**: Varies based on severity and complexity
- **Disclosure**: After fix is released and deployed

## Security Measures

### Script Security

Our detection scripts follow these security principles:

1. **Read-Only Operations**
   - Scripts NEVER modify system files
   - Scripts NEVER delete or alter configurations
   - Scripts ONLY detect and report

2. **No Data Transmission**
   - Scripts don't send data externally
   - All processing happens locally
   - No telemetry or analytics collected

3. **Minimal Privileges**
   - Most checks run with standard user permissions
   - Elevated privileges optional for system-wide checks
   - No requirement for admin/root access for core functionality

4. **No Code Execution**
   - Scripts don't execute untrusted code
   - No dynamic code generation
   - No eval or similar dangerous constructs

5. **Input Validation**
   - All inputs validated
   - Path traversal protections
   - Command injection protections

### Safe Deployment

When deploying detection scripts:

1. **Review Scripts Before Deployment**
   - Audit the code yourself
   - Understand what each script does
   - Verify no modifications to trusted sources

2. **Test in Isolated Environment**
   - Test on non-production systems first
   - Verify behavior matches documentation
   - Check for unexpected side effects

3. **Use Version Control**
   - Deploy specific tagged versions
   - Track what version is deployed where
   - Don't use scripts from arbitrary commits

4. **Monitor Execution**
   - Log script executions
   - Alert on unexpected failures
   - Review reports regularly

### MDM/EDR Integration Security

When integrating with MDM/EDR platforms:

1. **Use Platform Security Features**
   - Enable script signing (if available)
   - Use secure credential storage
   - Leverage platform RBAC

2. **Restrict Access**
   - Limit who can modify deployment configs
   - Audit changes to scripts and schedules
   - Use principle of least privilege

3. **Secure Reporting**
   - Encrypt reports in transit
   - Restrict access to compliance data
   - Comply with data retention policies

## Known Security Considerations

### False Positives

- Scripts may detect legitimate installations
- Organizations should have approved software lists
- Detection doesn't imply malicious intent

### False Negatives

- Novel installation methods may evade detection
- Scripts rely on known patterns
- Regular updates needed to catch new techniques

### Privacy

- Scripts detect software presence, not usage
- No user data or file contents collected
- Execution logs may contain user paths

### Permissions

- Some checks may require elevated privileges
- Document permission requirements clearly
- Provide alternatives for restricted environments

## Scope

### In Scope

- Vulnerabilities in detection scripts
- Security issues in documentation
- MDM integration security concerns
- Privacy violations
- Data leakage issues

### Out of Scope

- Theoretical vulnerabilities without proof of concept
- Social engineering attacks
- Denial of service via excessive script execution
- Issues in third-party MDM/EDR platforms
- Vulnerabilities in detected software itself

## Safe Harbor

We support safe harbor for security researchers who:

- Make a good faith effort to avoid privacy violations, data destruction, and service interruption
- Do not exploit vulnerabilities beyond minimal necessary testing
- Give us reasonable time to respond before disclosure
- Do not access or modify others' data without authorization

## Disclosure Policy

- Security patches will be released as soon as possible
- Security advisories will be published on GitHub
- CVEs will be requested for significant vulnerabilities
- Credit given to researchers (unless anonymity requested)

## Security Best Practices for Contributors

When contributing code:

1. **Never Hardcode Secrets**
   - No API keys, passwords, or tokens
   - Use environment variables or config files
   - Don't commit `.env` files

2. **Validate All Inputs**
   - Check file paths for traversal
   - Validate command arguments
   - Sanitize user inputs

3. **Use Safe APIs**
   - Avoid shell injection vectors
   - Use parameterized commands
   - Prefer language-native APIs

4. **Error Handling**
   - Don't expose sensitive info in errors
   - Log securely
   - Fail safely

5. **Dependencies**
   - Keep dependencies minimal
   - Use well-maintained packages
   - Review dependency security advisories

## Compliance

This project aims to comply with:

- **OWASP Top 10**: Address common security risks
- **CWE Top 25**: Mitigate dangerous software weaknesses
- **NIST Guidelines**: Follow security best practices
- **Secure Coding Standards**: Industry-standard secure development

## Security Updates

Subscribe to security updates:

- Watch this repository for security advisories
- Check releases for security patches
- Follow project announcements

## Questions

For non-security questions, use:
- GitHub Issues for bugs
- GitHub Discussions for questions
- Email for security concerns only

Thank you for helping keep Open Threat Detector secure!
