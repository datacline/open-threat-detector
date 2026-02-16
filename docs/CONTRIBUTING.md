# Contributing to OpenClaw Threat Detector

Thank you for your interest in contributing to OpenClaw Threat Detector! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
- [Development Guidelines](#development-guidelines)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)
- [Reporting Issues](#reporting-issues)

## Code of Conduct

This project follows a code of conduct that we expect all contributors to adhere to:

- Be respectful and inclusive
- Welcome newcomers and help them get started
- Focus on constructive feedback
- Maintain professional communication
- Respect differing viewpoints and experiences

## Getting Started

### Prerequisites

- Git
- Basic understanding of shell scripting (Bash, PowerShell)
- Familiarity with at least one MDM/EDR platform
- Test environment for validation

### Fork and Clone

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/open-threat-detector.git
   cd open-threat-detector
   ```
3. Add upstream remote:
   ```bash
   git remote add upstream https://github.com/ORIGINAL_OWNER/open-threat-detector.git
   ```

## How to Contribute

### Types of Contributions

We welcome various types of contributions:

1. **Bug Fixes**: Fix issues in detection scripts
2. **New Detection Methods**: Add new checks for OpenClaw artifacts
3. **Platform Support**: Improve support for specific OS versions
4. **MDM Integration**: Add guides for additional MDM platforms
5. **Documentation**: Improve or expand documentation
6. **Testing**: Add test cases and validation scripts
7. **Examples**: Contribute deployment examples and configurations

### Areas for Contribution

- **Detection Logic**: Enhance detection capabilities
- **Performance**: Optimize script execution speed
- **Error Handling**: Improve error messages and handling
- **Platform Compatibility**: Expand OS support
- **Deployment Guides**: Add platform-specific deployment instructions
- **Reporting**: Enhance output formatting and reporting
- **Logging**: Improve verbose output and debugging

## Development Guidelines

### Shell Script Standards (Bash)

1. **Shebang**: Use `#!/usr/bin/env bash`
2. **Error Handling**: Use `set -euo pipefail` at the start
3. **Functions**: Use descriptive function names with verb_noun pattern
4. **Variables**: Use lowercase with underscores (snake_case)
5. **Constants**: Use UPPERCASE for constants
6. **Comments**: Add comments for complex logic
7. **Quoting**: Always quote variables: `"$variable"`
8. **Exit Codes**: Follow the standard (0=success, 1=detection, 2=error)

Example:
```bash
#!/usr/bin/env bash
set -euo pipefail

# Constants
readonly SCRIPT_VERSION="1.0.0"

# Global variables
openclaw_detected=false

check_cli_executable() {
    local cli_path
    if command -v openclaw &> /dev/null; then
        cli_path=$(command -v openclaw)
        echo "Found: $cli_path"
        return 0
    fi
    return 1
}
```

### PowerShell Script Standards

1. **Function Names**: Use Verb-Noun pattern (e.g., `Test-CLIExecutable`)
2. **Variables**: Use PascalCase for variables
3. **Parameters**: Use `[CmdletBinding()]` for advanced functions
4. **Error Handling**: Use try-catch blocks
5. **Output**: Use `Write-Host` with appropriate colors
6. **Comments**: Use PowerShell comment-based help

Example:
```powershell
function Test-CLIExecutable {
    [CmdletBinding()]
    param()

    Write-Verbose "Checking for CLI executable..."

    $PathExe = Get-Command openclaw -ErrorAction SilentlyContinue
    if ($PathExe) {
        Write-Host "Found: $($PathExe.Source)" -ForegroundColor Green
        return $true
    }
    return $false
}
```

### Documentation Standards

1. **README**: Keep README concise, move details to separate docs
2. **Code Comments**: Explain "why" not "what"
3. **Function Documentation**: Document parameters and return values
4. **Examples**: Provide practical, working examples
5. **Platform-Specific**: Clearly mark platform-specific content

### Commit Message Guidelines

Follow the conventional commit format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(detection): add Docker container detection for Windows

Add support for detecting OpenClaw Docker containers on Windows
systems using the Docker Desktop API.

Closes #123

fix(macos): correct launchd service path detection

The script was checking incorrect paths for launchd plists.
Updated to check all standard locations.

docs(deployment): add Kandji deployment guide

Comprehensive guide for deploying detection scripts via Kandji MDM
platform, including Blueprint configuration and reporting.
```

## Testing

### Running Tests

Before submitting changes, run the test suite:

```bash
# Run test script
./scripts/test-detection.sh

# Test specific platform scripts
./scripts/detect-openclaw.sh --verbose

# PowerShell tests (Windows)
.\scripts\Detect-OpenClaw.ps1 -Verbose
```

### Manual Testing

1. **Clean Environment**: Test on system without OpenClaw
   - Expected: Exit code 0
   - Expected: No detections in output

2. **Test Environment**: Create test artifacts
   - Create `~/.openclaw` directory
   - Add mock config file
   - Run detection script
   - Expected: Exit code 1
   - Expected: Detection messages

3. **Edge Cases**: Test unusual scenarios
   - Partial installations
   - Different installation paths
   - Permission restrictions

### Writing Tests

When adding new detection methods, include tests:

```bash
test_new_detection_method() {
    echo "Testing new detection method..."

    # Setup test conditions
    setup_test_artifacts

    # Run detection
    if ./detect-openclaw.sh > /tmp/test.log 2>&1; then
        exit_code=$?
    else
        exit_code=$?
    fi

    # Verify results
    if [[ $exit_code -eq 1 ]]; then
        echo "PASSED"
    else
        echo "FAILED"
    fi

    # Cleanup
    cleanup_test_artifacts
}
```

## Submitting Changes

### Pull Request Process

1. **Create Feature Branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make Changes**:
   - Write code following style guidelines
   - Add tests for new functionality
   - Update documentation
   - Test thoroughly

3. **Commit Changes**:
   ```bash
   git add .
   git commit -m "feat(scope): description"
   ```

4. **Push to Fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

5. **Create Pull Request**:
   - Go to GitHub and create PR
   - Fill out PR template completely
   - Link related issues
   - Request reviewers

### Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Code refactoring

## Testing
- [ ] Tested on Windows
- [ ] Tested on macOS
- [ ] Tested on Linux
- [ ] Added/updated tests
- [ ] All tests passing

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No new warnings generated
- [ ] Tested in clean environment

## Related Issues
Closes #(issue number)

## Screenshots (if applicable)
```

### Review Process

1. **Automated Checks**: CI/CD runs tests automatically
2. **Code Review**: Maintainers review code
3. **Feedback**: Address review comments
4. **Approval**: Changes approved by maintainers
5. **Merge**: PR merged to main branch

## Reporting Issues

### Bug Reports

Use the bug report template:

```markdown
**Describe the Bug**
Clear description of the bug

**To Reproduce**
Steps to reproduce:
1. Step 1
2. Step 2
3. ...

**Expected Behavior**
What should happen

**Actual Behavior**
What actually happened

**Environment**
- OS: [e.g., Windows 11, macOS 14.1, Ubuntu 22.04]
- Script Version: [e.g., 1.0.0]
- Shell: [e.g., Bash 5.1, PowerShell 7.3]

**Additional Context**
Any other relevant information

**Logs**
```
Paste relevant logs here
```
```

### Feature Requests

Use the feature request template:

```markdown
**Feature Description**
Clear description of the requested feature

**Use Case**
Why is this feature needed?

**Proposed Solution**
How should this work?

**Alternatives Considered**
Other approaches considered

**Additional Context**
Any other relevant information
```

### Security Issues

For security vulnerabilities:

1. **Do NOT** open a public issue
2. Email security concerns to: [security@example.com]
3. Include:
   - Description of vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

## Development Setup

### Recommended Tools

- **Text Editor**: VS Code, Sublime Text, or vim
- **Shell**: Bash 4+ or Zsh for macOS/Linux
- **PowerShell**: PowerShell 7+ recommended for Windows
- **Git**: Latest stable version
- **ShellCheck**: For bash script linting
  ```bash
  # Install ShellCheck
  brew install shellcheck  # macOS
  apt-get install shellcheck  # Ubuntu/Debian
  ```

### VS Code Extensions

Recommended extensions for development:

- ShellCheck (Bash linting)
- PowerShell
- Bash IDE
- GitLens
- Markdown All in One

### Local Development

```bash
# Clone repository
git clone https://github.com/YOUR_USERNAME/open-threat-detector.git
cd open-threat-detector

# Create development branch
git checkout -b dev/your-feature

# Make changes
# ... edit files ...

# Run linting (if ShellCheck installed)
shellcheck scripts/detect-openclaw.sh

# Run tests
./scripts/test-detection.sh

# Commit changes
git add .
git commit -m "feat: your feature description"
```

## Getting Help

- **Documentation**: Check README.md and DEPLOYMENT.md
- **Issues**: Search existing issues for similar problems
- **Discussions**: Use GitHub Discussions for questions
- **Community**: Join our community chat (if applicable)

## Recognition

Contributors will be recognized in:
- CONTRIBUTORS.md file
- Release notes
- Project documentation

Thank you for contributing to OpenClaw Threat Detector!
