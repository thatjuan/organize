# Makefile for organize
# Directory Organization CLI Tool

BINARY_NAME = organize
INSTALL_DIR = /usr/local/bin
TEST_DIR = test_dirs
CARGO = cargo

# Default target
.PHONY: all
all: build

# Build release binary
.PHONY: build
build:
	$(CARGO) build --release

# Build debug binary
.PHONY: debug
debug:
	$(CARGO) build

# Install to system (requires sudo)
.PHONY: install
install: build
	@echo "Installing $(BINARY_NAME) to $(INSTALL_DIR)..."
	@if [ ! -d "$(INSTALL_DIR)" ]; then \
		sudo mkdir -p "$(INSTALL_DIR)"; \
	fi
	sudo cp target/release/$(BINARY_NAME) $(INSTALL_DIR)/$(BINARY_NAME)
	sudo chmod 755 $(INSTALL_DIR)/$(BINARY_NAME)
	@echo "Installation complete!"
	@echo "You can now run '$(BINARY_NAME)' from anywhere."

# Uninstall from system
.PHONY: uninstall
uninstall:
	@echo "Removing $(BINARY_NAME) from $(INSTALL_DIR)..."
	sudo rm -f $(INSTALL_DIR)/$(BINARY_NAME)
	@echo "Uninstallation complete!"

# Clean build artifacts
.PHONY: clean
clean:
	$(CARGO) clean
	rm -rf $(TEST_DIR)

# Run tests
.PHONY: test
test: build test-setup test-run test-cleanup
	@echo ""
	@echo "========================================"
	@echo "All tests passed!"
	@echo "========================================"

# Create test directory structure
.PHONY: test-setup
test-setup:
	@echo "========================================"
	@echo "Setting up test environment..."
	@echo "========================================"
	@# Create test directory
	@rm -rf $(TEST_DIR)
	@mkdir -p $(TEST_DIR)
	@# Test 1: Simple nested structure
	@mkdir -p $(TEST_DIR)/test1/subdir1/subsubdir
	@mkdir -p $(TEST_DIR)/test1/subdir2
	@echo "root file" > $(TEST_DIR)/test1/root.txt
	@echo "file in subdir1" > $(TEST_DIR)/test1/subdir1/file1.txt
	@echo "file in subsubdir" > $(TEST_DIR)/test1/subdir1/subsubdir/deep.txt
	@echo "file in subdir2" > $(TEST_DIR)/test1/subdir2/file2.txt
	@# Test 2: For --rename flag
	@mkdir -p $(TEST_DIR)/test2/photos/vacation
	@mkdir -p $(TEST_DIR)/test2/photos/birthday
	@mkdir -p $(TEST_DIR)/test2/docs
	@echo "vacation photo 1" > $(TEST_DIR)/test2/photos/vacation/img1.jpg
	@echo "vacation photo 2" > $(TEST_DIR)/test2/photos/vacation/img2.jpg
	@echo "birthday photo" > $(TEST_DIR)/test2/photos/birthday/img1.jpg
	@echo "document" > $(TEST_DIR)/test2/docs/readme.txt
	@# Test 3: For --delete flag
	@mkdir -p $(TEST_DIR)/test3/empty1/empty2
	@mkdir -p $(TEST_DIR)/test3/withfile
	@echo "content" > $(TEST_DIR)/test3/withfile/data.txt
	@# Test 4: Mixed scenario for --rename --delete
	@mkdir -p $(TEST_DIR)/test4/a/b/c
	@mkdir -p $(TEST_DIR)/test4/x/y
	@echo "file c" > $(TEST_DIR)/test4/a/b/c/file.txt
	@echo "file y" > $(TEST_DIR)/test4/x/y/file.txt
	@echo ""
	@echo "Test directories created successfully!"
	@echo ""

