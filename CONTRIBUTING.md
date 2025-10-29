# Contributing to yjump

Thank you for your interest in contributing to yjump!

## Code Style

This project uses [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) to maintain consistent code style across the codebase. The formatting rules are defined in `.swiftformat`.

### Installing SwiftFormat

```bash
make install-formatter
```

This will install SwiftFormat on your system (macOS or Linux).

### Formatting Code

Code is automatically formatted when you run:

```bash
make build
```

You can also format code manually:

```bash
make format
```

### Checking Formatting

To check if your code is properly formatted without making changes:

```bash
make format-check
```

## Development Workflow

1. **Make your changes** to the Swift source files in `src/`
2. **Build and test** your changes:
   ```bash
   make build
   make test
   ```
3. **Format your code** (happens automatically during build):
   ```bash
   make format
   ```
4. **Commit your changes** with a clear commit message

## Coding Standards

- Follow the Swift API Design Guidelines
- Use 2 spaces for indentation (enforced by SwiftFormat)
- Maximum line width of 80 characters
- Add blank lines around MARK comments
- Sort imports alphabetically (testable imports at bottom)
- Use descriptive variable and function names
- Add comments for complex logic

## Testing

Please add tests for new features:

- Place tests in `tests/` directory
- Follow the naming convention: `*Tests.swift`
- Run tests with `make test`

## Building

The build process automatically:
1. Formats all Swift source files
2. Compiles the application
3. Generates a versioned binary

```bash
make build
```

## Pull Request Process

1. Ensure all tests pass (`make test`)
2. Ensure code is properly formatted (`make format-check`)
3. Update documentation if needed
4. Create a pull request with a clear description of changes

## Questions?

Feel free to open an issue for questions or discussions!
