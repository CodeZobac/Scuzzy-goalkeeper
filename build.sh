#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
  export $(cat .env | sed 's/#.*//g' | xargs)
fi

# Generate app_config.dart from template
if [ -f lib/src/core/config/app_config.template.dart ]; then
  sed -e "s#{{SUPABASE_URL}}#${SUPABASE_URL}#g" \
      -e "s#{{SUPABASE_ANON_KEY}}#${SUPABASE_ANON_KEY}#g" \
      -e "s#{{MAPBOX_ACCESS_TOKEN}}#${MAPBOX_ACCESS_TOKEN}#g" \
      -e "s#{{MAPBOX_DOWNLOADS_TOKEN}}#${MAPBOX_DOWNLOADS_TOKEN}#g" \
      lib/src/core/config/app_config.template.dart > lib/src/core/config/app_config.dart
fi

# Build the Flutter web app
flutter build web
