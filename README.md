# 🤖 Jarvis AI Assistant

An AI-powered virtual assistant built using Flutter, FastAPI, and MongoDB.
It supports chat, voice interaction, AI responses, image generation, and persistent chat history storage.

---

## 🚀 Features

* 💬 AI Chat Assistant
* 🎤 Voice Input (Speech Recognition)
* 🔊 Text-to-Speech Response
* 🖼️ AI Image Generation
* 🗂️ Chat History Storage (MongoDB)
* ⚡ Fast API Backend (FastAPI)
* 📱 Cross-platform UI (Flutter Web + Mobile)

---

## 🛠️ Tech Stack

* **Frontend:** Flutter (Dart)
* **Backend:** FastAPI (Python)
* **Database:** MongoDB
* **AI APIs:** GPT / Image Generation APIs
* **Other:** REST APIs, JSON, Speech Services

---

## 📁 Project Structure

```
Jarvis AI Assistant/
│
├── jarvis_app/          # Flutter Frontend
├── main.py              # FastAPI Backend Entry
├── requirements.txt     # Python dependencies
└── README.md
```

---

## ⚙️ Installation & Setup

### 1. Clone Repository

```bash
git clone https://github.com/USERNAME/jarvis-ai-assistant.git
cd jarvis-ai-assistant
```

---

### 2. Backend Setup

```bash
pip install fastapi uvicorn motor requests pydantic
uvicorn main:app --reload
```

Backend runs on:

```
http://127.0.0.1:8000
```

---

### 3. Frontend Setup (Flutter)

```bash
cd jarvis_app
flutter pub get
flutter run -d chrome
```

---

## 🔄 System Architecture

```
User
 ↓
Flutter UI
 ↓
FastAPI Backend
 ↓
AI API (GPT / Image)
 ↓
MongoDB Database
 ↓
Response to UI
```

---

## 🧠 Database Design

### Collections:

* `chats_collection`
* `auth_collection`

### Stored Data:

* User messages
* AI responses
* Timestamps
* Authentication logs

---

## 📌 DBMS Concepts Used

* Collections (Tables equivalent)
* Documents (Rows equivalent)
* CRUD Operations
* Data Persistence
* NoSQL Database Design

---

## 🎯 Purpose of Project

This project demonstrates a real-world AI assistant system combining:

* Database management
* API integration
* AI interaction
* Cross-platform UI development

---

## 👨‍💻 Author

**Hafiz Zubair**

---

## ⭐ Future Improvements

* Real authentication system (JWT)
* Cloud database integration
* Mobile app optimization
* Conversation memory enhancement
