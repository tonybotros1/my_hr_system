# DataHub AI HR System

DataHub AI HR System is a standalone Flutter web client for employee administration, payroll setup, payroll processing, leave configuration, and company-level HR user access.

The application uses the existing DataHub AI FastAPI backend and MongoDB database, while remaining independent from the legacy Flutter client. Company profiles and shared master data can continue to be managed by the main system; this project provides the focused HR workspace.

> [!IMPORTANT]
> **Proprietary source code — All Rights Reserved.** No permission is granted to download, copy, use, modify, host, redistribute, or sell this repository or its source code. Access to the repository does not grant a license. See [LICENSE](LICENSE).

## Contents

- [Core features](#core-features)
- [Access and permission model](#access-and-permission-model)
- [Technology stack](#technology-stack)
- [Project structure](#project-structure)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Local setup](#local-setup)
- [Configuration](#configuration)
- [Backend contract](#backend-contract)
- [Testing and quality checks](#testing-and-quality-checks)
- [Production web deployment](#production-web-deployment)
- [Adding another HR screen](#adding-another-hr-screen)
- [Troubleshooting](#troubleshooting)
- [Security and production notes](#security-and-production-notes)
- [Project boundaries](#project-boundaries)
- [License](#license)

## Core features

### Authentication and session handling

- Email and password authentication through the FastAPI backend.
- Access and refresh token session flow.
- Automatic access-token refresh after an authorized request returns `401`.
- Session validation during the loading screen.
- Company status, user status, and user expiry-date enforcement by the backend.
- Secure local refresh-token storage through `flutter_secure_storage`.
- Local logout even when the backend is temporarily unavailable.
- Login is restricted to users who have the HR responsibility.

### Responsive workspace

- Company name and logo in the sidebar.
- Direct HR screen links without the old nested HR menu tree.
- Resizable desktop sidebar and collapsible compact sidebar.
- Circular Settings and Logout actions at the bottom of the sidebar.
- Five responsive color palettes with live preview and device-level persistence.
- Responsive tables whose visible row count follows the available screen height.
- Horizontally scrollable tables at narrow browser widths.
- Browser-friendly routes for each screen.
- Browser Back closes supported dialogs and full-screen editors before leaving the current screen.
- Shared centered alerts, confirmation dialogs, form fields, dropdowns, and date controls.

### HR modules

| Screen | Main capability | Browser path |
| --- | --- | --- |
| Dashboard | Permission-aware workforce summaries, hiring trends, recent starters, payroll activity, and a public-holiday calendar | `/#/mainScreen` |
| Legislation | Create and maintain legislation rules and values | `/#/mainScreen/legislation` |
| Payroll Elements | Maintain payroll elements and based-element relationships | `/#/mainScreen/payroll-elements` |
| Employees | Employee profiles, assignments, balances, related data, leaves, contacts, and documents | `/#/mainScreen/employees` |
| Public Holidays | Maintain legislation-based public holiday dates | `/#/mainScreen/public-holidays` |
| Leave Types | Maintain leave types and linked payroll elements | `/#/mainScreen/leave-types` |
| Payroll | Maintain payroll definitions and payroll periods | `/#/mainScreen/payroll` |
| Payroll Runs | Create runs, inspect results, generate documents, email payslips, export, and roll back | `/#/mainScreen/payroll-runs` |
| Balances | Maintain balance definitions and based-element calculations | `/#/mainScreen/balances` |
| Loan and Advances Types | Maintain loan/advance types and their payroll-element links | `/#/mainScreen/loan-and-advances-types` |
| Users | Create HR users, manage status, admin access, expiry, password, and screen permissions | `/#/mainScreen/users` |

The Users screen is shown under **Admin's Screens** and is available only when the signed-in user is an administrator.

Settings is available to every authenticated HR user at `/#/mainScreen/settings`. A selected color palette is applied immediately across the workspace and restored on the next visit from that browser/device.

### Dashboard

The opening screen is a responsive dashboard with a company welcome area, live summary cards, a six-month hiring chart, active employees by department, recent starters, recent payroll runs, a navigable holiday calendar, and shortcuts to authorized screens. Its colors follow the selected workspace theme.

It uses the existing company-scoped endpoints, without backend changes:

- `GET /employees/get_all_employees` for employee summaries.
- `GET /payroll_runs/get_all_payroll_runs` for payroll-run summaries.
- `POST /public_holidays/get_all_holidays` with an empty filter object for holidays.

Requests are sent only for screens the signed-in user can access. The dashboard does not fetch individual employee profiles or invent salary totals. Active headcount requires a hire date on or before today and an end date that is empty or on/after today; applicants without hire dates and future starters are excluded. Monthly hires count actual start dates, and holidays cover the company's legislations. A failed section shows unavailable information rather than a false zero; Refresh retries all authorized sections.

The implementation is separated into `screens/dashboard`, `controllers/dashboard_controllers`, `models/dashboard`, and `widgets/dashboard`. Regression tests use isolated fake responses. For a clearly labelled local sample-data preview, run `flutter run -d chrome -t test/support/dashboard_preview.dart`. Always build releases from `lib/main.dart`, never from the preview entry point.

### Employee workspace

The employee editor is a full-screen workspace containing:

- Personal information and employee photo selection/preview.
- Address, nationality, phone, social-contact, bank-account, and health-card records.
- Employment details, reporting manager, payroll assignment, and contract dates.
- Contract duration in years, months, and days.
- Period-filtered payroll elements and assignment balances.
- Employee loan and advance records.
- Leave records.
- Contacts and relatives.
- Document-of-record attachments with previews and file-type icons.
- Image thumbnails for image attachments.
- A frontend attachment limit of 50 MB per file.
- Reusable list-of-values maintenance for supported lookup fields.

## Access and permission model

Access is resolved after authentication from two backend responses:

1. `GET /menus/get_user_menu_tree` supplies the responsibilities and HR menu tree.
2. `GET /companies/get_current_company_details` supplies the current user's admin flag and `hr_screen_access` list.

The resulting rules are:

- A user must have the HR responsibility to enter this application.
- Normal HR screens are flattened and displayed directly in the sidebar.
- `hr_screen_access` determines which of those screens the user can open.
- Directly typing a disallowed Flutter route shows an access-denied view.
- An administrator with the HR responsibility also receives **Admin's Screens → Users**.
- The Users editor lets an administrator select all HR screens, clear all screens, or select screens individually.
- A newly created user is assigned the HR responsibility and the selected HR screen list.
- Existing users whose `hr_screen_access` is missing or `null` retain access to all implemented HR screens for backward compatibility.
- An explicitly empty `hr_screen_access` list means the user has no normal HR screens.

Canonical `hr_screen_access` values are:

```text
/legislation
/defination
/employees
/publicholidays
/leavetypes
/payroll
/payrollruns
/balances
/loanandadvancestypes
```

`/defination` is intentionally retained as the internal Payroll Elements route for compatibility with existing backend menu data.

> Sidebar filtering and Flutter route guards improve the user experience, but they are not a substitute for authorization on backend endpoints. The backend must remain the security authority for company and user access.

## Technology stack

| Area | Technology |
| --- | --- |
| UI | Flutter Material |
| State management and routing | GetX |
| Networking | `http` |
| Session persistence | `shared_preferences` and `flutter_secure_storage` |
| File selection | `file_picker` |
| Payroll documents | `pdf` and `printing` |
| Web integrations | Dart `web` package and conditional imports |
| Typography | Bundled Cairo and Noto font assets, with Google Fonts support |
| Backend | FastAPI / Python 3.12 |
| Database | MongoDB |

The Dart SDK constraint is declared in `pubspec.yaml` as `^3.12.2`. Use a stable Flutter SDK that provides a compatible Dart version.

## Project structure

```text
my_hr_system/
├── assets/
│   └── fonts/                         # Bundled Cairo and Noto fonts
├── lib/
│   ├── config/
│   │   ├── app_config.dart            # Backend URL and request timeout
│   │   └── app_theme.dart             # Compatibility export for theme tokens
│   ├── controllers/
│   │   ├── auth_controllers/          # Login and loading/session controllers
│   │   ├── employee_controllers/      # Employee workspace state and API calls
│   │   ├── main_controllers/          # Shell, sidebar, routing, and logout
│   │   ├── payroll_controllers/       # Payroll-related module controllers
│   │   └── user_controllers/          # Admin user management
│   ├── models/                        # Typed API/domain models and color palettes
│   ├── routes/
│   │   └── app_routes.dart            # GetX paths and backend-menu normalization
│   ├── screens/                       # Top-level feature and settings screens
│   ├── services/                      # API, session, theme, permissions, browser, documents
│   ├── widgets/
│   │   ├── dialogs/                   # Shared alert/confirmation dialogs
│   │   ├── employees/                 # Employee workspace components
│   │   ├── form_fields/               # Shared text, date, and dropdown fields
│   │   ├── main_shell/                # Sidebar and company branding
│   │   └── ...                        # Feature-specific tables and editors
│   ├── consts.dart                    # Theme, spacing, sizes, limits, decorations
│   └── main.dart                      # Application entry point and GetX bindings
├── test/                              # Widget, model, service, and regression tests
├── web/                               # Web manifest, icons, and index page
├── LICENSE                            # Proprietary All Rights Reserved terms
├── pubspec.yaml
└── README.md
```

## Architecture

### GetX organization

Each feature follows the project's screen/controller/model/widget structure:

- **Screens** compose a page and connect it to a controller.
- **Controllers** own reactive state, validation, pagination, and backend operations.
- **Models** parse backend responses and build request payloads.
- **Widgets** contain reusable forms, dialogs, tables, and shell components.
- **Services** handle cross-feature concerns such as authentication, authorized HTTP requests, HR access, browser history, and document generation.

Long-lived services are registered once in `main.dart`. Screen controllers are lazily registered through the main GetX binding, with `fenix: true` for feature controllers that may need to be recreated after route disposal.

### API flow

Authenticated feature requests go through `AuthenticatedApiService`:

1. Read the current access token.
2. Send an authorized JSON or multipart request.
3. If the response is `401`, perform one shared refresh-token request.
4. Retry the original request once with the new access token.
5. Clear the local session if refresh fails or the retry is unauthorized.
6. Convert backend errors into consistent exceptions for the UI.

Login and refresh endpoints use form-encoded requests because that is the backend contract. Feature CRUD requests use JSON unless a file upload requires multipart form data.

### Theme and shared components

Project-wide theme values live in `lib/consts.dart`:

- `AppColors`
- `AppFonts`
- `AppSpacing`
- `AppRadii`
- `AppSizes`
- `AppLimits`
- `AppDurations`
- `AppGradients`
- Shared text styles, decorations, and button styles

The Settings screen presents the palettes declared in `lib/models/settings/app_color_palette.dart`. `ThemeController` applies the selected semantic colors and stores the palette ID in `SharedPreferences`, so feature screens continue to consume the same shared `AppColors` tokens without maintaining their own theme state.

Use the shared form controls for consistent sizing and behavior:

- `AppTextFormField`
- `AppDateFormField`
- `AppDropdownFormField`
- `CustomDropdown`
- `showAppAlertDialog`
- `showAppConfirmationDialog`

All ordinary single-line text and dropdown fields use the shared 35 px minimum-height system. Validation messages are allowed to add vertical space so the input itself does not shrink.

### Browser navigation

The web build uses GetX named routes and hash-style URLs. Dialogs that participate in browser history use conditional web services so that pressing Browser Back closes the active dialog/editor instead of unexpectedly leaving the application.

Stub implementations keep non-web test builds compilable without importing browser-only libraries.

## Prerequisites

Install the following:

- Flutter stable with a Dart version compatible with `^3.12.2`.
- Chrome for local web development.
- The DataHub AI FastAPI backend.
- Python 3.12 for the backend.
- Access to the configured MongoDB database.
- Cloudinary credentials when employee image/document upload is required.
- Google OAuth/mail configuration when payroll payslips will be emailed.

Check the Flutter installation:

```bash
flutter doctor
flutter devices
```

## Local setup

### 1. Start the backend

From the backend repository:

```bash
python3.12 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
```

Create a backend `.env` file using the deployment's real values. Never commit it:

```dotenv
MONGO_URI=mongodb+srv://USER:PASSWORD@HOST/
DATABASE_NAME=your_database_name
ACCESS_SECRET_KEY=replace_with_a_long_random_secret
REFRESH_SECRET_KEY=replace_with_a_different_long_random_secret
ACCESS_TTL_MIN=60
REFRESH_TTL_DAYS=60

# Required for image and attachment uploads
CLOUD_NAME=your_cloudinary_cloud
CLOUDINARY_API_KEY=your_cloudinary_key
CLOUDINARY_API_SECRET=your_cloudinary_secret

# Required only for Google-based payslip email
GOOGLE_OAUTH_CLIENT_ID=your_client_id
GOOGLE_OAUTH_CLIENT_SECRET=your_client_secret
GOOGLE_OAUTH_REDIRECT_URI=https://your-api.example.com/your-callback
MAIL_TOKEN_ENCRYPTION_KEY=replace_with_a_secure_encryption_key
```

Run the API:

```bash
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

The backend repository also provides `./start.sh` for a non-reload launch using its `.venv`.

Verify the API is reachable:

```bash
curl http://127.0.0.1:8000/
```

Expected response:

```json
{"message":"DataHubAI"}
```

### 2. Install Flutter dependencies

From this repository:

```bash
flutter pub get
```

### 3. Run the web application

When the backend is on the same computer:

```bash
flutter run -d chrome \
  --dart-define=BACKEND_URL=http://127.0.0.1:8000
```

When accessing a backend running on another LAN device, use that device's reachable IP address:

```bash
flutter run -d chrome \
  --dart-define=BACKEND_URL=http://192.168.x.x:8000
```

The source fallback is currently `http://192.168.1.23:8000`, but passing `BACKEND_URL` explicitly is recommended so builds do not depend on one developer machine's address.

## Configuration

### Frontend compile-time variables

| Variable | Required | Description |
| --- | --- | --- |
| `BACKEND_URL` | Recommended | Base URL of the FastAPI backend, without a trailing API path |

`BACKEND_URL` is read with `String.fromEnvironment`, so it must be supplied at Flutter run/build time. Changing a shell environment variable alone does not change an already compiled web build.

Examples:

```bash
# Development
flutter run -d chrome \
  --dart-define=BACKEND_URL=http://127.0.0.1:8000

# Production
flutter build web --release \
  --dart-define=BACKEND_URL=https://api.example.com
```

### Date format

The UI displays and edits ordinary dates as:

```text
YYYY-MM-DD
```

Shared date fields support date-picker selection, keyboard editing, Delete/Backspace clearing, and a clear action where applicable. Controllers convert dates to the backend's ISO-compatible values.

### File limits

Employee document selection rejects files larger than 50 MB in the Flutter client. Production infrastructure should enforce a matching or stricter limit at the reverse proxy and backend layers.

## Backend contract

This project depends on the existing FastAPI service. Major route groups used by the Flutter client are:

| Prefix | Purpose |
| --- | --- |
| `/auth` | Login, logout, session validation, and token refresh |
| `/companies` | Company identity and current-user access metadata |
| `/menus` | Responsibility/menu tree used to confirm HR access |
| `/responsibilities` | HR role lookup for new users |
| `/users` | HR user administration and screen permissions |
| `/employees` | Employee profile, assignment, related records, and filtering |
| `/attachment` | Employee document-of-record uploads and deletion |
| `/list_of_values` | Shared employee dropdown data and lookup maintenance |
| `/legislation` | Legislation setup |
| `/payroll_elements` | Payroll elements and based elements |
| `/public_holidays` | Public holiday setup |
| `/leave_types` | Leave type setup |
| `/payroll` | Payroll and period setup |
| `/payroll_runs` | Payroll processing, details, export, rollback, and payslip email |
| `/balance` | Balance setup and based elements |
| `/loan_and_advances_types` | Loan and advance type setup |

### User screen-permission field

The backend user document supports:

```json
{
  "hr_screen_access": [
    "/employees",
    "/payroll",
    "/payrollruns"
  ]
}
```

The backend normalizes known routes and removes unknown or duplicate values before saving. The current-company details response must return this field for the signed-in user.

### Multi-company data

All HR data must remain scoped by the authenticated user's `company_id`. Never accept a client-supplied company identifier as the sole authorization check. New backend endpoints should derive company scope from the validated access token, following the existing protected routes.

## Testing and quality checks

Run formatting, static analysis, tests, and a production web build before release:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter test --platform chrome test/dashboard_test.dart
flutter build web --release \
  --dart-define=BACKEND_URL=https://api.example.com
```

The test suite currently covers areas including:

- Authentication and API response parsing.
- Shared 35 px form-field sizing.
- Reusable date-field behavior.
- Responsive main-shell layout.
- Persisted theme selection and Settings route mapping.
- HR responsibility and per-screen navigation filtering.
- User-model screen permissions.
- Browser/dialog stack regressions in the employee workspace.
- Payroll and employee model/controller behavior.
- Dashboard date boundaries, endpoint permissions, failure recovery, browser-style Back, live refresh, theme changes, and layouts from 320 to 1440 logical pixels (Chrome tests).

When changing dialogs or GetX routes, test repeated open/close cycles and Browser Back. This prevents duplicate `GlobalKey<FormState>` and over-popping regressions.

## Production web deployment

### Firebase release configuration

The new HR frontend is configured for the dedicated Firebase Hosting site `datahubai-hr` in project `compass-automatic-gear`. Its default address is `https://datahubai-hr.web.app`; a custom domain can be attached to this site later.

The explicit `site` in `firebase.json` targets only the HR website. Deploy from this project directory using:

```bash
flutter build web --release --no-source-maps \
  --dart-define=BACKEND_URL=https://datahubai-backend.onrender.com
firebase deploy --only hosting --project compass-automatic-gear
```

Always include the production `BACKEND_URL` when building for deployment: the default in `AppConfig` is a local development address. Only the generated `build/web/` assets are published, and source maps are excluded. Hosting requires cache revalidation so browsers can pick up changed bundles on a subsequent visit.

### Build

Always use an HTTPS backend for a production HTTPS website:

```bash
flutter clean
flutter pub get
flutter build web --release \
  --dart-define=BACKEND_URL=https://api.example.com
```

Deploy the generated `build/web/` directory to a static web host such as Firebase Hosting, Cloudflare Pages, Netlify, or an object-storage/CDN setup.

### Hosting requirements

- Serve the site over HTTPS.
- Serve `index.html` as the entry point.
- Preserve all files generated under `build/web/`.
- Do not cache `index.html` indefinitely; use short or revalidated caching so releases become visible promptly.
- Cache hashed Flutter assets for a long duration.
- Permit the deployed origin in the backend CORS configuration.
- Ensure the browser can reach the backend URL directly.
- Increase proxy/body limits if uploads up to 50 MB are supported.
- Keep the backend and MongoDB close to the majority of users to reduce request latency.

The app currently uses hash-style navigation, so direct links contain `/#/`. A general fallback to `index.html` is still safe and recommended for static hosting configuration.

### Release checklist

- [ ] Production `BACKEND_URL` was supplied during the build.
- [ ] Frontend and backend both use HTTPS.
- [ ] Backend secrets are not included in Flutter assets or source.
- [ ] Backend CORS is restricted to trusted production origins.
- [ ] MongoDB indexes initialize successfully.
- [ ] Cloudinary upload credentials work, if attachments are enabled.
- [ ] Payslip email credentials and redirect URL work, if email is enabled.
- [ ] Admin, non-admin, limited-screen, inactive, and expired accounts were tested.
- [ ] Browser refresh and Browser Back were tested on dialogs and employee editing.
- [ ] `flutter analyze`, `flutter test`, and the release build pass.

## Adding another HR screen

Follow this sequence to preserve the current architecture:

1. Add the typed model under `lib/models/`.
2. Add a GetX controller under the relevant `lib/controllers/` folder.
3. Build the top-level page under `lib/screens/`.
4. Put reusable controls, tables, and editors under `lib/widgets/`.
5. Register the controller in `_mainBinding()` in `lib/main.dart`.
6. Add the route/slug mapping in `lib/routes/app_routes.dart`.
7. Add the route to `HrAccessPolicy.supportedScreens` in `lib/services/hr_access_service.dart`.
8. Add the corresponding screen switch case in `MainScreenController`.
9. Add the same canonical route to the backend `HR_SCREEN_ROUTES` allowlist.
10. Confirm the backend HR menu tree contains the route.
11. Add permission, direct-route, responsive-layout, and CRUD tests.

Use existing shared theme tokens and form components instead of creating screen-specific copies.

## Troubleshooting

### The login page says “Invalid email or password”

- Confirm the email is exactly the saved lowercase address.
- Passwords are case-sensitive and are sent exactly as typed; leading or trailing spaces are significant.
- Use the admin Users screen to set a new password when the original entry is uncertain.
- Confirm the frontend is pointing to the same backend/database where the user was created.

### Login succeeds but HR access is rejected

- Confirm the user has the HR responsibility in the backend.
- Confirm the company and user are active.
- Confirm the user expiry date is later than today.
- Confirm the HR menu tree is returned by `/menus/get_user_menu_tree`.

### A screen is missing from the sidebar

- Check the user's `hr_screen_access` selection in the Users screen.
- Check that the backend menu route matches one of the canonical routes.
- Sign out and sign in again after changing access so the workspace reloads permissions.
- Remember that Users is visible only to an administrator.

### The app cannot reach the server

- Rebuild or rerun with the correct `--dart-define=BACKEND_URL=...` value.
- Confirm the API responds from the same browser/device.
- When using a phone or another computer, do not use `127.0.0.1`; use the backend computer's LAN address.
- Check firewall, reverse-proxy, DNS, TLS certificate, and CORS settings.
- An HTTPS page cannot normally call an insecure HTTP API because browsers block mixed content.

### Dropdowns or tables are empty

- Inspect the relevant API response and authentication status.
- Confirm lookup records belong to the signed-in company.
- Close and reopen the editor after changing a lookup value if the current controller has not refreshed yet.
- Check the browser developer console and backend logs for response-schema errors.

### Attachments do not upload or open

- Confirm each file is 50 MB or smaller.
- Confirm Cloudinary credentials are configured on the backend.
- Confirm the reverse proxy permits the multipart request size.
- Confirm popups/new tabs are allowed when opening a document.

### Payslip email fails

- Confirm the employee has a usable email address.
- Confirm the company mail integration is configured and authorized.
- Check Google OAuth credentials, redirect URI, encrypted refresh token, and backend logs.

### Missing-character font warnings

Run `flutter pub get` and confirm the font files under `assets/fonts/` are present and declared in `pubspec.yaml`. The app bundles Cairo, Noto Sans, and Noto Sans Symbols 2 as fallbacks.

## Security and production notes

- Keep this repository private and grant access only to trusted people who need it.
- Do not send customers a source-code archive unless a signed agreement explicitly authorizes it.
- Remove repository access immediately when a developer, employee, or contractor no longer needs it.
- Never place MongoDB, Cloudinary, OAuth, or token-signing secrets in Flutter code or `--dart-define` values.
- Treat everything compiled into `build/web/` as public.
- Use separate, strong access-token and refresh-token secrets.
- Use HTTPS for both frontend and backend.
- Restrict production CORS origins instead of leaving wildcard access enabled.
- Validate company ownership and permissions on every backend mutation.
- Enforce admin authorization on user-management endpoints, not only in the Flutter sidebar.
- Validate upload size and file type on the backend even though the Flutter client validates them.
- Keep dependencies patched and review `flutter pub outdated` and Python package updates regularly.
- Back up MongoDB and test restore procedures before production use.
- Avoid logging passwords, access tokens, refresh tokens, or attachment contents.

## Project boundaries

- This repository is the new HR frontend.
- It does not import source files or assets from the legacy Flutter application.
- It intentionally shares the FastAPI backend and MongoDB data model with the main system.
- Backend API contract changes must remain compatible with both authorized clients until the legacy client is retired.
- Company creation and global platform administration may remain in the main system, while company HR administrators manage HR users and per-screen access here.

## License

Copyright © 2026 DataHub AI. All Rights Reserved.

This project is proprietary software and is **not open source**. The [proprietary license](LICENSE) grants no public permission to download, copy, use, modify, host, distribute, sublicense, sell, or create derivative works from the repository or its source code.

Viewing the repository, receiving an accidental copy, or accessing a deployed version of the application does not transfer ownership or grant permission to reuse the code. Authorized customers may use only the hosted application or deliverables covered by their separate written agreement.

Third-party packages, fonts, and other dependencies remain governed by their own licenses. The DataHub AI proprietary license applies only to material owned by DataHub AI.
