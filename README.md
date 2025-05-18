

# Secure_Talks🔐

A fully working **secure communication application** combining **FastAPI**, **SQLite**, and **Steganography** with a **Flutter-based mobile frontend**. The system allows users to hide messages inside images (via steganography), manage user data securely, and access the service through a mobile application.

---

## 🌟 Key Features

* 🔐 **Secure Messaging**: Send and receive messages hidden within images using steganography.
* 🧑‍💻 **User Management**: User registration, login, and authentication.
* 🧠 **FastAPI + SQLite**: Lightweight backend built on FastAPI, with local SQLite databases.
* 📱 **Flutter Mobile Application**: Cross-platform frontend for accessing the backend functionality.
* 🌍 **Hosted API Server**: Backend is deployed online, making it accessible to the mobile app.

---

## 📁 Project Structure

```
taha_project/
│
├── api.py                   # FastAPI application (entry point)
├── db_processor.py          # Handles user and message database operations
├── stego_utils.py           # Encoding/decoding messages in images
├── users.db                 # SQLite DB for user credentials
├── steganography.db         # SQLite DB for message/image records
│
├── templates/               # HTML templates (for basic testing, optional)
│   └── index.html
│
├── SecureTalk-Files/        # Supporting components/resources
│
├── MOBILE_VIRJIN/           # Flutter mobile app source
│   ├── lib/
│   ├── android/
│   └── ...
│
├── requirements.txt         # Python backend dependencies
└── README.md                # This file
```

---

## 💡 Technologies Used

| Layer      | Tech Stack                         |
| ---------- | ---------------------------------- |
| Backend    | Python, FastAPI, SQLite            |
| Mobile App | Flutter, Dart                      |
| Security   | Steganography (via Pillow)         |
| Hosting    | Your FastAPI backend hosted online |

---

## ⚙️ Backend Setup Instructions

### ✅ Prerequisites

* Python 3.8+
* [Uvicorn](https://www.uvicorn.org/) ASGI server
* Git

### 📦 Install Dependencies

1. Clone the repo:

   ```bash
   git clone https://github.com/Mafia-Deadend/taha_project.git
   cd taha_project
   ```

2. Create a virtual environment (optional but recommended):

   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. Install required packages:

   ```bash
   pip install -r requirements.txt
   ```

4. Run the FastAPI server locally with Uvicorn:

   ```bash
   uvicorn api:app --host 0.0.0.0 --port 8000 --reload
   ```

   This starts your server at: [http://localhost:8000](http://localhost:8000)

> 💡 If you're deploying to a cloud server (like Render, Heroku, or EC2), make sure ports are open and the domain is updated in the mobile app.

---

## 🌐 Hosted API

Your FastAPI backend is **already hosted online**, making it accessible to the Flutter mobile app.
If you’re deploying on a VPS or cloud server, make sure to:

* Allow external HTTP traffic (port 8000 or your custom port).
* Use a reverse proxy (e.g., Nginx) for production deployments.
* Update the mobile app's base URL to point to the server (e.g., `https://yourserver.com/`).

---

## 📱 Running the Flutter Mobile App

1. Navigate to the Flutter project:

   ```bash
   cd MOBILE_VIRJIN/app/secure_talks
   ```

2. Fetch dependencies:

   ```bash
   flutter pub get
   ```

3. Make sure the backend URL in your Flutter code points to your hosted server.

4. Run the app:

   ```bash
   flutter run
   ```

> ✅ Ensure the emulator or device has internet access if you're using the hosted backend.

---

## 🛠 Key Functionalities

* **Register/Login** – Securely authenticate users with hashed passwords.
* **Hide Message in Image** – Encode a message inside an image using steganography.
* **Extract Message from Image** – Retrieve hidden messages from an image.

---

## 🧪 Sample Usage

You can test the backend locally using:

* `http://localhost:8000/docs` – Interactive Swagger UI
* `http://localhost:8000/redoc` – Alternative API docs

---

## 🤝 Contributing

Pull requests and feature suggestions are welcome. Fork the repo, make changes, and submit a PR.

---

## 🪪 License

This project is licensed under the **MIT License**.

---

