# Static site served by nginx, running as a non-root user.
FROM nginxinc/nginx-unprivileged:1.27-alpine

COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY nginx/security-headers.conf /etc/nginx/snippets/security-headers.conf
COPY index.html 404.html favicon.svg /usr/share/nginx/html/
COPY css/ /usr/share/nginx/html/css/

# Unprivileged nginx can't bind to ports below 1024.
EXPOSE 8080
