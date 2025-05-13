from fastapi import FastAPI, File, UploadFile, Form, HTTPException, Depends
from fastapi.responses import StreamingResponse, JSONResponse,HTMLResponse
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from fastapi import Request
import io
import base64
import random
from PIL import Image
import sqlite3
import hashlib
import uuid

app = FastAPI()
from fastapi.templating import Jinja2Templates
from fastapi.requests import Request
from fastapi.staticfiles import StaticFiles

app.mount("/static", StaticFiles(directory="static"), name="static")
templates = Jinja2Templates(directory="templates")

@app.get("/")
def read_root(request: Request):
    return templates.TemplateResponse("test.html", {"request": request})
from fastapi.middleware.cors import CORSMiddleware

# Allow all origins (or specify your frontend URL)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # You can set a specific URL for security purposes
    allow_credentials=True,
    allow_methods=["*"],  # Allow all methods (GET, POST, etc.)
    allow_headers=["*"],  # Allow all headers
)


oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# --- Database Setup ---
conn = sqlite3.connect("steganography.db", check_same_thread=False)
c = conn.cursor()

c.execute('''CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    username TEXT UNIQUE,
    password_hash TEXT
)''')

c.execute('''CREATE TABLE IF NOT EXISTS actions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT,
    action_type TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
)''')
c.execute('''CREATE TABLE IF NOT EXISTS messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    sender_id TEXT,
    recipient_id TEXT,
    message_type TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
)''')
conn.commit()

# --- Utility Functions ---
def hash_password(password: str) -> str:
    return hashlib.sha256(password.encode()).hexdigest()

def get_user_by_token(token: str):
    c.execute("SELECT id FROM users WHERE id = ?", (token,))
    user = c.fetchone()
    if not user:
        raise HTTPException(status_code=401, detail="Invalid token")
    return user[0]

def get_user_by_username(username: str) -> str:
    c.execute("SELECT id FROM users WHERE username = ?", (username,))
    user = c.fetchone()
    if not user:
        raise HTTPException(status_code=404, detail="Recipient username not found")
    return user[0]

def log_action(user_id: str, action_type: str):
    c.execute("INSERT INTO actions (user_id, action_type) VALUES (?, ?)", (user_id, action_type))
    conn.commit()

def log_message(sender_id: str, recipient_id: str, message_type: str):
    c.execute("INSERT INTO messages (sender_id, recipient_id, message_type) VALUES (?, ?, ?)",
              (sender_id, recipient_id, message_type))
    conn.commit()

# --- Text Encoding/Decoding ---
def text_to_bin(text: str) -> str:
    return ''.join(format(ord(char), '08b') for char in text)

def bin_to_text(binary: str) -> str:
    return ''.join(chr(int(binary[i:i+8], 2)) for i in range(0, len(binary), 8))

def int_to_bin(value: int, bits: int = 8) -> str:
    return format(value, f'0{bits}b')

def bin_to_int(binary: str) -> int:
    return int(binary, 2)

def bytesio_to_base64_str(bytes_io: io.BytesIO) -> str:
    bytes_io.seek(0)
    return base64.b64encode(bytes_io.read()).decode('utf-8')

# --- Text Steganography ---
def hide_text_in_image(image_stream: io.BytesIO, text: str) -> io.BytesIO:
    img = Image.open(image_stream).convert('RGB')
    binary_text = text_to_bin(text) + '1111111111111110'
    binary_index = 0
    pixels = img.load()

    for y in range(img.height):
        for x in range(img.width):
            if binary_index >= len(binary_text):
                break

            r, g, b = pixels[x, y]
            r = (r & ~1) | int(binary_text[binary_index]); binary_index += 1
            if binary_index < len(binary_text):
                g = (g & ~1) | int(binary_text[binary_index]); binary_index += 1
            if binary_index < len(binary_text):
                b = (b & ~1) | int(binary_text[binary_index]); binary_index += 1

            pixels[x, y] = (r, g, b)
        if binary_index >= len(binary_text):
            break

    output = io.BytesIO()
    img.save(output, format='PNG')
    output.seek(0)
    return output


