FROM nginx:1.27.0-alpine-slim

RUN apk update
# copy the info of the builded web app to nginx
COPY build/web /usr/share/nginx/html

# Expose and run nginx
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]