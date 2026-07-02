# Dr.N

**Minecraft Bedrock Proxy App** – Verbinde deine PS5, Xbox oder Switch mit beliebigen Bedrock-Servern, indem dein Phone als LAN-Proxy fungiert.

Dr.N läuft auf **iOS + Android** und nutzt den **BedrockTogether-Transfer-Ansatz** (basierend auf [gophertunnel](https://github.com/Sandertv/gophertunnel)):

1. 📱 Phone zeigt sich als LAN-Server
2. 🎮 PS5/Xbox verbindet sich mit dem Phone
3. 📱 Phone reicht die Verbindung per **Transfer-Packet** an den echten Server weiter
4. ✅ **Phone kann aus** – die Konsole spielt direkt auf dem Server!

## 📱 Features

- **Single Page UI** – Server hinzufügen, speichern, Proxy starten/stoppen
- **PS5 & Xbox** – Erscheint im Friends/LAN-Tab
- **Switch** – Erscheint im LAN-Tab (kein Nintendo-Account nötig)
- **Unsignierte IPA** (iOS, zum Sideloaden mit AltStore/Sideloadly)
- **Signierte APK** (Android, direkt installierbar)
- **GitHub Actions** – Automatische Builds bei jedem Push

## 🏗️ Architektur

```
Dr.N/
├── go/core/                  # Go Proxy Library
│   ├── drn/proxy.go          # Core-Proxy (gophertunnel MITM)
│   ├── drnbind/mobile.go     # gomobile Bindungs-API
│   └── go.mod
├── flutter_app/              # Flutter UI
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/home_screen.dart   # Hauptseite
│   │   └── services/proxy_service.dart # Platform Channel
│   ├── android/              # Android Native Bridge (Kotlin)
│   └── ios/                  # iOS Native Bridge (Swift)
└── .github/workflows/
    ├── build-android.yml     # APK Build
    └── build-ios.yml         # IPA Build (unsigned)
```

## 🚀 Build Anleitung

### Voraussetzungen

- [Go 1.24+](https://go.dev/dl/)
- [Flutter 3.24+](https://flutter.dev/docs/get-started/install)
- [gomobile](https://pkg.go.dev/golang.org/x/mobile/cmd/gomobile)

### Lokal bauen

```bash
# 1. Go Dependencies
cd go/core
go mod tidy

# 2. Go Library für Android bauen
gomobile bind -target=android -o ../flutter_app/android/app/libs/drn.aar github.com/b3nni/drn/core/drnbind

# Oder für iOS
gomobile bind -target=ios -o ../flutter_app/ios/Runner/drn.xcframework github.com/b3nni/drn/core/drnbind

# 3. Flutter APK/IPA bauen
cd ../flutter_app
flutter pub get
flutter build apk --release    # Android
flutter build ios --release --no-codesign   # iOS (unsigned)
```

### GitHub Actions

Einfach pushen – die Workflows bauen automatisch:

- **Android:** `flutter build apk --release` → signierte APK
- **iOS:** `flutter build ios --no-codesign` → unsigned IPA

Die fertigen Builds liegen als **GitHub Release** + **Artifact** bereit.

## 📲 Installation

### Android
1. APK aus dem GitHub Release herunterladen
2. Auf dem Phone öffnen (Unbekannte Quellen erlauben)
3. App starten

### iOS (unsigned, via Sideloading)
1. IPA aus dem GitHub Release herunterladen
2. Mit [AltStore](https://altstore.io/), [Sideloadly](https://sideloadly.io/) oder [TrollStore](https://github.com/opa334/TrollStore) installieren
3. App starten

## 🎮 Nutzung

1. App öffnen
2. **+** tippen, Server-Name + IP/Port eingeben → Speichern
3. Server in der Liste antippen → **Play** drücken
4. Auf der Konsole im **LAN/Friends-Tab** → Server erscheint!
5. Verbinden und spielen 🎉

### Wichtig
- Phone und Konsole müssen **im selben WLAN** sein
- In Minecraft: **"Visible to LAN players"** muss AN sein
- Phone muss während des Spielens verbunden bleiben (Proxy läuft)

## ⚙️ Technisches

- **Proxy-Typ:** Full MITM Proxy (alle Pakete gehen übers Phone)
- **Bibliothek:** gophertunnel (MIT License)
- **Protokoll:** RakNet + Minecraft Bedrock Protocol
- **Port:** Dynamisch (0.0.0.0:0)
- **Auth:** Ausgeschaltet (AuthenticationDisabled: true)

## 📄 Lizenz

MIT – basierend auf [gophertunnel](https://github.com/Sandertv/gophertunnel) (MIT) und [Phantom](https://github.com/jhead/phantom) (MIT)

---

**Dr.N** – *"Dr. Network" – Dein LAN-Arzt für Minecraft Bedrock*