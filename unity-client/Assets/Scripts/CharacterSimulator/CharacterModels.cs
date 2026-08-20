using System;

namespace AIGCCharacterSimulator.Client
{
    [Serializable]
    public class CharacterDto
    {
        public int id;
        public string name;
        public string personality;
        public string background;
        public string memory;
        public string created_at;
    }

    [Serializable]
    public class CharacterCreateRequest
    {
        public string name;
        public string personality;
        public string background;
        public string memory;
    }

    [Serializable]
    public class ChatRequest
    {
        public string message;
    }

    [Serializable]
    public class ChatResponse
    {
        public int character_id;
        public string user_message;
        public string reply;
        public bool used_llm;
    }

    [Serializable]
    public class MessageDto
    {
        public int id;
        public int character_id;
        public string role;
        public string content;
        public string created_at;
    }

    [Serializable]
    public class MemoryDto
    {
        public int id;
        public int character_id;
        public string type;
        public string content;
        public int importance;
        public string created_at;
        public string updated_at;
    }

    [Serializable]
    public class HealthResponse
    {
        public string status;
    }
}

