# Dockerfile
FROM python:3.9-slim

# Set the working directory
WORKDIR /app

# Copy the application files
COPY app.py /app
COPY templates /app/templates

# Install Flask
RUN pip install Flask

# Set the environment variable for Flask
ENV FLASK_APP=app.py

# Expose the port
EXPOSE 5000

# Run the application
CMD ["python", "app.py"]
