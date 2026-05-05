# SaberPlus

**Fork di [Saber Notes](https://github.com/saber-notes/saber) con Google Drive sync, supporto Redmi Smart Pen, webapp e widget Android.**

SaberPlus è un'app per prendere appunti con il pennino su Android, con sincronizzazione automatica su Google Drive e una webapp compagna per visualizzare e annotare le note dal browser.

---

## Funzionalità aggiunte rispetto all'originale

### 🖊️ Redmi Smart Pen
I pulsanti laterali della penna vengono intercettati nativamente:

| Pulsante | Azione |
|---|---|
| Pulsante 1 (PAGE_DOWN) | Toggle gomma |
| Pulsante 2 (PAGE_UP) | Toggle selezione |

### ☁️ Sincronizzazione Google Drive
- Autenticazione OAuth2 tramite browser — nessuno SHA1 richiesto
- File salvati in `appDataFolder` — privati, accessibili solo dall'app
- Upload automatico dopo ogni modifica (debounce 3 secondi)
- Download automatico ogni 30 secondi
- Indicatore sync nell'header con pallino colorato (grigio/blu/verde/rosso)
- Notifica SnackBar quando una nota viene aggiornata da un altro dispositivo
- Protezione dell'editor durante il sync — nessun crash se la nota è aperta

### 📝 Annotazioni web bidirezionali
- Drawer "Web Annotations" nell'editor per leggere le note aggiunte dalla webapp
- Testo Quill copiabile direttamente nell'editor
- Immagini e screenshot visibili nel drawer
- Sincronizzazione bidirezionale tramite file `.quill.json` su Drive

### 🏠 Widget home screen
- Widget 2×2 con le ultime 5 note modificate
- Tocca una nota per aprirla direttamente nell'editor
- Si aggiorna automaticamente ogni 30 minuti

---

## Webapp compagna

Le note sincronizzate su Drive sono visualizzabili e annotabili via browser tramite **[SaberPlus Web](https://github.com/Ken5998/saber-web)** — una webapp Next.js self-hostata..

**Funzionalità webapp:**
- Login Google con refresh token automatico
- Lista note con miniature, cartelle e ricerca
- Rendering fedele dei tratti a mano con canvas hi-DPI
- Zoom, pan, pinch-to-zoom
- Export PNG e PDF
- Editor Quill con formattazione (grassetto, corsivo, liste)
- Upload screenshot e immagini con drag&drop e paste
- Dark mode completa
- PWA installabile

---

## Prerequisiti

- Flutter SDK (stable) — vedi [flutter.dev](https://flutter.dev/docs/get-started/install)
- Android SDK 36 con Build Tools 36.0.0
- JDK 17
- Un progetto Google Cloud con **Google Drive API** abilitata
- Credenziali OAuth2 di tipo **Desktop app**

---

## Setup ambiente (macOS)

```bash
brew install flutter --cask android-commandlinetools openjdk@17

export ANDROID_HOME="/opt/homebrew/share/android-commandlinetools"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"

sdkmanager --install "platform-tools" "platforms;android-36" "build-tools;36.0.0"
flutter doctor --android-licenses
```

---

## Setup Google Cloud

1. Crea un progetto su [console.cloud.google.com](https://console.cloud.google.com)
2. Abilita **Google Drive API**
3. Configura la **OAuth consent screen** (External)
4. Crea credenziali **OAuth 2.0 → Desktop app**
5. Salva le credenziali in `.env` (non committare):

```bash
GOOGLE_CLIENT_ID=il_tuo_client_id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=il_tuo_client_secret
```

---

## Build e Run

```bash
# Clone
git clone https://github.com/Ken5998/SaberPlus.git
cd SaberPlus

# Dipendenze
flutter pub get

# Debug sul dispositivo connesso
flutter run \
  --dart-define=GOOGLE_CLIENT_ID=$(grep GOOGLE_CLIENT_ID .env | cut -d= -f2) \
  --dart-define=GOOGLE_CLIENT_SECRET=$(grep GOOGLE_CLIENT_SECRET .env | cut -d= -f2)

# Build APK release
flutter build apk --release \
  --dart-define=GOOGLE_CLIENT_ID=$(grep GOOGLE_CLIENT_ID .env | cut -d= -f2) \
  --dart-define=GOOGLE_CLIENT_SECRET=$(grep GOOGLE_CLIENT_SECRET .env | cut -d= -f2)
```

---

## Connessione dispositivo Android

1. **Impostazioni → Info sul dispositivo** → tocca "Versione MIUI" 7 volte
2. **Opzioni sviluppatore** → attiva **Debug USB** e **Installa tramite USB**
3. Collega via USB e autorizza sul popup
4. `adb devices` per verificare

---

## Struttura delle modifiche

```
android/app/src/main/kotlin/com/adilhanney/saber/
├── MainActivity.kt              # KeyEvent Smart Pen + MethodChannel
├── RecentNotesWidget.kt         # Widget home screen note recenti

android/app/src/main/res/
├── drawable/ic_launcher_foreground_plus.xml  # Badge + icona
├── layout/widget_recent_notes.xml            # Layout widget
└── xml/widget_recent_notes_info.xml          # Config widget

lib/
├── components/editor/
│   └── web_annotations_sheet.dart   # Drawer annotazioni web
├── data/googledrive/
│   ├── drive_client.dart            # OAuth2 Google
│   └── drive_syncer.dart            # Upload/download Drive
├── data/editor/
│   └── editor_core_info.dart        # Caricamento .quill.json
├── data/file_manager/
│   └── file_manager.dart            # Enqueue upload Drive
├── pages/user/
│   └── drive_login.dart             # Pagina login Drive
├── pages/editor/
│   └── editor.dart                  # Smart Pen + drawer annotations
├── data/prefs.dart                  # Preferenze Drive
└── main.dart                        # Sync Drive all'avvio + polling
```

---

## Gestione aggiornamenti

Per ricevere aggiornamenti dal repo originale Saber:

```bash
git remote add upstream https://github.com/saber-notes/saber.git
git fetch upstream
git log upstream/main --oneline | head -20
```

I file modificati da SaberPlus sono circoscritti — i conflitti sono gestibili manualmente caso per caso.

---

## File da non committare

```
.env
android/key.properties
android/app/release.keystore
```

---

## Crediti

Fork di [Saber Notes](https://github.com/saber-notes/saber) di [@adilhanney](https://github.com/adilhanney). Tutto il lavoro originale appartiene ai rispettivi autori.

---

## Licenza

**GPL-3.0** — in conformità con il progetto originale.
