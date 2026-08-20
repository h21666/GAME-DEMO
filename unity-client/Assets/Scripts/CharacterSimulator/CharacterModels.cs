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

    [Serializable]
    public class TextProviderConfigRead
    {
        public string provider_name;
        public bool api_key_present;
        public string base_url;
        public string model;
        public float temperature;
        public int max_tokens;
        public bool thinking_enabled;
        public string reasoning_effort;
    }

    [Serializable]
    public class ImageProviderConfigRead
    {
        public string provider_name;
        public bool api_key_present;
        public string base_url;
        public string model;
        public string generation_path;
        public string edit_path;
        public string quality;
        public string size;
        public string background;
        public string input_fidelity;
    }

    [Serializable]
    public class ProviderConfigRead
    {
        public TextProviderConfigRead text;
        public ImageProviderConfigRead image;
    }

    public class ProviderSettingsUpdate
    {
        public string deepseekApiKey;
        public string deepseekBaseUrl;
        public string deepseekModel;
        public string imageApiKey;
        public string imageBaseUrl;
        public string imageModel;
        public string imageSize;
        public string imageQuality;
    }
}
