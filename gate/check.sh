#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
REPO_ROOT="${SCRIPT_DIR:h}"
SERVICE_PYTHON="${REPO_ROOT}/object/service/.venv/bin/python"
DERIVED_DATA="${TMPDIR:-/tmp}/music-glove-derived"
IOS_DESTINATION="${MUSIC_GLOVE_IOS_DESTINATION:-platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0}"

if [[ ! -x "${SERVICE_PYTHON}" ]]; then
  print -u2 "缺少 object/service/.venv；请先按 object/service/README.md 安装项目依赖。"
  exit 2
fi

"${SERVICE_PYTHON}" -m compileall -q "${REPO_ROOT}/object/service/app" "${REPO_ROOT}/object/service/tests"
"${SERVICE_PYTHON}" -m pytest "${REPO_ROOT}/object/service/tests"
"${SERVICE_PYTHON}" "${REPO_ROOT}/gate/scripts/check_markdown_links.py"
plutil -lint "${REPO_ROOT}/object/ios/MusicGlove/Resources/Info.plist"
xcodebuild \
  -project "${REPO_ROOT}/object/ios/MusicGlove.xcodeproj" \
  -scheme MusicGlove \
  -destination "${IOS_DESTINATION}" \
  -derivedDataPath "${DERIVED_DATA}" \
  CODE_SIGNING_ALLOWED=NO \
  test
