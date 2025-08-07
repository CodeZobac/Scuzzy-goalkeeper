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
echo "PYTHON_BACKEND_URL is set: $([ -n "$PYTHON_BACKEND_URL" ] && echo "YES" || echo "NO")"

# Exit if critical environment variables are missing
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ] || [ -z "$MAPBOX_ACCESS_TOKEN" ]; then
  echo "ERROR: Critical environment variables are missing!"
  echo "This will cause the app to fail. Please check your GitHub repository secrets."
  exit 1
fi

if [ -f lib/src/core/config/app_config.template.dart ]; then
  echo "Creating app_config.dart from template..."
  
  # Escape single quotes in environment variables for Dart string literals
  ESCAPED_SUPABASE_URL=$(printf '%s' "$SUPABASE_URL" | sed "s/'/\\\\'/g")
  ESCAPED_SUPABASE_ANON_KEY=$(printf '%s' "$SUPABASE_ANON_KEY" | sed "s/'/\\\\'/g")
  ESCAPED_MAPBOX_ACCESS_TOKEN=$(printf '%s' "$MAPBOX_ACCESS_TOKEN" | sed "s/'/\\\\'/g")
  ESCAPED_MAPBOX_DOWNLOADS_TOKEN=$(printf '%s' "$MAPBOX_DOWNLOADS_TOKEN" | sed "s/'/\\\\'/g")
  
  # Handle PYTHON_BACKEND_URL with fallback
  if [ -z "$PYTHON_BACKEND_URL" ]; then
    echo "WARNING: PYTHON_BACKEND_URL not set, using localhost fallback"
    PYTHON_BACKEND_URL="http://localhost:8000"
  fi
  ESCAPED_PYTHON_BACKEND_URL=$(printf '%s' "$PYTHON_BACKEND_URL" | sed "s/'/\\\\'/g")
  
  # Use cat with here document and escaped variables
  cat > lib/src/core/config/app_config.dart <<EOF
class AppConfig {
  static const String supabaseUrl = '${ESCAPED_SUPABASE_URL}';
  static const String supabaseAnonKey = '${ESCAPED_SUPABASE_ANON_KEY}';
  static const String mapboxAccessToken = '${ESCAPED_MAPBOX_ACCESS_TOKEN}';
  static const String mapboxDownloadsToken = '${ESCAPED_MAPBOX_DOWNLOADS_TOKEN}';
  static const String currencySymbol = '€';
  static const bool isDemoMode = false;
  
  // Python Backend Service Configuration
  static const String backendBaseUrl = '${ESCAPED_PYTHON_BACKEND_URL}';
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
echo "Building Flutter web app..."
flutter build web
