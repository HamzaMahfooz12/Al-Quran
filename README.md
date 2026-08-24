# 📖 Al Quran — Read, Listen & Reflect

A premium, full-featured Holy Quran mobile application built with **Flutter**, offering authentic Mushaf layouts, real-time synchronized word-by-word audio recitation, translations, tafseers, Mutashabihat (similar verses), and smart offline caching.

---

## ✨ Features

### 1. 📖 Three Distinct Quran Reading Views
* **Simple Quran (Verse-by-Verse Reader & Juz Reader)**:
  - Clean card-based reading with Arabic, Translations, Tafseer, Bookmarking, and Word-by-Word live audio recitation.
* **15-Line Madani Mushaf**:
  - High-precision authentic 15-line page layout (1–610 pages) with Ruku marginal badges, Sajda indicators, and Mistakes marking mode.
* **16-Line Indo-Pak Mushaf**:
  - Authentic 16-line subcontinental grid layout (1–548 pages) with authentic typography, ligatures, and pause signs.

---

### 2. 🎙️ Synchronized Word-by-Word Audio Recitation
* **Real-Time Word Highlighting**: Active recited word illuminates in a **Warm Golden Amber glow capsule** (`#FFE082`) in real-time as the Qari recites.
* **Support for 20+ Renowned Reciters**: Including Mishary Rashid Alafasy, Mahmoud Khalil Al-Husary, AbdulBaset AbdulSamad, Mohamed Siddiq Al-Minshawi, Abdur-Rahman As-Sudais, Abu Bakr Al-Shatri, Sa'ud Ash-Shuraim, Hani Ar-Rifai, and more.
* **Sliding-Window ($N-1, N, N+1$) Pre-Caching Engine**:
  - Automatically pre-downloads the next verse in the background for **instant 0ms transition delay** between verses.
  - Keeps previous verse for seamless backward rewind.
  - Skip-aware cache purging ensures minimal phone storage usage.
* **Seamless Auto Page-Turning**: When recitation completes the last verse on a Mushaf page, the view smoothly turns to the next page while recitation continues uninterrupted.
* **Floating & Sticky Audio Control Bar**: Play/Pause, Reciter Selection, Speed adjustment (0.75x to 2.0x), and Next/Previous verse navigation.

---

### 3. 🛑 Quranic Waqf Stopping Marks & Verse End Badges
* Complete authentic stopping marks (`ط`, `لا`, `ج`, `مـ`, `قلی`, `صلی`, `ز`, `ص`, `س`, `ۛ`, `ع`, `قف`, `ك`) styled directly over Ayah end circles across all three Quran views.

---

### 4. 🔗 Mutashabihat (Similar Ayahs)
* Instant access to cross-Quran similar verses with thematic context, allowing Hafiz and students to revise and navigate similar verses effortlessly.

---

### 5. 🕌 Prayer Times & Fiqh Juristic Calculation
* GPS and manual location prayer times.
* Fiqh Juristic method toggles: **Hanafi** (Later Asr) and **Shafi'i / Hanbali / Maliki** (Standard Asr).

---

### 6. 🎨 Dynamic Verse Sharing & Wallpapers
* Export and share beautiful Ayah graphics with custom background wallpapers (Sanctuary, Celestial, Dawn Light, Arabesque).

---

### 7. ⚙️ Storage & Cache Management
* Real-time audio storage footprint calculation.
* One-tap **"Clear Audio Cache"** button in Settings with confirmation.

---

## 🛠️ Technology Stack

* **Framework**: [Flutter](https://flutter.dev) (Dart SDK ^3.11.4)
* **State Management**: [Riverpod](https://riverpod.dev)
* **Audio Engine**: [just_audio](https://pub.dev/packages/just_audio) & `just_audio_media_kit`
* **Local Database**: [SQLite (sqflite)](https://pub.dev/packages/sqflite) with pre-indexed word-layout coordinates & gzip decompression
* **Networking & Caching**: [Dio](https://pub.dev/packages/dio), [path_provider](https://pub.dev/packages/path_provider)
* **Typography**: Google Fonts (Amiri, Scheherazade New, Inter, Noto Nastaliq Urdu, Outfit)

---

## 🚀 Getting Started

### Prerequisites
* Flutter SDK (3.24.0 or newer)
* Android SDK (API Level 21+)

### Installation & Run
```bash
# Clone the repository
git clone https://github.com/HamzaMahfooz12/Al-Quran.git
cd Al-Quran/al_quran_app

# Install dependencies
flutter pub get

# Run on connected device or emulator
flutter run
```

### Build Release APK
```bash
flutter build apk --split-per-abi
```

---

## 📄 License
This project is licensed for personal and educational use.
