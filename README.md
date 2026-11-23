# Lune 🌙

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20WearOS%20%7C%20watchOS-blue)](#platform-support)
[![Security](https://img.shields.io/badge/Security-AES--256%20Encrypted-success)](#privacy--security-architecture)
[![Languages](https://img.shields.io/badge/Languages-21%20Supported-purple)](#internationalization)

> **Lune** is an open-source, privacy-first menstrual cycle, ovulation, and health intelligence platform built with **Flutter**, designed to give individuals complete ownership and cryptographic security over their reproductive health data.

---

## 🌟 Highlights & Core Principles

- 🔒 **Zero-Compromise Privacy:** Your intimate health data should never be monetized, tracked, or leaked. All cycle logs, symptoms, moods, and intimate notes are encrypted locally with AES-256 before disk storage.
- 📴 **Offline-First by Design:** Works 100% offline without requiring an account or cloud connectivity. Cloud sync is strictly opt-in and user-consented.
- 🩺 **Clinically-Informed Algorithms:** Predicts cycles, luteal/follicular phases, and ovulation windows using established reproductive health guidelines and biphasic Basal Body Temperature (BBT) detection.
- 🤖 **Context-Aware AI Companion:** Provides compassionate, evidence-based wellness insights with automated client-side data anonymization before external AI inference.
- ⌚ **Wearables Integration:** Native companion applications for **Wear OS** (Jetpack Compose & Tiles) and **Apple Watch** (SwiftUI & Complications).
- 🌐 **Global Accessibility:** Native support for **21 languages** including complete RTL support for Arabic, Urdu, and Persian.

---

## 📱 Key Features

### 1. Cycle & Fertility Intelligence
- **Intelligent Phase Tracking:** Calculates Menstrual, Follicular, Ovulation, and Luteal phases dynamically based on individual historical variance.
- **BBT Ovulation Detection:** Automatic biphasic temperature shift detection, baseline calculation, and coverline graphing.
- **Symptom & Mood Patterns:** Comprehensive logging for 30+ physical symptoms, moods, cervical mucus consistency, flow heaviness, and sexual activity.
- **Lifestyle Tracking:** Integrated logs for sleep hygiene, hydration, weight, body temperature, and meditation.

### 2. Privacy & Hardware-Backed Security
- **Local SQLite Encryption:** AES-CBC-256 encryption applied transparently to database records.
- **Hardware Keystore:** Cryptographic keys are generated and stored strictly inside platform hardware keystores (`Android Keystore` / `Apple Keychain`).
- **App Lock & Stealth Mode:** Biometric (Fingerprint / Face ID) and custom PIN app locks, including a stealth decoy calculator mode for physical safety.
- **Doctor PDF Reports:** Generate clean, encrypted PDF health summaries and trend graphs to share directly with OB/GYN specialists without sharing raw account access.

### 3. Wearable Ecosystem
- **Wear OS:** Standalone Compose app with interactive cycle ring, today's phase, quick symptom logging, and Wear Tiles.
- **Apple Watch:** Native WatchConnectivity companion app built in SwiftUI with Complications for the watch face.

---

## 🏗️ Repository Architecture

This repository is organized as a modular monorepo:

```
├── cycle_app/                          # Main Flutter application (Mobile & Wear)
│   ├── lib/
│   │   ├── core/                       # Shared infrastructure & core services
│   │   │   ├── ai/                     # AI context engine, prompts, and inference gateway
│   │   │   ├── security/               # Keystore encryption & secure storage
│   │   │   ├── firebase/               # Firebase bootstrap & cloud clients
│   │   │   └── locale/                 # Multi-language cubits & localization
│   │   ├── features/                   # Feature-first application modules
│   │   │   ├── cycle/                  # Cycle dashboard, calendar & phase rings
│   │   │   ├── logs/                   # Symptom, temperature, mood & wellness loggers
│   │   │   ├── insights/               # AI advice cards & predictive charts
│   │   │   ├── privacy/                # Privacy center, stealth mode & data deletion
│   │   │   └── settings/               # App configuration & preferences
│   │   └── menstrudel/                 # Health utilities & period prediction algorithms
│   ├── android/                        # Android project + Wear OS companion (:wear)
│   ├── ios/                            # iOS project + watchOS companion (:WatchApp)
│   └── test/                           # Comprehensive unit & widget test suite (250+ tests)
│
├── menstrual_cycle_widget-master/      # Core reusable Flutter package (v4.0.0)
│   ├── lib/
│   │   ├── database_helper/            # AES-encrypted SQLite storage layer
│   │   ├── ui/                         # Calendar widgets, graphs & cycle circle components
│   │   └── widget_languages/           # Translations for 21 languages
│   └── test/                           # Package calculation & utility tests
│
└── LICENSE                             # Open source MIT License
```

---

## 🛠️ Technology Stack

| Layer | Technologies |
|---|---|
| **Framework** | [Flutter](https://flutter.dev) (v3.24+), [Dart](https://dart.dev) (v3.5+) |
| **State Management** | `flutter_bloc` / Cubit, `provider` |
| **Local Storage** | `sqflite`, `flutter_secure_storage`, `shared_preferences` |
| **Cryptography** | `encrypt` (AES-256), `crypto` (SHA-256), Android Keystore, iOS Keychain |
| **Visualizations** | `fl_chart`, `syncfusion_flutter_charts` |
| **Wearables** | Android Jetpack Compose + Tiles, Apple WatchKit + SwiftUI |
| **Localization** | `flutter_localizations`, `intl` (21 languages supported) |

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (>= 3.24.0)
- [Dart SDK](https://dart.dev/get-dart) (>= 3.5.0)
- Android Studio / Xcode for platform builds

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Ssohebmerr/lnunr.git
   cd lnunr
   ```

2. **Install dependencies:**
   ```bash
   # In the root package
   cd menstrual_cycle_widget-master
   flutter pub get

   # In the main app
   cd ../cycle_app
   flutter pub get
   ```

3. **Run the test suite:**
   ```bash
   flutter test
   ```

4. **Launch the app:**
   ```bash
   flutter run
   ```

---

## 🌐 Internationalization (21 Languages)

Lune proudly supports full localization for:
- English, Arabic (`العربية`), Spanish (`Español`), French (`Français`), German (`Deutsch`), Italian (`Italiano`), Portuguese (`Português`), Russian (`Русский`), Turkish (`Türkçe`), Chinese (`中文`), Japanese (`日本語`), Korean (`한국어`), Hindi (`हिन्दी`), Bengali (`বাংলা`), Punjabi (`ਪੰਜਾਬੀ`), Tamil (`தமிழ்`), Urdu (`اردو`), Vietnamese (`Tiếng Việt`), Indonesian (`Bahasa Indonesia`), Javanese, and Wu Chinese.

---

## 🤝 Contributing

We welcome contributions from the open-source community, whether it's bug fixes, translations, medical accuracy reviews, or UI improvements!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'feat: add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

Please refer to [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## 💬 Community & Support

- Issues & Discussions: Use [GitHub Issues](https://github.com/Ssohebmerr/lnunr/issues) to report bugs or request features.
- Contact: `support@cycleaura.app`
