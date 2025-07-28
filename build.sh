#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
  export $(cat .env | sed 's/#.*//g' | xargs)
fi

# Generate app_config.dart from template
if [ -f lib/src/core/config/app_config.template.dart ]; then
  sed -e "s|{{SUPABASE_URL}}|${SUPABASE_URL}|g" \
      -e "s|{{SUPABASE_ANON_KEY}}|${SUPABASE_ANON_KEY}|g" \
      -e "s|{{MAPBOX_ACCESS_TOKEN}}|${MAPBOX_ACCESS_TOKEN}|g" \
      -e "s|{{MAPBOX_DOWNLOADS_TOKEN}}|${MAPBOX_DOWNLOADS_TOKEN}|g" \
      lib/src/core/config/app_config.template.dart > lib/src/core/config/app_config.dart
fi

# Replace Firebase config placeholders in index.html
if [ -f web/index.html ]; then
  sed -i "s|\${FIREBASE_API_KEY}|\${FIREBASE_API_KEY}|g" web/index.html
  sed -i "s|\${FIREBASE_AUTH_DOMAIN}|\${FIREBASE_AUTH_DOMAIN}|g" web/index.html
  sed -i "s|\${FIREBASE_PROJECT_ID}|\${FIREBASE_PROJECT_ID}|g" web/index.html
  sed -i "s|\${FIREBASE_STORAGE_BUCKET}|\${FIREBASE_STORAGE_BUCKET}|g" web/index.html
  sed -i "s|\${FIREBASE_MESSAGING_SENDER_ID}|\${FIREBASE_MESSAGING_SENDER_ID}|g" web/index.html
  sed -i "s|\${FIREBASE_APP_ID}|\${FIREBASE_APP_ID}|g" web/index.html
  sed -i "s|\${FIREBASE_MEASUREMENT_ID}|\${FIREBASE_MEASUREMENT_ID}|g" web/index.html
fi

# Build the Flutter web app
flutter build web