# Run all tests
.PHONY: test-run
test-run:
	@echo "========================================"
	@echo "Running tests..."
	@echo "========================================"
	@echo ""
	@# Test 1: Basic flatten
	@echo "[TEST 1/6] Testing basic flatten..."
	@./target/release/$(BINARY_NAME) flatten $(TEST_DIR)/test1
	@if [ -f "$(TEST_DIR)/test1/root.txt" ] && \
	    [ -f "$(TEST_DIR)/test1/file1.txt" ] && \
	    [ -f "$(TEST_DIR)/test1/deep.txt" ] && \
	    [ -f "$(TEST_DIR)/test1/file2.txt" ]; then \
		echo "  PASSED: All files flattened to root"; \
	else \
		echo "  FAILED: Files not properly flattened"; \
		ls -la $(TEST_DIR)/test1/; \
		exit 1; \
	fi
	@echo ""
	@# Reset test1 for next tests
	@rm -rf $(TEST_DIR)/test1
	@mkdir -p $(TEST_DIR)/test1/subdir1/subsubdir
	@mkdir -p $(TEST_DIR)/test1/subdir2
	@echo "root file" > $(TEST_DIR)/test1/root.txt
	@echo "file in subdir1" > $(TEST_DIR)/test1/subdir1/file1.txt
	@echo "file in subsubdir" > $(TEST_DIR)/test1/subdir1/subsubdir/deep.txt
	@echo "file in subdir2" > $(TEST_DIR)/test1/subdir2/file2.txt
	@# Test 2: Flatten with --delete
	@echo "[TEST 2/6] Testing flatten with --delete..."
	@./target/release/$(BINARY_NAME) flatten $(TEST_DIR)/test1 --delete
	@if [ -f "$(TEST_DIR)/test1/root.txt" ] && \
	    [ -f "$(TEST_DIR)/test1/file1.txt" ] && \
	    [ ! -d "$(TEST_DIR)/test1/subdir1" ] && \
	    [ ! -d "$(TEST_DIR)/test1/subdir2" ]; then \
		echo "  PASSED: Files flattened and empty dirs deleted"; \
	else \
		echo "  FAILED: Directories not properly cleaned"; \
		ls -laR $(TEST_DIR)/test1/; \
		exit 1; \
	fi
	@echo ""
	@# Test 3: Flatten with --rename (handles duplicate filenames)
	@echo "[TEST 3/6] Testing flatten with --rename..."
	@./target/release/$(BINARY_NAME) flatten $(TEST_DIR)/test2 --rename
	@if [ -f "$(TEST_DIR)/test2/vacation_img1.jpg" ] && \
	    [ -f "$(TEST_DIR)/test2/vacation_img2.jpg" ] && \
	    [ -f "$(TEST_DIR)/test2/birthday_img1.jpg" ] && \
	    [ -f "$(TEST_DIR)/test2/docs_readme.txt" ]; then \
		echo "  PASSED: Files renamed with parent folder prefix"; \
	else \
		echo "  FAILED: Files not properly renamed"; \
		ls -laR $(TEST_DIR)/test2/; \
		exit 1; \
	fi
	@echo ""
	@# Test 4: Flatten with --delete on structure with empty nested dirs
	@echo "[TEST 4/6] Testing flatten with --delete on nested empty dirs..."
	@./target/release/$(BINARY_NAME) flatten $(TEST_DIR)/test3 --delete
	@if [ -f "$(TEST_DIR)/test3/data.txt" ] && \
	    [ ! -d "$(TEST_DIR)/test3/empty1" ] && \
	    [ ! -d "$(TEST_DIR)/test3/withfile" ]; then \
		echo "  PASSED: Nested empty directories deleted"; \
	else \
		echo "  FAILED: Empty directories not properly cleaned"; \
		ls -laR $(TEST_DIR)/test3/; \
		exit 1; \
	fi
	@echo ""
	@# Test 5: Flatten with --rename --delete combined
	@echo "[TEST 5/6] Testing flatten with --rename --delete combined..."
	@./target/release/$(BINARY_NAME) flatten $(TEST_DIR)/test4 --rename --delete
	@if [ -f "$(TEST_DIR)/test4/c_file.txt" ] && \
	    [ -f "$(TEST_DIR)/test4/y_file.txt" ] && \
	    [ ! -d "$(TEST_DIR)/test4/a" ] && \
	    [ ! -d "$(TEST_DIR)/test4/x" ]; then \
		echo "  PASSED: Files renamed and empty dirs deleted"; \
	else \
		echo "  FAILED: Combined operation failed"; \
		ls -laR $(TEST_DIR)/test4/; \
		exit 1; \
	fi
	@echo ""
	@# Test 6: Flatten on already flat directory (no-op)
	@echo "[TEST 6/6] Testing flatten on already flat directory..."
	@mkdir -p $(TEST_DIR)/test5
	@echo "flat file" > $(TEST_DIR)/test5/flat.txt
	@./target/release/$(BINARY_NAME) flatten $(TEST_DIR)/test5
	@if [ -f "$(TEST_DIR)/test5/flat.txt" ]; then \
		echo "  PASSED: Already flat directory handled correctly"; \
	else \
		echo "  FAILED: Flat directory handling failed"; \
		exit 1; \
	fi
	@echo ""

# Cleanup test files
.PHONY: test-cleanup
test-cleanup:
	@echo "========================================"
	@echo "Cleaning up test files..."
	@echo "========================================"
	@rm -rf $(TEST_DIR)
	@echo "Cleanup complete!"

# Run cargo tests (unit tests)
.PHONY: cargo-test
cargo-test:
	$(CARGO) test

# Format code
.PHONY: fmt
fmt:
	$(CARGO) fmt

# Lint code
.PHONY: lint
lint:
	$(CARGO) clippy -- -D warnings

# Check code without building
.PHONY: check
check:
	$(CARGO) check

# Show help
.PHONY: help
help:
	@echo "organize Makefile"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  all          Build release binary (default)"
	@echo "  build        Build release binary"
	@echo "  debug        Build debug binary"
	@echo "  install      Install to $(INSTALL_DIR) (requires sudo)"
	@echo "  uninstall    Remove from $(INSTALL_DIR) (requires sudo)"
	@echo "  clean        Remove build artifacts and test files"
	@echo "  test         Run integration tests"
	@echo "  test-setup   Create test directories only"
	@echo "  test-run     Run tests only (requires test-setup first)"
	@echo "  test-cleanup Remove test files only"
	@echo "  cargo-test   Run cargo unit tests"
	@echo "  fmt          Format code with rustfmt"
	@echo "  lint         Run clippy linter"
	@echo "  check        Check code without building"
	@echo "  help         Show this help message"
	@echo ""
	@echo "Requirements:"
	@echo "  - Rust/Cargo (rustup.rs)"
