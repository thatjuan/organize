# Contributing to organize

Thanks for your interest in contributing! This document outlines how to get started.

## Development Setup

1. Install [Rust](https://rustup.rs/) (1.70 or later)
2. Clone the repository:
   ```bash
   git clone https://github.com/thatjuan/organize.git
   cd organize
   ```
3. Build and test:
   ```bash
   cargo build
   cargo test
   ```

## Making Changes

1. Fork the repository
2. Create a feature branch: `git checkout -b my-feature`
3. Make your changes
4. Ensure tests pass: `cargo test`
5. Format code: `cargo fmt`
6. Check for lints: `cargo clippy`
7. Commit your changes
8. Push to your fork and open a Pull Request

## Code Style

- Run `cargo fmt` before committing
- Run `cargo clippy` and address any warnings
- Add tests for new functionality
- Use `anyhow::Context` for error messages that include relevant paths or values

## Testing

The project uses Rust's built-in test framework with `tempfile` for filesystem fixtures:

```bash
# Run all tests
cargo test

# Run a specific test
cargo test test_basic_flatten

# Run tests with output
cargo test -- --nocapture
```

When adding tests:
- Use `TempDir` for isolated filesystem operations
- Test both success and edge cases
- Clean up is automatic via `TempDir`'s Drop implementation

## Pull Request Guidelines

- Keep PRs focused on a single change
- Update documentation if needed
- Add tests for new features or bug fixes
- Ensure CI passes before requesting review

## Reporting Issues

When reporting bugs, please include:
- Your operating system and version
- Rust version (`rustc --version`)
- Steps to reproduce
- Expected vs actual behavior

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
