#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
  export $(cat .env | sed 's/#.*//g' | xargs)
fi

escaped_mapbox_downloads_token=$(printf '%s' "$MAPBOX_DOWNLOADS_TOKEN" | sed -e 's/[\/&]/\\&/g')

if [ -f lib/src/core/config/app_config.template.dart ]; then
  sed -e "s/{{SUPABASE_URL}}/$escaped_supabase_url/g" \
      -e "s/{{SUPABASE_ANON_KEY}}/$escaped_supabase_anon_key/g" \
      -e "s/{{MAPBOX_ACCESS_TOKEN}}/$escaped_mapbox_access_token/g" \
      -e "s/{{MAPBOX_DOWNLOADS_TOKEN}}/$escaped_mapbox_downloads_token/g" \
      lib/src/core/config/app_config.template.dart > lib/src/core/config/app_config.dart
fi

# Build the Flutter web app
flutter build web
