# Progression Note — Configuration, Security, and Navigation Improvements

This update focused on improving the maintainability, safety, and usability of the Flutter Cross project.

## What was improved

### 1. Centralized runtime configuration
Client-side runtime configuration was moved into a dedicated central config layer (`AppConfig`) using compile-time variables with `--dart-define`.

This removed the need to keep important client configuration values hardcoded across multiple files.

### 2. Reduced hardcoded client config values
The following client-side values were centralized:
- API base URL
- mock track management flags
- reCAPTCHA Android site key
- Windows reCAPTCHA web URL

This makes environment switching easier and reduces accidental exposure of local configuration inside source files.

### 3. Safer project setup for contributors
The project now includes:
- `.env.example` as documentation for required client config values
- VS Code launch configurations for common development targets
- updated `README.md` instructions for PowerShell and local development

This improves onboarding and reduces setup mistakes for team members.

### 4. Standardized API path usage
Hardcoded `/api/v1/...` paths were replaced with centralized constants in the networking layer.

This improves consistency and makes future backend path updates easier to manage.

### 5. Fixed unresolved navigation targets
Temporary placeholder routes were added for:
- `/feed`
- `/search`
- `/upgrade`

This prevents broken navigation and avoids sending users to the 404 fallback page when those tabs are tapped.

## Security note
This work improves repository hygiene and client configuration management, but it does not replace backend security.

Real secrets such as:
- database credentials
- JWT secrets
- mail passwords
- backend private keys

must remain only on the backend and must never be shipped in the Flutter client.

## Outcome
The project is now cleaner to configure, easier to run locally, safer to share in source control, and more stable during navigation in the current `dev` workflow.