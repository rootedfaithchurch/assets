#!/bin/sh

set -eu

SRC_ROOT="/usr/share/nginx/html"
RENDER_ROOT="/tmp/html"

: "${PUBLIC_URL:?PUBLIC_URL is required}"

# Escape characters that are special in sed replacement.
PUBLIC_URL_ESCAPED=$(printf '%s' "${PUBLIC_URL}" | sed -e 's/[\/&|]/\\&/g')
FACEBOOK_URL_ESCAPED=$(printf '%s' "${FACEBOOK_URL:-#}" | sed -e 's/[\/&|]/\\&/g')

# Prepare a writable copy of the site content.
rm -rf "${RENDER_ROOT}"
cp -R "${SRC_ROOT}" "${RENDER_ROOT}"

# Render email templates with the injected PUBLIC_URL placeholder.
if [ -d "${RENDER_ROOT}/emails" ]; then
  find "${RENDER_ROOT}/emails" -name '*.html' -print0 | while IFS= read -r -d '' file; do
    sed -e "s|__PUBLIC_URL__|${PUBLIC_URL_ESCAPED}|g" -e "s|__FACEBOOK_URL__|${FACEBOOK_URL_ESCAPED}|g" "${file}" > "${file}.tmp"
    mv "${file}.tmp" "${file}"
  done
fi

# Configure nginx to serve the rendered copy.
cat > /etc/nginx/conf.d/default.conf <<'EOF'
server {
  listen 80;
  listen [::]:80;
  server_name _;
  root /tmp/html;

  location / {
    add_header Access-Control-Allow-Origin * always;
    try_files $uri $uri/ =404;
  }
}
EOF

exec nginx -g 'daemon off;'
