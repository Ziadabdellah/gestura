#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../apps/gestura"

COPYFILE_DISABLE=1 tar --no-xattrs -czf - \
  firebase.json \
  lib/firebase/firebase_options_dev.dart \
  lib/firebase/firebase_options_staging.dart \
  lib/firebase/firebase_options_prod.dart \
  android/app/src/dev/google-services.json \
  android/app/src/staging/google-services.json \
  android/app/src/prod/google-services.json \
  ios/flavors/dev/GoogleService-Info.plist \
  ios/flavors/staging/GoogleService-Info.plist \
  ios/flavors/prod/GoogleService-Info.plist \
  | base64 | tr -d '\n'
