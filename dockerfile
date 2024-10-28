# Dockerfile
FROM nginx:alpine
# Copy the HTML files into the Nginx web directory
COPY ./app /usr/share/nginx/html

# Expose port 80 to allow external access to the container
EXPOSE 80

# Start the Nginx server
CMD ["nginx", "-g", "daemon off;"]