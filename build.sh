#!/bin/bash

FLUTTER_HOME="$HOME/flutter"

echo "==> Cloning Flutter..."
git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_HOME"
if [ $? -ne 0 ]; then echo "FAILED: git clone"; exit 1; fi

export PATH="$PATH:$FLUTTER_HOME/bin"

echo "==> Flutter version..."
flutter --version
if [ $? -ne 0 ]; then echo "FAILED: flutter --version"; exit 1; fi

echo "==> Enabling web..."
flutter config --enable-web
if [ $? -ne 0 ]; then echo "FAILED: flutter config"; exit 1; fi

echo "==> pub get..."
flutter pub get
if [ $? -ne 0 ]; then echo "FAILED: flutter pub get"; exit 1; fi

echo "==> Building web..."
flutter build web --release --dart-define=SUPABASE_PUBLISHABLE_KEY=$SUPABASE_PUBLISHABLE_KEY
if [ $? -ne 0 ]; then echo "FAILED: flutter build web"; exit 1; fi

echo "==> Done."
