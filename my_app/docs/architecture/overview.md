# Architecture Overview

## Clean Architecture Layers

- **Presentation**: UI, BLoC, Widgets
- **Domain**: Entities, Use Cases, Repository Interfaces
- **Data**: Repositories Implementation, DTOs, Data Sources

## Package Structure

lib/
├── app/          # App-wide configuration
├── core/         # Shared utilities
└── features/     # Feature modules
    ├── auth/
    ├── profile/
    └── ...