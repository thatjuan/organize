use anyhow::{Context, Result};
use clap::{Parser, Subcommand};
use std::collections::HashSet;
use std::fs;
use std::path::{Path, PathBuf};
use walkdir::WalkDir;

#[derive(Parser)]
#[command(name = "organize")]
#[command(author = "thatjuan")]
#[command(version = "0.1.0")]
#[command(about = "A CLI tool for organizing directories in *nix systems")]
struct Args {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Flatten a directory by moving all nested files to the root level
    Flatten {
        /// The path to flatten
        path: PathBuf,

        /// Rename files by prepending the immediate parent folder name
        #[arg(long)]
        rename: bool,

        /// Delete empty folders after flattening
        #[arg(long)]
        delete: bool,
    },
}

fn main() -> Result<()> {
    let args = Args::parse();

    match args.command {
        Commands::Flatten {
            path,
            rename,
            delete,
        } => {
            flatten_directory(&path, rename, delete)?;
        }
    }

    Ok(())
}

/// Flatten a directory by moving all files from subdirectories to the root level
fn flatten_directory(root: &Path, rename: bool, delete_empty: bool) -> Result<()> {
    let root = root
        .canonicalize()
        .with_context(|| format!("Failed to resolve path: {}", root.display()))?;

    // Collect all files that need to be moved (excluding files already at root)
    let mut files_to_move: Vec<(PathBuf, PathBuf)> = Vec::new();
    let mut directories: HashSet<PathBuf> = HashSet::new();

    for entry in WalkDir::new(&root)
        .min_depth(1)
        .into_iter()
        .filter_map(|e| e.ok())
    {
        let path = entry.path();

        if path.is_dir() {
            directories.insert(path.to_path_buf());
        } else if path.is_file() {
            // Only process files that are in subdirectories (not directly in root)
            let parent = path.parent().unwrap();
            if parent != root {
                let file_name = path.file_name().unwrap().to_string_lossy();
                let new_name = if rename {
                    // Get the immediate parent folder name
                    let parent_name = parent.file_name().unwrap().to_string_lossy();
                    format!("{}_{}", parent_name, file_name)
                } else {
                    file_name.to_string()
                };

                let dest = root.join(&new_name);
                files_to_move.push((path.to_path_buf(), dest));
            }
        }
    }

    // Handle filename conflicts by adding numeric suffixes
    let mut used_names: HashSet<PathBuf> = HashSet::new();

    // First, collect existing files at root level
    for entry in fs::read_dir(&root)? {
        let entry = entry?;
        if entry.path().is_file() {
            used_names.insert(entry.path());
        }
    }

    // Move files, handling conflicts
    for (src, mut dest) in files_to_move {
        // If destination already exists or is already used, add a numeric suffix
        if used_names.contains(&dest) || dest.exists() {
            let stem = dest.file_stem().unwrap().to_string_lossy().to_string();
            let ext = dest
                .extension()
                .map(|e| format!(".{}", e.to_string_lossy()))
                .unwrap_or_default();

            let mut counter = 1;
            loop {
                let new_name = format!("{}_{}{}", stem, counter, ext);
                dest = root.join(&new_name);
                if !used_names.contains(&dest) && !dest.exists() {
                    break;
                }
                counter += 1;
            }
        }

        fs::rename(&src, &dest).with_context(|| {
            format!(
                "Failed to move file from {} to {}",
                src.display(),
                dest.display()
            )
        })?;

        used_names.insert(dest);
    }

    // Delete empty directories if requested
    if delete_empty {
        delete_empty_directories(&root)?;
    }

    Ok(())
}

