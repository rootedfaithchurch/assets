#!/bin/sh

# Re-render email templates by substituting __PUBLIC_URL__ placeholders.
# Keeps nginx running; only refreshes the rendered copy in /tmp/html.

set -eu

SRC_ROOT="/usr/share/nginx/html"
RENDER_ROOT="/tmp/html"

: "${PUBLIC_URL:?PUBLIC_URL is required}"

# Escape characters that sed uses in replacements.
PUBLIC_URL_ESCAPED=$(printf '%s' "${PUBLIC_URL}" | sed -e 's/[\/&|]/\\&/g')
FACEBOOK_URL_ESCAPED=$(printf '%s' "${FACEBOOK_URL:-#}" | sed -e 's/[\/&|]/\\&/g')
INSTAGRAM_URL_ESCAPED=$(printf '%s' "${INSTAGRAM_URL:-#}" | sed -e 's/[\/&|]/\\&/g')

# Refresh rendered copy.
rm -rf "${RENDER_ROOT}"
cp -R "${SRC_ROOT}" "${RENDER_ROOT}"

if [ -d "${RENDER_ROOT}/emails" ]; then
  find "${RENDER_ROOT}/emails" -name '*.html' -print0 | while IFS= read -r -d '' file; do
    sed -e "s|__PUBLIC_URL__|${PUBLIC_URL_ESCAPED}|g" -e "s|__FACEBOOK_URL__|${FACEBOOK_URL_ESCAPED}|g" -e "s|__INSTAGRAM_URL__|${INSTAGRAM_URL_ESCAPED}|g" "${file}" > "${file}.tmp"
    mv "${file}.tmp" "${file}"
  done
fi
