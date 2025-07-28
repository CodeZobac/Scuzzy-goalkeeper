#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
  export $(cat .env | sed 's/#.*//g' | xargs)
fi

# Debug: Check if environment variables are set
echo "Checking environment variables..."
echo "SUPABASE_URL is set: $([ -n "$SUPABASE_URL" ] && echo "YES" || echo "NO")"
echo "SUPABASE_ANON_KEY is set: $([ -n "$SUPABASE_ANON_KEY" ] && echo "YES" || echo "NO")"
echo "MAPBOX_ACCESS_TOKEN is set: $([ -n "$MAPBOX_ACCESS_TOKEN" ] && echo "YES" || echo "NO")"
echo "MAPBOX_DOWNLOADS_TOKEN is set: $([ -n "$MAPBOX_DOWNLOADS_TOKEN" ] && echo "YES" || echo "NO")"

# Exit if critical environment variables are missing
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ] || [ -z "$MAPBOX_ACCESS_TOKEN" ]; then
  echo "ERROR: Critical environment variables are missing!"
  echo "This will cause the app to fail. Please check your GitHub repository secrets."
  exit 1
fi

# Escape all environment variables for safe sed replacement
# Use a different delimiter for sed to avoid issues with forward slashes in URLs
escaped_supabase_url=$(printf '%s' "$SUPABASE_URL" | sed -e 's/[\/&]/\\&/g')
escaped_supabase_anon_key=$(printf '%s' "$SUPABASE_ANON_KEY" | sed -e 's/[\/&]/\\&/g')
escaped_mapbox_access_token=$(printf '%s' "$MAPBOX_ACCESS_TOKEN" | sed -e 's/[\/&]/\\&/g')
escaped_mapbox_downloads_token=$(printf '%s' "$MAPBOX_DOWNLOADS_TOKEN" | sed -e 's/[\/&]/\\&/g')

if [ -f lib/src/core/config/app_config.template.dart ]; then
  echo "Creating app_config.dart from template..."
  sed -e "s|{{SUPABASE_URL}}|$SUPABASE_URL|g" \
      -e "s|{{SUPABASE_ANON_KEY}}|$SUPABASE_ANON_KEY|g" \
      -e "s|{{MAPBOX_ACCESS_TOKEN}}|$MAPBOX_ACCESS_TOKEN|g" \
      -e "s|{{MAPBOX_DOWNLOADS_TOKEN}}|$MAPBOX_DOWNLOADS_TOKEN|g" \
      lib/src/core/config/app_config.template.dart > lib/src/core/config/app_config.dart
  
  echo "Generated app_config.dart successfully"
  # Verify the file was created and has content
  if [ -f lib/src/core/config/app_config.dart ]; then
    echo "Configuration file size: $(wc -c < lib/src/core/config/app_config.dart) bytes"
    echo "Checking for remaining placeholders..."
    if grep -q "{{" lib/src/core/config/app_config.dart; then
      echo "WARNING: Found unreplaced placeholders in generated config!"
      grep "{{" lib/src/core/config/app_config.dart
    else
      echo "✅ All placeholders successfully replaced"
    fi
  else
    echo "ERROR: Failed to generate app_config.dart"
    exit 1
  fi
else
  echo "Template file not found: lib/src/core/config/app_config.template.dart"
  exit 1
fi

# Build the Flutter web app
flutter build web