/// Recursively delete empty directories within the given root
fn delete_empty_directories(root: &Path) -> Result<()> {
    // Collect directories in reverse depth order (deepest first)
    let mut dirs: Vec<PathBuf> = WalkDir::new(root)
        .min_depth(1)
        .into_iter()
        .filter_map(|e| e.ok())
        .filter(|e| e.path().is_dir())
        .map(|e| e.path().to_path_buf())
        .collect();

    // Sort by path length descending to process deepest directories first
    dirs.sort_by_key(|b| std::cmp::Reverse(b.components().count()));

    for dir in dirs {
        // Check if directory is empty
        if fs::read_dir(&dir)?.next().is_none() {
            fs::remove_dir(&dir)
                .with_context(|| format!("Failed to remove empty directory: {}", dir.display()))?;
        }
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;

    fn create_test_structure(temp_dir: &TempDir) -> PathBuf {
        let root = temp_dir.path().to_path_buf();

        // Create nested structure
        let subdir1 = root.join("subdir1");
        let subsubdir = subdir1.join("subsubdir");
        let subdir2 = root.join("subdir2");

        fs::create_dir_all(&subsubdir).unwrap();
        fs::create_dir_all(&subdir2).unwrap();

        // Create files
        fs::write(root.join("root.txt"), "root file").unwrap();
        fs::write(subdir1.join("file1.txt"), "file in subdir1").unwrap();
        fs::write(subsubdir.join("deep.txt"), "file in subsubdir").unwrap();
        fs::write(subdir2.join("file2.txt"), "file in subdir2").unwrap();

        root
    }

    #[test]
    fn test_basic_flatten() {
        let temp_dir = TempDir::new().unwrap();
        let root = create_test_structure(&temp_dir);

        flatten_directory(&root, false, false).unwrap();

        // Check all files are at root
        assert!(root.join("root.txt").exists());
        assert!(root.join("file1.txt").exists());
        assert!(root.join("deep.txt").exists());
        assert!(root.join("file2.txt").exists());
    }

    #[test]
    fn test_flatten_with_rename() {
        let temp_dir = TempDir::new().unwrap();
        let root = temp_dir.path().to_path_buf();

        // Create structure with same-named files
        let photos = root.join("photos");
        let vacation = photos.join("vacation");
        let birthday = photos.join("birthday");

        fs::create_dir_all(&vacation).unwrap();
        fs::create_dir_all(&birthday).unwrap();

        fs::write(vacation.join("img1.jpg"), "vacation photo 1").unwrap();
        fs::write(birthday.join("img1.jpg"), "birthday photo").unwrap();

        flatten_directory(&root, true, false).unwrap();

        // Check files are renamed with parent folder prefix
        assert!(root.join("vacation_img1.jpg").exists());
        assert!(root.join("birthday_img1.jpg").exists());
    }

    #[test]
    fn test_flatten_with_delete() {
        let temp_dir = TempDir::new().unwrap();
        let root = create_test_structure(&temp_dir);

        flatten_directory(&root, false, true).unwrap();

        // Check all files are at root
        assert!(root.join("root.txt").exists());
        assert!(root.join("file1.txt").exists());
        assert!(root.join("deep.txt").exists());
        assert!(root.join("file2.txt").exists());

        // Check directories are deleted
        assert!(!root.join("subdir1").exists());
        assert!(!root.join("subdir2").exists());
    }

    #[test]
    fn test_flatten_with_rename_and_delete() {
        let temp_dir = TempDir::new().unwrap();
        let root = temp_dir.path().to_path_buf();

        // Create nested structure
        let a = root.join("a").join("b").join("c");
        let x = root.join("x").join("y");

        fs::create_dir_all(&a).unwrap();
        fs::create_dir_all(&x).unwrap();

        fs::write(a.join("file.txt"), "file c").unwrap();
        fs::write(x.join("file.txt"), "file y").unwrap();

        flatten_directory(&root, true, true).unwrap();

        // Check files are renamed
        assert!(root.join("c_file.txt").exists());
        assert!(root.join("y_file.txt").exists());

        // Check directories are deleted
        assert!(!root.join("a").exists());
        assert!(!root.join("x").exists());
    }

    #[test]
    fn test_flatten_handles_conflicts() {
        let temp_dir = TempDir::new().unwrap();
        let root = temp_dir.path().to_path_buf();

        let subdir = root.join("subdir");
        fs::create_dir_all(&subdir).unwrap();

        // Create conflicting file names
        fs::write(root.join("file.txt"), "root file").unwrap();
        fs::write(subdir.join("file.txt"), "subdir file").unwrap();

        flatten_directory(&root, false, false).unwrap();

        // Check both files exist (one with numeric suffix)
        assert!(root.join("file.txt").exists());
        assert!(root.join("file_1.txt").exists());
    }

    #[test]
    fn test_flatten_already_flat() {
        let temp_dir = TempDir::new().unwrap();
        let root = temp_dir.path().to_path_buf();

        fs::write(root.join("flat.txt"), "flat file").unwrap();

        flatten_directory(&root, false, false).unwrap();

        // File should still exist
        assert!(root.join("flat.txt").exists());
    }

    #[test]
    fn test_delete_empty_directories() {
        let temp_dir = TempDir::new().unwrap();
        let root = temp_dir.path().to_path_buf();

        // Create nested empty directories
        let empty1 = root.join("empty1");
        let empty2 = empty1.join("empty2");
        fs::create_dir_all(&empty2).unwrap();

        delete_empty_directories(&root).unwrap();

        // Check directories are deleted
        assert!(!empty1.exists());
        assert!(!empty2.exists());
    }

    #[test]
    fn test_delete_preserves_non_empty() {
        let temp_dir = TempDir::new().unwrap();
        let root = temp_dir.path().to_path_buf();

        // Create directory with file
        let non_empty = root.join("non_empty");
        fs::create_dir_all(&non_empty).unwrap();
        fs::write(non_empty.join("file.txt"), "content").unwrap();

        // Create empty directory
        let empty = root.join("empty");
        fs::create_dir_all(&empty).unwrap();

        delete_empty_directories(&root).unwrap();

        // Non-empty should be preserved, empty should be deleted
        assert!(non_empty.exists());
        assert!(!empty.exists());
    }
}
