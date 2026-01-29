# Insurance Claim Management System.....

A comprehensive Flutter application for managing hospital insurance claims. Built with modern Flutter practices, Material Design 3, and Provider state management.

## Features

### Core Functionality
- **Create & Manage Claims** - Create insurance claims with patient details, diagnosis, and insurance information
- **Bill Management** - Add, edit, and remove hospital bills with categories
- **Advance Tracking** - Record advance payments from insurance or hospital
- **Settlement Recording** - Track settlement payments with references
- **Status Workflow** - Draft → Submitted → Approved/Rejected → Partially Settled → Approved

### Professional Features
1. **Search & Sorting** - Find claims quickly by patient name, ID, diagnosis, or insurance provider. Sort by date, amount, or name
2. **Data Persistence** - All claims auto-saved to local storage using SharedPreferences
3. **Export to CSV** - Export single claims or all claims to CSV format for reporting
4. **Confirmation Dialogs & Undo** - Safe delete operations with undo capability
5. **Loading States** - Visual feedback during data loading operations
6. **Keyboard Shortcuts** - Ctrl+N (new claim), Ctrl+F (search), Esc (clear filters)
7. **Print-Friendly View** - Generate beautiful print-ready HTML reports
8. **Unit Tests** - Comprehensive test coverage for data models
9. **Responsive Layout** - Desktop navigation rail, mobile-friendly design
10. **Dark Mode** - Toggle between light and dark themes

## Screenshots

The app adapts to different screen sizes:
- **Mobile**: Bottom navigation, compact cards
- **Desktop (>900px)**: Side navigation rail with expanded menu

## Getting Started

### Prerequisites
- Flutter SDK (3.10.7 or later)
- Chrome browser (for web deployment)

### Installation

```bash
# Clone the repository
cd insurance_claim_app

# Get dependencies
flutter pub get

# Run the app (web)
flutter run -d chrome

# Build for production
flutter build web
```

### Running Tests

```bash
flutter test
```

## Project Structure

```
lib/
├── main.dart                 # App entry point with theme configuration
├── models/
│   └── claim.dart           # Data models (Claim, Bill, Advance, Settlement)
├── providers/
│   ├── claims_provider.dart # State management for claims
│   └── theme_provider.dart  # Dark/light theme management
├── screens/
│   ├── dashboard_screen.dart    # Main dashboard with stats and claims list
│   ├── claim_detail_screen.dart # Detailed claim view with tabs
│   └── claim_form_screen.dart   # Create/edit claim form
├── services/
│   ├── storage_service.dart # Local storage persistence
│   ├── export_service.dart  # CSV export functionality
│   └── print_service.dart   # Print-friendly HTML generation
├── utils/
│   └── dialogs.dart         # Reusable dialog utilities
└── widgets/
    ├── async_widgets.dart   # Loading state widgets
    ├── bill_dialog.dart     # Add/edit bill dialog
    ├── advance_dialog.dart  # Add advance dialog
    └── settlement_dialog.dart # Add settlement dialog
```

## Technologies Used

- **Flutter** - UI framework
- **Provider** - State management
- **SharedPreferences** - Local data persistence
- **intl** - Date and currency formatting
- **uuid** - Unique ID generation
- **Material Design 3** - Modern UI components

## Architecture

The app follows a clean architecture with:
- **Models** - Immutable data classes with JSON serialization
- **Providers** - ChangeNotifier-based state management
- **Services** - Business logic for storage, export, and printing
- **Screens** - Main UI components
- **Widgets** - Reusable UI components

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Ctrl + N | Create new claim |
| Ctrl + F | Focus search bar |
| Esc | Clear search and filters |

## License

This project was created as part of a technical assignment for Medoc Health.