def bin_to_text(binary_data: str) -> str:
    chars = [binary_data[i:i+8] for i in range(0, len(binary_data), 8)]
    return ''.join([chr(int(b, 2)) for b in chars if len(b) == 8])

def extract_text_from_image(image_stream: io.BytesIO) -> str:
    image_stream.seek(0)  # Important!
    img = Image.open(image_stream).convert('RGB')
    pixels = img.load()
    binary_data = ''

    for y in range(img.height):
        for x in range(img.width):
            r, g, b = pixels[x, y]
            binary_data += str(r & 1)
            binary_data += str(g & 1)
            binary_data += str(b & 1)

            if '1111111111111110' in binary_data:
                binary_data = binary_data[:binary_data.index('1111111111111110')]
                return bin_to_text(binary_data)

    return "No hidden text found"


# --- Image Steganography ---
def hide_image_in_image(cover_stream: io.BytesIO, secret_stream: io.BytesIO, seed: int = 42) -> io.BytesIO:
    cover_img = Image.open(cover_stream).convert('RGB')
    secret_img = Image.open(secret_stream).convert('RGB')
    cover_pixels = cover_img.load()
    secret_pixels = secret_img.load()
    cover_w, cover_h = cover_img.size
    secret_w, secret_h = secret_img.size

    # Check if the cover image is large enough to hide the secret image
    if cover_w * cover_h < secret_w * secret_h:
        raise ValueError("Cover image is too small to hide the secret image.")

    cover_pixels[0, 0] = (secret_w // 256, secret_w % 256, cover_pixels[0, 0][2])
    cover_pixels[0, 1] = (secret_h // 256, secret_h % 256, cover_pixels[0, 1][2])

    random.seed(seed)
    slots = [(x, y) for y in range(2, cover_h) for x in range(cover_w)]
    chosen = random.sample(slots, secret_w * secret_h)

    for idx, (x, y) in enumerate(chosen):
        sx = idx % secret_w
        sy = idx // secret_w
        r, g, b = cover_pixels[x, y]
        sr, sg, sb = secret_pixels[sx, sy]
        new_r = int_to_bin(r)[:-4] + int_to_bin(sr)[:4]
        new_g = int_to_bin(g)[:-4] + int_to_bin(sg)[:4]
        new_b = int_to_bin(b)[:-4] + int_to_bin(sb)[:4]
        cover_pixels[x, y] = (bin_to_int(new_r), bin_to_int(new_g), bin_to_int(new_b))

    output = io.BytesIO()
    cover_img.save(output, format='PNG')
    output.seek(0)
    return output

def extract_image_from_image(stego_stream: io.BytesIO, seed: int = 42) -> io.BytesIO:
    img = Image.open(stego_stream).convert('RGB')
    pixels = img.load()
    w, h = img.size

    sw = pixels[0,0][0] * 256 + pixels[0,0][1]
    sh = pixels[0,1][0] * 256 + pixels[0,1][1]

    random.seed(seed)
    slots = [(x, y) for y in range(2, h) for x in range(w)]
    chosen = random.sample(slots, sw * sh)

    secret_img = Image.new('RGB', (sw, sh))
    secret_pixels = secret_img.load()

    for idx, (x, y) in enumerate(chosen):
        sx = idx % sw
        sy = idx // sw
        r, g, b = pixels[x, y]
        sr = bin_to_int(int_to_bin(r)[-4:] + '0000')
        sg = bin_to_int(int_to_bin(g)[-4:] + '0000')
        sb = bin_to_int(int_to_bin(b)[-4:] + '0000')
        secret_pixels[sx, sy] = (sr, sg, sb)

    output = io.BytesIO()
    secret_img.save(output, format='PNG')
    output.seek(0)
    return output

# --- Auth Endpoints ---
@app.post("/signup")
async def signup(username: str = Form(...), password: str = Form(...)):
    user_id = str(uuid.uuid4())
    try:
        c.execute("INSERT INTO users (id, username, password_hash) VALUES (?, ?, ?)",
                  (user_id, username, hash_password(password)))
        conn.commit()
    except sqlite3.IntegrityError:
        raise HTTPException(sxtatus_code=400, detail="Username already exists")
    return {"token": user_id}

@app.post("/token")
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
    c.execute("SELECT id, password_hash FROM users WHERE username = ?", (form_data.username,))
    result = c.fetchone()
    if not result or result[1] != hash_password(form_data.password):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    return {"access_token": result[0], "token_type": "bearer"}

# --- User Stats ---
@app.get("/user-stats")
async def get_stats(token: str = Depends(oauth2_scheme)):
    user_id = get_user_by_token(token)
    
    # Get username
    c.execute("SELECT username FROM users WHERE id = ?", (user_id,))
    result = c.fetchone()
    username = result[0] if result else "Unknown User"

    # Count each action type
    action_types = ["hide_text", "extract_text", "hide_image", "extract_image"]
    stats = {"username": username}
    
    for action in action_types:
        c.execute(
            "SELECT COUNT(*) FROM actions WHERE user_id = ? AND action_type = ?",
            (user_id, action)
        )
        stats[action] = c.fetchone()[0]

    return stats

# --- API Endpoints ---
@app.post("/hide-text")
async def hide_text(image: UploadFile = File(...), text: str = Form(...), token: str = Depends(oauth2_scheme)):
    user_id = get_user_by_token(token)
    image_bytes = await image.read()
    output = hide_text_in_image(io.BytesIO(image_bytes), text)
    log_action(user_id, "hide_text")
    return StreamingResponse(output, media_type="image/png", headers={"Content-Disposition": "attachment; filename=stego.png"})

@app.post("/extract-text")
async def extract_text(image: UploadFile = File(...), token: str = Depends(oauth2_scheme)):
    user_id = get_user_by_token(token)
    image_bytes = await image.read()
    hidden_text = extract_text_from_image(io.BytesIO(image_bytes))
    log_action(user_id, "extract_text")
    return JSONResponse(content={"extracted_text": hidden_text})

@app.post("/hide-image")
async def hide_image_api(cover: UploadFile = File(...), secret: UploadFile = File(...), token: str = Depends(oauth2_scheme)):
    user_id = get_user_by_token(token)
    cover_bytes = await cover.read()
    secret_bytes = await secret.read()
    output = hide_image_in_image(io.BytesIO(cover_bytes), io.BytesIO(secret_bytes))
    log_action(user_id, "hide_image")
    return StreamingResponse(output, media_type="image/png", headers={"Content-Disposition": "attachment; filename=stego.png"})

@app.post("/extract-image")
async def extract_image_api(stego: UploadFile = File(...), token: str = Depends(oauth2_scheme)):
    user_id = get_user_by_token(token)
    stego_bytes = await stego.read()
    output = extract_image_from_image(io.BytesIO(stego_bytes))
    log_action(user_id, "extract_image")
    return StreamingResponse(output, media_type="image/png", headers={"Content-Disposition": "attachment; filename=extracted.png"})

@app.post("/send-image")
async def send_image(recipient_username: str = Form(...), message_type: str = Form(...), token: str = Depends(oauth2_scheme)):
    user_id = get_user_by_token(token)
    recipient_id = get_user_by_username(recipient_username)
    
    # Log the message
    log_message(user_id, recipient_id, message_type)
    
    return {"detail": f"Image successfully sent to {recipient_username}"}

@app.get("/messages")
async def get_messages(token: str = Depends(oauth2_scheme)):
    user_id = get_user_by_token(token)
    
    # Fetch sent messages
    c.execute("SELECT recipient_id, message_type, timestamp FROM messages WHERE sender_id = ?", (user_id,))
    sent_messages = [{"recipient_id": row[0], "message_type": row[1], "timestamp": row[2]} for row in c.fetchall()]
    
    # Fetch received messages
    c.execute("SELECT sender_id, message_type, timestamp FROM messages WHERE recipient_id = ?", (user_id,))
    received_messages = [{"sender_id": row[0], "message_type": row[1], "timestamp": row[2]} for row in c.fetchall()]
    
    return {"sent_messages": sent_messages, "received_messages": received_messages}

@app.get("/available-users")
async def available_users(prefix: str = ""):
    # Fetch all users and filter by prefix
    query = "SELECT username FROM users WHERE username LIKE ?"
    c.execute(query, (f"{prefix}%",))
    users = [{"username": row[0]} for row in c.fetchall()]
    
    return {"available_users": users}
