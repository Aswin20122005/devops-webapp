# Static site served by nginx, running as a non-root user.
FROM nginxinc/nginx-unprivileged:1.31-alpine

ARG GIT_SHA=dev
ARG BUILD_DATE=unknown
LABEL org.opencontainers.image.source="https://github.com/Aswin20122005/devops-webapp" \
      org.opencontainers.image.revision="$GIT_SHA" \
      org.opencontainers.image.created="$BUILD_DATE"

COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY nginx/security-headers.conf /etc/nginx/snippets/security-headers.conf
COPY index.html 404.html favicon.svg /usr/share/nginx/html/
COPY css/ /usr/share/nginx/html/css/
COPY js/ /usr/share/nginx/html/js/

# Expose which commit is running at /version.json
RUN printf '{"commit":"%s","built":"%s"}\n' "$GIT_SHA" "$BUILD_DATE" > /usr/share/nginx/html/version.json

# Unprivileged nginx can't bind to ports below 1024.
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1:8080/healthz || exit 1
