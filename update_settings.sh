#!/usr/bin/env bash
# shellcheck disable=SC1091,2148

# Constants for setting patterns
DEFAULT_TRUE="'default': true"
DEFAULT_FALSE="'default': false"
DEFAULT_ON="'default': TelemetryConfiguration.ON"
DEFAULT_OFF="'default': TelemetryConfiguration.OFF"
TELEMETRY_CRASH_REPORTER="'telemetry.enableCrashReporter':"
TELEMETRY_CONFIGURATION=" TelemetryConfiguration.ON"
NLS_SETTING="workbench.settings.enableNaturalLanguageSearch"

# Source common utility functions
. ../utils.sh

# Update a setting in the specified file by searching for the setting and replacing its default value
update_setting() {
  local SETTING FILENAME LINE_NUM IN_SETTING FOUND REPLACEMENT_CMD CURRENT_LINE

  SETTING="$1"
  FILENAME="$2"

  # Check if the file exists
  if [[ ! -f "$FILENAME" ]]; then
    echo "File does not exist: $FILENAME"
    return 1
  fi

  LINE_NUM=0
  IN_SETTING=0
  FOUND=0

  # Read file line by line
  while IFS= read -r CURRENT_LINE; do
    LINE_NUM=$((LINE_NUM + 1))
    # Detect the block containing the setting
    if [[ "$CURRENT_LINE" == *"$SETTING"* ]]; then
      IN_SETTING=1
    fi
    # Look for the default value and mark as found
    if [[ ( "$CURRENT_LINE" == *"$DEFAULT_TRUE"* || "$CURRENT_LINE" == *"$DEFAULT_ON"* ) && "$IN_SETTING" -eq 1 ]]; then
      FOUND=1
      break
    fi
  done < "$FILENAME"

  if [[ $FOUND -ne 1 ]]; then
    echo "Default value not found for setting '$SETTING' in '$FILENAME'"
    return 1
  fi

  # Prepare the replacement command for sed
  if [[ "$CURRENT_LINE" == *"$DEFAULT_TRUE"* ]]; then
    REPLACEMENT_CMD="${LINE_NUM}s/${DEFAULT_TRUE}/${DEFAULT_FALSE}/"
  else
    REPLACEMENT_CMD="${LINE_NUM}s/${DEFAULT_ON}/${DEFAULT_OFF}/"
  fi

  # Call the replace utility (assumed to be defined in utils.sh)
  replace "$REPLACEMENT_CMD" "$FILENAME"
}

# Update settings in the respective files
update_setting "$TELEMETRY_CRASH_REPORTER" src/vs/workbench/electron-sandbox/desktop.contribution.ts
update_setting "$TELEMETRY_CONFIGURATION" src/vs/platform/telemetry/common/telemetryService.ts
update_setting "$NLS_SETTING" src/vs/workbench/contrib/preferences/common/preferencesContribution.ts
