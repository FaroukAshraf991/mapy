#!/bin/bash
# Read .env and pass values as --dart-define flags to Flutter
# Usage: ./run.sh [additional flutter args]
# Example: ./run.sh -d chrome

set -a
source .env
set +a

flutter run \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  "$@"
