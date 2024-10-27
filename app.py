# app.py
from flask import Flask, render_template
import socket
import os

app = Flask(__name__)

# Set a version number
VERSION = "1.0"

# Determine the hostname suffix based on an environment variable
instance_number = os.getenv("INSTANCE_NUMBER", "01")  # Default to "01" if not set
hostname = f"Node-{instance_number}"

@app.route("/")
def home():
    return render_template("index.html", hostname=hostname, version=VERSION)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
