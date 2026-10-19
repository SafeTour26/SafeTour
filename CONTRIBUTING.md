# Contributing to SafeTour

Welcome to the SafeTour project. Whether you are a core team member or an open-source contributor, we are glad to have your support.

> [!IMPORTANT]
> **Project Status: Active Development / MVP**  
> SafeTour is currently in active prototyping and development. The app architecture, features, and UI are evolving rapidly. We encourage open discussion, experiments, and creative ideas.

---

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Local Development Setup](#local-development-setup)
3. [Environment Configuration (.env)](#environment-configuration-env)
4. [Running the Application](#running-the-application)
5. [Codebase Architecture](#codebase-architecture)
6. [Development Workflow](#development-workflow)
7. [Submitting a Pull Request](#submitting-a-pull-request)
8. [Roadmap and Where We Need Help](#roadmap-and-where-we-need-help)

---

## Prerequisites

Before starting, ensure the following are installed on your machine:
- **Flutter SDK** (`>= 3.0.0 < 4.0.0`): [Flutter Install Guide](https://docs.flutter.dev/get-started/install)
- **Dart SDK** (bundled with Flutter)
- **Git**
- **Android Studio** or **VS Code** with the Flutter and Dart extensions
- **Python 3.8+** (Optional: only needed if executing the Supabase database seeder `seed_safety_zones.py`)

---

## Local Development Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/SafeTour26/SafeTour.git
   cd SafeTour
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Verify your setup:**
   ```bash
   flutter doctor
   ```

---

## Environment Configuration (.env)

SafeTour connects to a Supabase backend for user authentication, live safety zones, and emergency SOS tracking. However, it also features an **offline-first engine** with 100 pre-bundled Bengaluru localities.

1. Create your local `.env` file from the template:
   ```bash
   cp .env.example .env
   ```
2. Request the active project keys from the team lead, or insert your own Supabase project credentials into `.env`:
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   SUPABASE_SERVICE_ROLE_KEY=your-service-role-key # optional: seed script only
   ```
   > [!NOTE]
   > Security Note: The `.env` file is git-ignored. Never commit API keys or secret tokens to version control.

---

## Running the Application

### Option A: Using VS Code (Recommended)
Open the project in VS Code, navigate to the **Run and Debug** panel (`Ctrl+Shift+D` / `Cmd+Shift+D`), and select:
- **SafeTour (with .env)**: Runs the app with live Supabase credentials injected.
- **SafeTour (Offline Mode)**: Runs the app without external backend dependencies using bundled safety data.

### Option B: Using the Command Line
- **With `.env` credentials:**
  ```bash
  flutter run --dart-define-from-file=.env
  ```
- **In offline mode:**
  ```bash
  flutter run
  ```

---

## Codebase Architecture

SafeTour follows a modular, feature-first structure with clean separation between UI, business logic, and data layers:

```
lib/
├── core/
│   ├── constants/       # App constants, URLs, Supabase config
│   ├── theme/           # Dark mode styling, color palette, typography
│   └── utils/           # Geo distance calculations, score algorithms
├── data/
│   ├── local/           # Bundled Bengaluru locality datasets (100 zones)
│   ├── models/          # SafetyZone, EmergencyContact, SOSEvent models
│   └── repositories/    # Data repositories with local offline fallback
├── features/
│   ├── auth/            # Sign in, Sign up, Profile setup
│   ├── directory/       # Searchable Bengaluru safety zones directory
│   ├── emergency/       # Helplines (112, 1091, etc.) and personal contacts
│   ├── friends/         # SafeTour companion check-in network
│   ├── home/            # Home safety radar and score dashboard
│   ├── map/             # OpenStreetMap zero-cost interactive safety map
│   ├── navigation/      # Persistent bottom navigation shell
│   ├── onboarding/      # Welcome walkthrough for newcomers
│   ├── profile/         # User profile and account preferences
│   └── sos/             # Emergency SOS siren, countdown and SMS alert
└── main.dart            # App entrypoint and startup gate
```

---

## Development Workflow

1. **Pull the latest changes from `main`:**
   ```bash
   git checkout main
   git pull origin main
   ```

2. **Create a descriptive feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/issue-description
   ```

3. **Make code changes** following effective Dart guidelines.

4. **Run static analysis and tests:**
   ```bash
   flutter analyze
   flutter test
   ```
   Ensure there are 0 analyzer warnings and all tests pass before committing.

5. **Commit your changes:**
   ```bash
   git add .
   git commit -m "feat(map): add custom safety radius slider"
   ```

6. **Push to GitHub:**
   ```bash
   git push origin feature/your-feature-name
   ```

---

## Submitting a Pull Request

1. Go to the [SafeTour GitHub Repository](https://github.com/SafeTour26/SafeTour).
2. Click **New Pull Request** from your feature branch against `main`.
3. Fill out the PR template describing the problem, solution, and testing performed.
4. Request a review from teammates.

---

## Roadmap and Where We Need Help

Here are areas actively open for contribution:
- [ ] **Turn-by-Turn Safe Routing**: Route navigation avoiding low-scoring night zones.
- [ ] **Community Hazard Reporting**: Allow users to pin street lamp failures or isolated corridors.
- [ ] **Background Geofencing**: Push notifications when transitioning into a lower-safety zone.
- [ ] **Multilingual Support**: Kannada and Hindi localization.
- [ ] **Emergency SMS Integration**: Automated SMS dispatch with live Google Maps/OpenStreetMap links to contacts.
- [ ] **Expanded City Data**: Extending safety datasets beyond Bengaluru to other cities.

Thank you for contributing to SafeTour.
