# Rust Style Guide

## Formatting

### Use rustfmt
- Always use `cargo fmt` to format code before committing
- Configure rustfmt in `rustfmt.toml` if project-specific rules are needed
- Use 4 spaces for indentation (rustfmt default)

### Line Length
- Prefer 100 characters per line (rustfmt default)
- Break long lines at logical boundaries
- Align function parameters and arguments when wrapping

### Function Definitions

```rust
// Good: Clear parameter formatting
fn process_user_data(
    user_id: u64,
    name: &str,
    email: Option<&str>,
) -> Result<UserProfile, ProcessingError> {
    // implementation
}

// Good: Short functions on one line
fn is_valid(input: &str) -> bool {
    !input.is_empty() && input.len() <= 50
}
```

## Naming and Structure

### Error Handling
```rust
// Good: Use Result for recoverable errors
fn parse_config(path: &Path) -> Result<Config, ConfigError> {
    let content = fs::read_to_string(path)?;
    toml::from_str(&content).map_err(ConfigError::ParseError)
}

// Good: Use descriptive error types
#[derive(Debug, thiserror::Error)]
pub enum ConfigError {
    #[error("Failed to read config file: {0}")]
    IoError(#[from] std::io::Error),
    #[error("Failed to parse config: {0}")]
    ParseError(#[from] toml::de::Error),
}
```

### Structs and Enums
```rust
// Good: Derive common traits
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct UserProfile {
    pub id: u64,
    pub name: String,
    pub email: Option<String>,
    pub created_at: DateTime<Utc>,
}

// Good: Use descriptive enum variants
#[derive(Debug, Clone, Copy)]
pub enum UserRole {
    Admin,
    Member,
    Guest,
}

// Good: Enums with data
#[derive(Debug)]
pub enum DatabaseConnection {
    Postgres { url: String, pool_size: u32 },
    Sqlite { path: PathBuf },
    InMemory,
}
```

### Traits
```rust
// Good: Small, focused traits
pub trait Serializable {
    type Error;
    
    fn serialize(&self) -> Result<Vec<u8>, Self::Error>;
    fn deserialize(data: &[u8]) -> Result<Self, Self::Error>
    where
        Self: Sized;
}

// Good: Use associated types when appropriate
pub trait Repository<T> {
    type Error;
    
    async fn find_by_id(&self, id: u64) -> Result<Option<T>, Self::Error>;
    async fn save(&self, entity: &T) -> Result<(), Self::Error>;
}
```

## Documentation

### Doc Comments
```rust
/// Calculates the monthly payment for a loan.
/// 
/// # Arguments
/// 
/// * `principal` - The loan amount in currency units
/// * `rate` - Annual interest rate (e.g., 0.05 for 5%)
/// * `years` - Loan term in years
/// 
/// # Returns
/// 
/// Monthly payment amount, or `None` if inputs are invalid
/// 
/// # Examples
/// 
/// ```
/// let payment = calculate_monthly_payment(100000.0, 0.05, 30);
/// assert!(payment.is_some());
/// ```
pub fn calculate_monthly_payment(
    principal: f64, 
    rate: f64, 
    years: u32
) -> Option<f64> {
    // implementation
}
```

### Module Documentation
```rust
//! User management module.
//! 
//! This module provides functionality for creating, updating, and 
//! managing user accounts in the system.
//! 
//! # Examples
//! 
//! ```
//! use crate::users::{User, UserManager};
//! 
//! let manager = UserManager::new();
//! let user = manager.create_user("alice", "alice@example.com")?;
//! ```

use std::collections::HashMap;
```

## Testing

### Unit Tests
```rust
#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_user_creation() {
        let user = User::new("alice", "alice@example.com");
        assert_eq!(user.name(), "alice");
        assert_eq!(user.email(), "alice@example.com");
    }
    
    #[test]
    fn test_invalid_email() {
        let result = User::new("bob", "invalid-email");
        assert!(result.is_err());
    }
}
```

### Integration Tests
```rust
// tests/integration_test.rs
use myapp::{Database, User};
use tempfile::TempDir;

#[tokio::test]
async fn test_user_persistence() {
    let temp_dir = TempDir::new().unwrap();
    let db_path = temp_dir.path().join("test.db");
    let db = Database::new(&db_path).await.unwrap();
    
    let user = User::new("alice", "alice@example.com").unwrap();
    db.save_user(&user).await.unwrap();
    
    let loaded_user = db.load_user(user.id()).await.unwrap();
    assert_eq!(user, loaded_user);
}
```

## Performance and Safety

### Memory Management
```rust
// Good: Use &str for string parameters when possible
fn process_name(name: &str) -> String {
    name.trim().to_lowercase()
}

// Good: Use Cow for conditional cloning
use std::borrow::Cow;

fn normalize_path(path: &str) -> Cow<str> {
    if path.starts_with("./") {
        Cow::Owned(path[2..].to_string())
    } else {
        Cow::Borrowed(path)
    }
}
```

### Async/Await
```rust
// Good: Use async/await for I/O operations
pub async fn fetch_user_data(user_id: u64) -> Result<UserData, ApiError> {
    let response = reqwest::get(&format!("/api/users/{}", user_id))
        .await?
        .error_for_status()?;
    
    let user_data = response.json().await?;
    Ok(user_data)
}

// Good: Use join! for concurrent operations
use tokio::join;

pub async fn load_user_profile(user_id: u64) -> Result<UserProfile, LoadError> {
    let (user_data, preferences, activity) = join!(
        fetch_user_data(user_id),
        fetch_user_preferences(user_id),
        fetch_recent_activity(user_id)
    );
    
    Ok(UserProfile {
        data: user_data?,
        preferences: preferences?,
        recent_activity: activity?,
    })
}
```