import requests
from datetime import datetime
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from motor.motor_asyncio import AsyncIOMotorClient

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

MONGO_DETAILS = "mongodb://localhost:27017"
client = AsyncIOMotorClient(MONGO_DETAILS)
db = client.jarvis_db                    

chats_collection = db.get_collection("chats")  
auth_collection = db.get_collection("auth_logs")

class ChatMessage(BaseModel):
    user_id: str
    user_message: str

class SimpleLoginRequest(BaseModel):
    phone: str

RAPIDAPI_KEY = "e02488f70cmsh518b0ecd4f34528p109c34jsnec383fbb459b"
NEW_FLUX_HOST = "flux-api-4-custom-models-100-style.p.rapidapi.com"

@app.post("/api/chat")
async def chat_with_jarvis(data: ChatMessage):
    user_prompt = data.user_message.lower().strip()
    jarvis_reply = ""
    msg_type = "text"
    status_code = 200
    
    # 🎨 IMAGE GENERATION TRIGGER (Naya Provider Integration with Job ID Polling)
    if any(word in user_prompt for word in ["generate", "create", "draw", "make image", "paint", "show me"]):
        flux_create_url = f"https://{NEW_FLUX_HOST}/create-v28"
        
        flux_payload = {
            "prompt": data.user_message,
            "style": "Cinematic",
            "aspect_ratio": "1:1"
        }
        
        flux_headers = {
            "x-rapidapi-key": RAPIDAPI_KEY,
            "x-rapidapi-host": NEW_FLUX_HOST,
            "Content-Type": "application/json"
        }
        
        try:
            # Step 1: Request Image Creation
            response = requests.post(flux_create_url, json=flux_payload, headers=flux_headers, timeout=30)
            status_code = response.status_code
            
            if response.status_code == 200:
                api_res = response.json()
                
                print(f"=== NAYA API INITIAL RESPONSE: {api_res} ===")
                image_url = api_res.get("url") or api_res.get("image_url")
                job_id = api_res.get("jobId")
                
                # Step 2: Polling Using Job ID
                if not image_url and job_id:
                    status_url = f"https://{NEW_FLUX_HOST}/create-v28/status"
                    
                    import time
                    for attempt in range(5):
                        print(f"--- Checking Image Status (Attempt {attempt + 1})... ---")
                        time.sleep(3)  # 3 seconds ka pause takay server response ready karle
                        
                        status_res = requests.get(status_url, headers=flux_headers, params={"id": job_id}, timeout=15)
                        if status_res.status_code == 200:
                            status_data = status_res.json()
                            print(f"=== STATUS RESPONSE: {status_data} ===")
                            
                            # 🎯 EXACT FIX: data -> urls -> list ka pehla element
                            status_inner_data = status_data.get("data")
                            if status_inner_data and isinstance(status_inner_data, dict):
                                urls_list = status_inner_data.get("urls")
                                if urls_list and isinstance(urls_list, list) and len(urls_list) > 0:
                                    image_url = urls_list[0]  # Extraction Successful!
                            
                            if image_url:
                                print(f"--- [SUCCESS] Image Extracted: {image_url} ---")
                                break
                                
                            if status_data.get("status") == "failed":
                                jarvis_reply = "Sir, the neural generation job failed on the remote server."
                                break
                
                if image_url:
                    jarvis_reply = image_url
                    msg_type = "image"
                else:
                    jarvis_reply = "Sir, the image creation job is taking longer than expected. Please try querying again in a moment."
                    msg_type = "text"
            else:
                jarvis_reply = f"Flux tactical mainframe returned an error, sir. Status: {response.status_code}"
                msg_type = "text"
                
        except Exception as e:
            jarvis_reply = f"Image generation core failure, sir. Error: {str(e)}"
            msg_type = "text"

    # 💬 TEXT CHAT (GPT-4)
    else:
        gpt_url = "https://chatgpt-42.p.rapidapi.com/conversationgpt4-2"    
        gpt_payload = {
            "messages": [{"role": "user", "content": data.user_message}],
            "system_prompt": "You are Jarvis, the legendary AI assistant from Iron Man. You were built by SSARZ. Keep responses crisp, highly intelligent, and always address the user as 'sir'.",
            "temperature": 0.8,
            "top_k": 5,
            "top_p": 0.9,
            "max_tokens": 256,
            "web_access": False
        }
        gpt_headers = {
            "x-rapidapi-key": RAPIDAPI_KEY,
            "x-rapidapi-host": "chatgpt-42.p.rapidapi.com",
            "Content-Type": "application/json"
        }
        
        try:
            response = requests.post(gpt_url, json=gpt_payload, headers=gpt_headers)
            status_code = response.status_code
            if response.status_code == 200:
                api_res = response.json()
                jarvis_reply = api_res.get("result", "Systems are operational, sir, but response parsing failed.")
            else:
                jarvis_reply = "I am unable to access my satellite servers at the moment, sir."            
        except Exception as e:
            jarvis_reply = f"Critical connection failure, sir. Error: {str(e)}"
        msg_type = "text"

    # MongoDB Logging
    document = {
        "user_id": data.user_id,
        "timestamp": datetime.utcnow(),
        "user_prompt": data.user_message,
        "jarvis_response": jarvis_reply,
        "metadata": {
            "type": msg_type,
            "status_code": status_code
        }
    }
    await chats_collection.insert_one(document)
    return {"status": "success", "type": msg_type, "reply": jarvis_reply}

@app.post("/api/verify-otp")
async def direct_login(data: SimpleLoginRequest):
    log_document = {"phone": data.phone.strip(), "action": "DIRECT_ACCESS_GRANTED", "timestamp": datetime.utcnow()}
    await auth_collection.insert_one(log_document)
    return {"status": "success", "message": "Access granted, sir."}