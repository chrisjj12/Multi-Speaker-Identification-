from flask import Flask, render_template
app = Flask(__name__, template_folder="Templates")
    

@app.route('/')
def dsp():
    return render_template("main.html")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)