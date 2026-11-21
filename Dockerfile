# Static site served by nginx.
FROM nginx:1.27-alpine

COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY nginx/security-headers.conf /etc/nginx/snippets/security-headers.conf
COPY index.html 404.html favicon.svg /usr/share/nginx/html/
COPY css/ /usr/share/nginx/html/css/

EXPOSE 80
