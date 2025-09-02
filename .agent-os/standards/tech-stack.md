# Tech Stack

## Context

Global tech stack defaults for Agent OS projects, overridable in project-specific `.agent-os/product/tech-stack.md`.

## Backend/CLI Applications (Rust)

- Language: Rust latest stable (1.80+)
- Edition: Rust 2021
- Package Manager: Cargo
- Build Tool: Cargo
- Async Runtime: Tokio latest
- HTTP Client: Reqwest
- JSON Serialization: Serde
- CLI Framework: Clap 4.0+
- Configuration: Config crate with TOML/YAML
- Logging: Tracing + Tracing-subscriber
- Error Handling: Anyhow/Thiserror
- Database ORM: SQLx with compile-time verification
- Primary Database: PostgreSQL 17+ or SQLite 3.45+
- Testing Framework: Built-in Rust test + Criterion for benchmarks

## Mobile/Desktop Applications (Flutter)

- Framework: Flutter latest stable (3.24+)
- Language: Dart latest stable (3.5+)
- Package Manager: Pub
- State Management: BLoC + Cubit patterns
- Navigation: Go Router
- HTTP Client: Dio
- Data Classes: Freezed 3.0+
- JSON Serialization: Json Annotation + Json Serializable
- Local Database: Drift (SQLite)
- Dependency Injection: Get It
- Internationalization: Flutter Intl
- Platform Integration: Flutter Platform Channels
- Testing: Flutter Test + Integration Test
- Build Tool: Flutter Build Runner

## Deployment & Infrastructure

- Container Platform: Docker with multi-stage builds
- Orchestration: Docker Compose for development
- Application Hosting: Digital Ocean App Platform/Droplets
- Database Hosting: Digital Ocean Managed PostgreSQL
- Database Backups: Daily automated
- Asset Storage: Amazon S3
- CDN: CloudFront
- CI/CD Platform: GitHub Actions
- CI/CD Trigger: Push to main/staging branches
- Tests: Run before deployment
- Production Environment: main branch
- Staging Environment: staging branch
