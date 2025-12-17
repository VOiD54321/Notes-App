from flask import Flask, render_template, request, redirect, session
import json, os, uuid, datetime

app = Flask(__name__)
app.secret_key = "offline-secret"

DB = "notes.json"
USER_DB = "user.json"

# ---------- UTIL ----------
def load_json(file, default):
    if not os.path.exists(file):
        return default
    with open(file, "r") as f:
        content = f.read().strip()
        return json.loads(content) if content else default

def save_json(file, data):
    with open(file, "w") as f:
        json.dump(data, f, indent=2)

# ---------- AUTH ----------
@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        user = load_json(USER_DB, {})
        if not user:
            user = {
                "email": request.form["email"],
                "password": request.form["password"]
            }
            save_json(USER_DB, user)

        if (request.form["email"] == user["email"] and
                request.form["password"] == user["password"]):
            session["user"] = user["email"]
            return redirect("/")
    return render_template("login.html")

@app.route("/logout")
def logout():
    session.clear()
    return redirect("/login")

# ---------- NOTES ----------
@app.route("/")
def index():
    if "user" not in session:
        return redirect("/login")

    notes = load_json(DB, [])
    q = request.args.get("q", "").lower()
    if q:
        notes = [n for n in notes if q in n["title"].lower() or q in n["content"].lower()]

    return render_template("index.html", notes=notes)

@app.route("/add", methods=["POST"])
def add():
    notes = load_json(DB, [])
    notes.append({
        "id": str(uuid.uuid4()),
        "title": request.form["title"],
        "content": request.form["content"],
        "time": str(datetime.datetime.now())
    })
    save_json(DB, notes)
    return redirect("/")

@app.route("/edit/<id>", methods=["POST"])
def edit(id):
    notes = load_json(DB, [])
    for n in notes:
        if n["id"] == id:
            n["title"] = request.form["title"]
            n["content"] = request.form["content"]
    save_json(DB, notes)
    return redirect("/")

@app.route("/delete/<id>")
def delete(id):
    notes = load_json(DB, [])
    notes = [n for n in notes if n["id"] != id]
    save_json(DB, notes)
    return redirect("/")

if __name__ == "__main__":
    app.run(debug=True)
