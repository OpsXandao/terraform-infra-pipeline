from flask import Flask, render_template_string
import socket

app = Flask(__name__)

@app.route("/")
def index():
    color = "Verde"
    server = socket.gethostname()
    html = f"""
    <html>
        <head>
            <title>Cor do Fundo</title>
        </head>
        <body style="background-color: green; color: white; text-align: center; padding: 50px;">
            <h1>A cor de fundo é: {color}</h1>
        </body>
    </html>
    """
    return render_template_string(html)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
