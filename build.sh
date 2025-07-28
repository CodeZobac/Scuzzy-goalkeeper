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

if [ -f lib/src/core/config/app_config.template.dart ]; then
  echo "Creating app_config.dart from template..."
  
  # Use cat with here document to avoid sed escaping issues
  cat > lib/src/core/config/app_config.dart << EOF
class AppConfig {
  static const String supabaseUrl = '${SUPABASE_URL}';
  static const String supabaseAnonKey = '${SUPABASE_ANON_KEY}';
  static const String mapboxAccessToken = '${MAPBOX_ACCESS_TOKEN}';
  static const String mapboxDownloadsToken = '${MAPBOX_DOWNLOADS_TOKEN}';
  static const bool isDemoMode = false;
}
EOF
  
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
