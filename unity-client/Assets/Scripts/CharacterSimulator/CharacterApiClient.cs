using System;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using UnityEngine;
using UnityEngine.Networking;

namespace AIGCCharacterSimulator.Client
{
    public class CharacterApiClient : MonoBehaviour
    {
        [SerializeField]
        private string baseUrl = "http://127.0.0.1:8000";

        public string BaseUrl
        {
            get { return baseUrl; }
            set { baseUrl = NormalizeBaseUrl(value); }
        }

        private void Awake()
        {
            baseUrl = NormalizeBaseUrl(baseUrl);
        }

        public IEnumerator GetHealth(Action<HealthResponse> onSuccess, Action<string> onError)
        {
            using (UnityWebRequest request = UnityWebRequest.Get(BuildUrl("health")))
            {
                request.downloadHandler = new DownloadHandlerBuffer();
                yield return request.SendWebRequest();

                if (HasError(request))
                {
                    onError?.Invoke(FormatError(request));
                    yield break;
                }

                HealthResponse response = JsonUtility.FromJson<HealthResponse>(request.downloadHandler.text);
                if (response == null)
                {
                    onError?.Invoke("Failed to parse health response.");
                    yield break;
                }

                onSuccess?.Invoke(response);
            }
        }

        public IEnumerator GetCharacters(Action<List<CharacterDto>> onSuccess, Action<string> onError)
        {
            using (UnityWebRequest request = UnityWebRequest.Get(BuildUrl("characters")))
            {
                request.downloadHandler = new DownloadHandlerBuffer();
                yield return request.SendWebRequest();

                if (HasError(request))
                {
                    onError?.Invoke(FormatError(request));
                    yield break;
                }

                CharacterDto[] items = JsonHelper.FromJsonArray<CharacterDto>(request.downloadHandler.text);
                onSuccess?.Invoke(new List<CharacterDto>(items));
            }
        }

        public IEnumerator GetCharacter(int characterId, Action<CharacterDto> onSuccess, Action<string> onError)
        {
            using (UnityWebRequest request = UnityWebRequest.Get(BuildUrl("characters/" + characterId)))
            {
                request.downloadHandler = new DownloadHandlerBuffer();
                yield return request.SendWebRequest();

                if (HasError(request))
                {
                    onError?.Invoke(FormatError(request));
                    yield break;
                }

                CharacterDto character = JsonUtility.FromJson<CharacterDto>(request.downloadHandler.text);
                if (character == null)
                {
                    onError?.Invoke("Failed to parse character response.");
                    yield break;
                }

                onSuccess?.Invoke(character);
            }
        }

        public IEnumerator CreateCharacter(CharacterCreateRequest payload, Action<CharacterDto> onSuccess, Action<string> onError)
        {
            string json = JsonUtility.ToJson(payload);
            byte[] bodyRaw = Encoding.UTF8.GetBytes(json);

            using (UnityWebRequest request = new UnityWebRequest(BuildUrl("characters"), "POST"))
            {
                request.uploadHandler = new UploadHandlerRaw(bodyRaw);
                request.downloadHandler = new DownloadHandlerBuffer();
                request.SetRequestHeader("Content-Type", "application/json");
                request.SetRequestHeader("Accept", "application/json");

                yield return request.SendWebRequest();

                if (HasError(request))
                {
                    onError?.Invoke(FormatError(request));
                    yield break;
                }

                CharacterDto character = JsonUtility.FromJson<CharacterDto>(request.downloadHandler.text);
                if (character == null)
                {
                    onError?.Invoke("Failed to parse create character response.");
                    yield break;
                }

                onSuccess?.Invoke(character);
            }
        }

        public IEnumerator GetMessages(int characterId, int limit, Action<List<MessageDto>> onSuccess, Action<string> onError)
        {
            string path = "characters/" + characterId + "/messages?limit=" + Mathf.Clamp(limit, 1, 200);
            using (UnityWebRequest request = UnityWebRequest.Get(BuildUrl(path)))
            {
                request.downloadHandler = new DownloadHandlerBuffer();
                yield return request.SendWebRequest();

                if (HasError(request))
                {
                    onError?.Invoke(FormatError(request));
                    yield break;
                }

                MessageDto[] items = JsonHelper.FromJsonArray<MessageDto>(request.downloadHandler.text);
                onSuccess?.Invoke(new List<MessageDto>(items));
            }
        }

        public IEnumerator GetMemories(int characterId, int limit, Action<List<MemoryDto>> onSuccess, Action<string> onError)
        {
            string path = "characters/" + characterId + "/memories?limit=" + Mathf.Clamp(limit, 1, 200);
            using (UnityWebRequest request = UnityWebRequest.Get(BuildUrl(path)))
            {
                request.downloadHandler = new DownloadHandlerBuffer();
                yield return request.SendWebRequest();

                if (HasError(request))
                {
                    onError?.Invoke(FormatError(request));
                    yield break;
                }

                MemoryDto[] items = JsonHelper.FromJsonArray<MemoryDto>(request.downloadHandler.text);
                onSuccess?.Invoke(new List<MemoryDto>(items));
            }
        }

        public IEnumerator Chat(int characterId, ChatRequest payload, Action<ChatResponse> onSuccess, Action<string> onError)
        {
            string json = JsonUtility.ToJson(payload);
            byte[] bodyRaw = Encoding.UTF8.GetBytes(json);

            using (UnityWebRequest request = new UnityWebRequest(BuildUrl("characters/" + characterId + "/chat"), "POST"))
            {
                request.uploadHandler = new UploadHandlerRaw(bodyRaw);
                request.downloadHandler = new DownloadHandlerBuffer();
                request.SetRequestHeader("Content-Type", "application/json");
                request.SetRequestHeader("Accept", "application/json");

                yield return request.SendWebRequest();

                if (HasError(request))
                {
                    onError?.Invoke(FormatError(request));
                    yield break;
                }

                ChatResponse response = JsonUtility.FromJson<ChatResponse>(request.downloadHandler.text);
                if (response == null)
                {
                    onError?.Invoke("Failed to parse chat response.");
                    yield break;
                }

                onSuccess?.Invoke(response);
            }
        }

        private string BuildUrl(string path)
        {
            string normalizedPath = path.StartsWith("/") ? path.Substring(1) : path;
            return NormalizeBaseUrl(baseUrl) + "/" + normalizedPath;
        }

        private static string NormalizeBaseUrl(string value)
        {
            if (string.IsNullOrEmpty(value))
            {
                return "http://127.0.0.1:8000";
            }

            return value.Trim().TrimEnd('/');
        }

        private static bool HasError(UnityWebRequest request)
        {
#if UNITY_2020_2_OR_NEWER
            return request.result != UnityWebRequest.Result.Success;
#else
            return request.isNetworkError || request.isHttpError;
#endif
        }

        private static string FormatError(UnityWebRequest request)
        {
            string body = request.downloadHandler != null ? request.downloadHandler.text : string.Empty;
            if (string.IsNullOrEmpty(body))
            {
                return request.error;
            }

            return request.error + " | " + body;
        }
    }
}

