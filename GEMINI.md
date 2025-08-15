# Gemini Code Assistant Context

## Project Overview

This project is a Dart library named `muxa_xtream` for interacting with Xtream Codes IPTV services. It provides a client for querying account information, catalogs, details, EPG, and building streaming URLs. The library is designed to be lightweight and has no UI dependencies, making it suitable for use in various Dart applications.

The project is well-structured, with a clear separation of concerns. The core logic is in the `lib` directory, with a public API exposed through `lib/muxa_xtream.dart`. The project also includes a comprehensive example application in the `example` directory, which demonstrates how to use the library.

## Building and Running

The project is a standard Dart package. To build and run the project, you will need to have the Dart SDK installed.

### Key Commands

*   **Install dependencies:** `dart pub get`
*   **Run the example application:**
    *   Mock mode: `dart run example/main.dart --mock`
    *   Real portal: `dart run example/main.dart --portal https://your.portal/ --user USER --pass PASS`
*   **Run tests:** `dart test`
*   **Run verification script (formatting, analysis, tests):** `tool/verify.sh`

## Development Conventions

The project follows standard Dart conventions.

*   **Formatting:** The code is formatted using `dart format`.
*   **Static Analysis:** The code is analyzed using `dart analyze`.
*   **Testing:** The project has a suite of tests in the `test` directory. The tests are run using the `test` package.
*   **Commits:** The project has a `CONTRIBUTING.md` file that outlines the workflow rules, including commit format.
*   **CI:** The project uses GitHub Actions for continuous integration. The CI configuration is in `.github/workflows/ci.yml`.

## Key Files

*   `pubspec.yaml`: Defines the project's metadata and dependencies.
*   `lib/muxa_xtream.dart`: The main entry point of the library.
*   `lib/src/client.dart`: The core client implementation.
*   `lib/src/api.dart`: The public API barrel file.
*   `example/main.dart`: An example command-line application that demonstrates how to use the library.
*   `tool/verify.sh`: A script that runs a series of checks to verify the project's code quality.
*   `README.md`: The project's README file, which provides a good overview of the project.
*   `AGENTS.md`: Contributor and development guidelines.
*   `CONTRIBUTING.md`: Workflow rules (verify script, commit format, examples, hooks).
