#!/bin/bash

set -e

FLUTTER_HOME="$HOME/flutter"

echo "==> Creating .env from environment variables..."
echo "SUPABASE_URL=${SUPABASE_URL}" > .env
echo "SUPABASE_PUBLISHABLE_KEY=${SUPABASE_PUBLISHABLE_KEY}" >> .env

echo "==> Cloning Flutter stable..."
git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_HOME"

export PATH="$PATH:$FLUTTER_HOME/bin"

echo "==> Flutter version..."
flutter --version

echo "==> Enabling web..."
flutter config --enable-web

echo "==> pub get..."
flutter pub get

echo "==> Building web..."
flutter build web --release \
  --dart-define=SUPABASE_URL=${SUPABASE_URL} \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=${SUPABASE_PUBLISHABLE_KEY}

echo "==> Build complete."
