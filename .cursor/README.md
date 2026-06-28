# Cursor Project Rules for SelfHost

This directory contains the modern Cursor Project Rules configuration for the SelfHost repository, using the `.mdc` (Markdown with frontmatter) format.

## Rule Types and Usage

### 📌 **Always Applied Rules** (`alwaysApply: true`)
These rules are automatically attached to all AI conversations in this project:

- **`project-overview.mdc`** - Core project context, architecture, and conventions
- **`security-practices.mdc`** - Security guidelines and best practices

### 🔄 **Auto-Attached Rules** (`autoApply: true`)
These rules automatically attach based on file patterns:

- **`coding-guidelines.mdc`** - Applies to `*.sh`, `*.container`, and script files
- **`contribution-guidelines.mdc`** - Applies to `apps/`, `README.md`, and setup files

### 📋 **Manual Rules** (`manualApply: true`)
These rules must be explicitly requested when needed:

- **`deployment-guidelines.mdc`** - Deployment procedures, testing, and troubleshooting

## How Rules Work

### Automatic Application
- **Always Applied**: Rules with `alwaysApply: true` are included in every conversation
- **Auto-Attached**: Rules with `autoApply: true` attach based on `globs` patterns when you open relevant files

### Manual Application
- **Manual Rules**: Use `@filename` or describe the rule you want to apply
- Example: `@deployment-guidelines` or "apply deployment guidelines"

### File Patterns (Globs)
Rules target specific files using glob patterns:
- `"**/*.sh"` - All shell scripts in any directory
- `"apps/**/*"` - Everything in the apps directory
- `"**/*"` - All files in the repository

## Migration from Legacy .cursorrules

The previous `.cursorrules` file has been replaced by these Project Rules. The new format provides:

✅ **Better Organization**: Separate files for different concerns
✅ **Scoped Application**: Rules apply only to relevant files
✅ **Flexible Types**: Always, Auto, Manual application modes
✅ **Enhanced Context**: More detailed and contextual guidance

## Best Practices

1. **Rule Naming**: Use descriptive filenames (e.g., `coding-guidelines.mdc`)
2. **Frontmatter**: Always include proper frontmatter with description and globs
3. **Content Structure**: Use clear headings and organized sections
4. **File Patterns**: Be specific with globs to target relevant files
5. **Rule Types**: Choose appropriate application type (Always/Auto/Manual)

## Usage Examples

- **Working on shell scripts**: Coding guidelines automatically apply
- **Adding new services**: Contribution guidelines automatically apply
- **Deployment tasks**: Manually request deployment guidelines
- **Security concerns**: Security practices always available
- **General context**: Project overview always provided

The rules ensure consistent development practices, security awareness, and proper documentation across the SelfHost ecosystem.
