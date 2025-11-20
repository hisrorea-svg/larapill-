# Copilot Instructions for Flutter Project

## General Guidelines
- Follow Effective Dart style guide
- Use `dart format` for all code
- Prefer lines 80 characters or fewer
- Use curly braces for all flow control statements

## Imports & Organization
- Place `dart:` imports before other imports
- Place `package:` imports before relative imports
- Sort sections alphabetically
- Specify exports in separate section after imports

## Types & Null Safety
- DO annotate return types on function declarations
- DO annotate parameter types on function declarations
- DON'T explicitly initialize variables to null
- PREFER using final field for read-only properties
- AVOID late variables if checking initialization is needed

## State Management (Riverpod)
- Providers should be top-level final variables only
- Use ref.watch/read/listen with statically known providers
- AVOID using providers for ephemeral state (animations, form state)
- AVOID dynamically creating providers

## Flutter Best Practices
- Use const constructors whenever possible
- Prefer composition over inheritance for widgets
- Keep widget build methods small and focused
