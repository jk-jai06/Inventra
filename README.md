# Inventra Mobile Application

## Overview
Inventra is an AI-powered smart inventory and GST billing system designed for small retail shops. This mobile application aims to streamline business management by providing features for inventory management, GST billing, customer management, sales tracking, and AI-powered insights.

## Project Structure
The mobile application is structured as follows:

```
mobile/
├── lib/
│   ├── main.dart                # Entry point of the Flutter application
│   ├── core/                    # Core functionalities
│   │   ├── constants/           # Constant values used throughout the app
│   │   ├── theme/               # Application theme definitions
│   │   ├── utils/               # Utility functions and helpers
│   │   └── services/            # Services for API calls and business logic
│   ├── models/                  # Data models for the application entities
│   ├── repositories/            # Repository classes for data access
│   ├── providers/               # State management providers
│   ├── features/                # Feature-specific functionalities
│   │   ├── auth/                # Authentication features
│   │   ├── dashboard/           # Dashboard functionalities
│   │   ├── inventory/           # Inventory management features
│   │   ├── billing/             # Billing functionalities
│   │   ├── customers/           # Customer management features
│   │   ├── sales/               # Sales records management
│   │   ├── analytics/           # Analytics and reporting features
│   │   └── settings/            # Application settings management
│   └── widgets/                 # Reusable UI components
├── test/                        # Unit and widget tests
├── pubspec.yaml                 # Flutter project configuration
└── README.md                    # Documentation for the mobile application
```

## Setup Instructions
1. **Clone the Repository**
   ```
   git clone <repository-url>
   cd inventra/mobile
   ```

2. **Install Dependencies**
   Make sure you have Flutter installed. Run the following command to get the required packages:
   ```
   flutter pub get
   ```

3. **Firebase Configuration**
   - Set up a Firebase project and configure your app with the necessary credentials.
   - Update the `firebase` directory with your Firestore rules and indexes.

4. **Run the Application**
   Use the following command to run the application on an emulator or connected device:
   ```
   flutter run
   ```

## Usage Guidelines
- **Authentication**: Users can register, log in, and manage their accounts.
- **Inventory Management**: Add, edit, and delete products. Monitor stock levels and receive alerts for low stock.
- **Billing**: Generate GST-compliant invoices and manage sales transactions.
- **Customer Management**: Keep track of customer details and purchase history.
- **Analytics**: View sales metrics and receive AI-generated insights.

## Contribution
Contributions are welcome! Please follow the standard Git workflow for submitting changes.

## License
This project is licensed under the MIT License. See the LICENSE file for more details.