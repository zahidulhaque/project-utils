import requests
from openai import OpenAI
import streamlit as st


def get_public_ip():
    try:
        response = requests.get("https://ifconfig.me", timeout=5)
        response.raise_for_status()
        return response.text.strip()
    except requests.RequestException as e:
        st.error(f"Failed to get public IP: {e}")
        return None
    
public_ip = get_public_ip()
print(f"Public IP: {public_ip}")
if not public_ip:
    st.stop()

# Replace below with actual URL and API Key
BASE_URL = f"http://{public_ip}:8000/v1"
API_KEY="my-dummy-key"

st.title("Conversational AI")

client = OpenAI(api_key=API_KEY, base_url=BASE_URL)

# Extract the model name
models = client.models.list()
modelname = models.data[0].id

if "messages" not in st.session_state:
    st.session_state.messages = []

for message in st.session_state.messages:
    with st.chat_message(message["role"]):
        st.markdown(message["content"])

if prompt := st.chat_input("What is up?"):
    st.session_state.messages.append({"role": "user", "content": prompt})
    with st.chat_message("user"):
        st.markdown(prompt)

    with st.chat_message("assistant"):
        stream = client.chat.completions.create(
            model=modelname,
            messages=[
                {"role": m["role"], "content": m["content"]}
                for m in st.session_state.messages
            ],
            stream=True,
        )
        response = st.write_stream(stream)
    st.session_state.messages.append({"role": "assistant", "content": response})
