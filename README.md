# Farmer Expense Record 🌾

A beginner-friendly Flutter app for farmers to record farm income and expenses.

## Features
- Add expenses by crop and category
- Record income from crop sales
- See total income, total expenses and profit/loss
- Review recent records and delete mistakes
- Saves records on the device using SharedPreferences
- Responsive Flutter Web interface
- GitHub Actions workflow to build and publish the Flutter Web app to GitHub Pages

## Run locally
1. Install Flutter SDK: https://docs.flutter.dev/get-started/install
2. Open this project folder in VS Code or Android Studio.
3. Run:
   ```bash
   flutter pub get
   flutter run -d chrome
   ```

## Build for web
```bash
flutter pub get
flutter build web --base-href "/FARMER-2/"
```

## Deploy
The workflow in `.github/workflows/deploy.yml` builds the app and deploys it to GitHub Pages whenever code is pushed to `main`.
In GitHub, open **Settings → Pages** and set **Build and deployment → Source** to **GitHub Actions** if it is not already selected. Then check **Actions** for the deployment status.

## Data note
Records are saved in the browser/device where you enter them. They are not automatically synced between different phones or users.
