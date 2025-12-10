#!/usr/bin/env python3
from flask import Flask, request, jsonify, abort
import os
import hashlib
import yaml

app = Flask(__name__)

BASE_DIR = "/opt/terraform-state-server"
STATE_DIR = os.path.join(BASE_DIR, "states")
LOCK_DIR  = os.path.join(BASE_DIR, "locks")

CONFIG = yaml.safe_load(open(os.path.join(BASE_DIR, "config.yaml")))

def check_auth(req):
    if not CONFIG.get("auth"):
        return True
    user = req.headers.get("X-Auth-User")
    passwd = req.headers.get("X-Auth-Password")
    return user == CONFIG["auth"]["user"] and passwd == CONFIG["auth"]["password"]

@app.before_request
def authenticate():
    if not check_auth(request):
        abort(401)

@app.route("/terraform_state/<path:key>", methods=["GET"])
def get_state(key):
    state_file = os.path.join(STATE_DIR, key)
    if not os.path.exists(state_file):
        abort(404)
    with open(state_file, "rb") as f:
        return f.read(), 200, {"Content-Type": "application/json"}

@app.route("/terraform_state/<path:key>", methods=["POST"])
def write_state(key):
    state_file = os.path.join(STATE_DIR, key)
    data = request.data
    with open(state_file, "wb") as f:
        f.write(data)
    return "OK", 200

@app.route("/terraform_lock/<path:key>", methods=["PUT"])
def lock_state(key):
    lock_file = os.path.join(LOCK_DIR, f"{key}.lock")
    if os.path.exists(lock_file):
        abort(423)  # Lock already exists
    with open(lock_file, "wb") as f:
        f.write(request.data)
    return "LOCKED", 200

@app.route("/terraform_lock/<path:key>", methods=["DELETE"])
def unlock_state(key):
    lock_file = os.path.join(LOCK_DIR, f"{key}.lock")
    if not os.path.exists(lock_file):
        abort(404)
    os.remove(lock_file)
    return "UNLOCKED", 200

if __name__ == "__main__":
    app.run(host=CONFIG["server"]["host"], port=CONFIG["server"]["port"])
