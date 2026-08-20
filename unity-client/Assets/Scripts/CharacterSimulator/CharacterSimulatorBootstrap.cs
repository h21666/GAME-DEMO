using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace AIGCCharacterSimulator.Client
{
    [RequireComponent(typeof(CharacterApiClient))]
    public class CharacterSimulatorBootstrap : MonoBehaviour
    {
        [SerializeField]
        private string initialBackendUrl = "http://127.0.0.1:8000";

        private CharacterApiClient apiClient;
        private Canvas canvas;

        private GameObject mainMenuRoot;
        private GameObject chatRoot;

        private Text statusText;
        private InputField backendUrlInput;

        private InputField characterNameInput;
        private InputField characterPersonalityInput;
        private InputField characterBackgroundInput;
        private InputField characterMemoryInput;

        private Transform characterListContent;
        private Text selectedCharacterPreviewText;
        private Button openChatButton;
        private Text emptyCharacterListText;

        private Text activeCharacterNameText;
        private Text activeCharacterProfileText;
        private Transform memoryListContent;
        private Transform messageListContent;
        private ScrollRect messageScrollRect;
        private InputField chatInput;
        private Button sendButton;
        private Button backButton;

        private List<CharacterDto> characters = new List<CharacterDto>();
        private CharacterDto selectedCharacter;

        private void Awake()
        {
            EnsureEventSystem();
            apiClient = GetComponent<CharacterApiClient>();
            apiClient.BaseUrl = initialBackendUrl;
            BuildCanvas();
            BuildMainMenu();
            BuildChatPanel();
            ShowMainMenu();
        }

        private void Start()
        {
            if (backendUrlInput != null)
            {
                backendUrlInput.text = initialBackendUrl;
            }

            ConnectAndLoadCharacters();
        }

        private void Update()
        {
            if (!chatRoot.activeSelf)
            {
                return;
            }

            if (chatInput != null && chatInput.isFocused && Input.GetKeyDown(KeyCode.Return))
            {
                SendChatMessage();
            }
        }

        private void BuildCanvas()
        {
            GameObject canvasObject = new GameObject("AIGCCharacterCanvas", typeof(RectTransform), typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
            canvas = canvasObject.GetComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;

            CanvasScaler scaler = canvasObject.GetComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1600f, 900f);
            scaler.screenMatchMode = CanvasScaler.ScreenMatchMode.MatchWidthOrHeight;
            scaler.matchWidthOrHeight = 0.5f;

            canvasObject.transform.SetParent(transform, false);
        }

        private void BuildMainMenu()
        {
            mainMenuRoot = UiFactory.CreateRoot("MainMenuRoot", canvas.transform);
            Image rootBackground = mainMenuRoot.AddComponent<Image>();
            rootBackground.color = new Color(0.07f, 0.09f, 0.12f, 1f);
            UiFactory.CreateVerticalLayout(mainMenuRoot.transform, 16, new RectOffset(24, 24, 24, 24));

            GameObject header = UiFactory.CreateCard("Header", mainMenuRoot.transform, new Color(0.12f, 0.14f, 0.19f, 1f));
            LayoutElement headerLayout = header.GetComponent<LayoutElement>();
            headerLayout.preferredHeight = 64f;
            UiFactory.CreateHorizontalLayout(header.transform, 12, new RectOffset(16, 16, 12, 12));

            UiFactory.CreateSectionTitle(header.transform, "AIGC Interactive Character Simulator");
            statusText = UiFactory.CreateMutedText(header.transform, "Connecting...");
            LayoutElement statusLayout = statusText.GetComponent<LayoutElement>();
            statusLayout.flexibleWidth = 1f;
            statusText.alignment = TextAnchor.MiddleRight;

            GameObject body = UiFactory.CreatePanel("MainMenuBody", mainMenuRoot.transform, new Color(0f, 0f, 0f, 0f));
            LayoutElement bodyLayout = body.GetComponent<LayoutElement>();
            bodyLayout.flexibleHeight = 1f;
            UiFactory.CreateHorizontalLayout(body.transform, 16, new RectOffset(0, 0, 0, 0));

            GameObject leftColumn = UiFactory.CreateCard("LeftColumn", body.transform, new Color(0.10f, 0.12f, 0.16f, 1f));
            LayoutElement leftLayout = leftColumn.GetComponent<LayoutElement>();
            leftLayout.preferredWidth = 430f;
            leftLayout.flexibleHeight = 1f;
            UiFactory.CreateVerticalLayout(leftColumn.transform, 14, new RectOffset(16, 16, 16, 16));

            BuildConnectionCard(leftColumn.transform);
            BuildCreateCharacterCard(leftColumn.transform);

            GameObject rightColumn = UiFactory.CreateCard("RightColumn", body.transform, new Color(0.09f, 0.11f, 0.15f, 1f));
            LayoutElement rightLayout = rightColumn.GetComponent<LayoutElement>();
            rightLayout.flexibleWidth = 1f;
            rightLayout.flexibleHeight = 1f;
            UiFactory.CreateVerticalLayout(rightColumn.transform, 14, new RectOffset(16, 16, 16, 16));

            BuildCharacterBrowserCard(rightColumn.transform);
            BuildSelectedCharacterCard(rightColumn.transform);
        }

        private void BuildConnectionCard(Transform parent)
        {
            GameObject card = UiFactory.CreateCard("ConnectionCard", parent, new Color(0.13f, 0.15f, 0.20f, 1f));
            LayoutElement layout = card.GetComponent<LayoutElement>();
            layout.preferredHeight = 150f;
            UiFactory.CreateVerticalLayout(card.transform, 10, new RectOffset(14, 14, 14, 14));

            UiFactory.CreateSectionTitle(card.transform, "Backend");
            backendUrlInput = UiFactory.CreateInputField(card.transform, "http://127.0.0.1:8000", false);
            Button connectButton = UiFactory.CreateButton(card.transform, "Connect / Refresh", new Color(0.26f, 0.48f, 0.86f, 1f), Color.white);
            connectButton.onClick.AddListener(ConnectAndLoadCharacters);
        }

        private void BuildCreateCharacterCard(Transform parent)
        {
            GameObject card = UiFactory.CreateCard("CreateCharacterCard", parent, new Color(0.13f, 0.15f, 0.20f, 1f));
            LayoutElement layout = card.GetComponent<LayoutElement>();
            layout.preferredHeight = 390f;
            UiFactory.CreateVerticalLayout(card.transform, 8, new RectOffset(14, 14, 14, 14));

            UiFactory.CreateSectionTitle(card.transform, "Create Character");
            characterNameInput = UiFactory.CreateInputField(card.transform, "Name", false);
            characterPersonalityInput = UiFactory.CreateInputField(card.transform, "Personality", true);
            characterBackgroundInput = UiFactory.CreateInputField(card.transform, "Background", true);
            characterMemoryInput = UiFactory.CreateInputField(card.transform, "Memory", true);

            characterNameInput.text = "Mira";
            characterPersonalityInput.text = "warm, curious, playful";
            characterBackgroundInput.text = "A virtual guide from a near-future city.";
            characterMemoryInput.text = "The user is building an AI character demo.";

            GameObject buttonRow = UiFactory.CreatePanel("ButtonRow", card.transform, new Color(0f, 0f, 0f, 0f));
            UiFactory.CreateHorizontalLayout(buttonRow.transform, 8, new RectOffset(0, 0, 0, 0));

            Button createButton = UiFactory.CreateButton(buttonRow.transform, "Create", new Color(0.33f, 0.66f, 0.45f, 1f), Color.white);
            createButton.onClick.AddListener(CreateCharacterFromForm);

            Button fillButton = UiFactory.CreateButton(buttonRow.transform, "Demo Fill", new Color(0.28f, 0.32f, 0.38f, 1f), Color.white);
            fillButton.onClick.AddListener(FillDemoCharacterForm);
        }

        private void BuildCharacterBrowserCard(Transform parent)
        {
            GameObject card = UiFactory.CreateCard("CharacterBrowserCard", parent, new Color(0.13f, 0.15f, 0.20f, 1f));
            LayoutElement layout = card.GetComponent<LayoutElement>();
            layout.flexibleHeight = 1f;
            UiFactory.CreateVerticalLayout(card.transform, 10, new RectOffset(14, 14, 14, 14));

            UiFactory.CreateSectionTitle(card.transform, "Characters");

            ScrollRect scrollRect = UiFactory.CreateScrollRect(card.transform, "CharacterScroll", out characterListContent);
            LayoutElement scrollLayout = scrollRect.GetComponent<LayoutElement>();
            scrollLayout.flexibleHeight = 1f;
        }

        private void BuildSelectedCharacterCard(Transform parent)
        {
            GameObject card = UiFactory.CreateCard("SelectedCharacterCard", parent, new Color(0.13f, 0.15f, 0.20f, 1f));
            LayoutElement layout = card.GetComponent<LayoutElement>();
            layout.preferredHeight = 230f;
            layout.flexibleHeight = 1f;
            UiFactory.CreateVerticalLayout(card.transform, 10, new RectOffset(14, 14, 14, 14));

            UiFactory.CreateSectionTitle(card.transform, "Selected Character");
            selectedCharacterPreviewText = UiFactory.CreateBodyText(card.transform, "Choose a character from the list.");
            LayoutElement previewLayout = selectedCharacterPreviewText.GetComponent<LayoutElement>();
            previewLayout.flexibleHeight = 1f;

            openChatButton = UiFactory.CreateButton(card.transform, "Open Chat", new Color(0.29f, 0.55f, 0.94f, 1f), Color.white);
            openChatButton.onClick.AddListener(OpenSelectedCharacterChat);
            openChatButton.interactable = false;
        }

        private void BuildChatPanel()
        {
            chatRoot = UiFactory.CreateRoot("ChatRoot", canvas.transform);
            Image rootBackground = chatRoot.AddComponent<Image>();
            rootBackground.color = new Color(0.06f, 0.08f, 0.10f, 1f);
            UiFactory.CreateVerticalLayout(chatRoot.transform, 16, new RectOffset(24, 24, 24, 24));

            GameObject header = UiFactory.CreateCard("ChatHeader", chatRoot.transform, new Color(0.12f, 0.14f, 0.19f, 1f));
            LayoutElement headerLayout = header.GetComponent<LayoutElement>();
            headerLayout.preferredHeight = 64f;
            UiFactory.CreateHorizontalLayout(header.transform, 12, new RectOffset(16, 16, 12, 12));

            backButton = UiFactory.CreateButton(header.transform, "Menu", new Color(0.33f, 0.35f, 0.40f, 1f), Color.white);
            backButton.onClick.AddListener(ShowMainMenu);

            activeCharacterNameText = UiFactory.CreateSectionTitle(header.transform, "No character selected");
            LayoutElement titleLayout = activeCharacterNameText.GetComponent<LayoutElement>();
            titleLayout.flexibleWidth = 1f;
            activeCharacterNameText.alignment = TextAnchor.MiddleLeft;

            GameObject body = UiFactory.CreatePanel("ChatBody", chatRoot.transform, new Color(0f, 0f, 0f, 0f));
            LayoutElement bodyLayout = body.GetComponent<LayoutElement>();
            bodyLayout.flexibleHeight = 1f;
            UiFactory.CreateHorizontalLayout(body.transform, 16, new RectOffset(0, 0, 0, 0));

            GameObject profileCard = UiFactory.CreateCard("ProfileCard", body.transform, new Color(0.11f, 0.13f, 0.17f, 1f));
            LayoutElement profileLayout = profileCard.GetComponent<LayoutElement>();
            profileLayout.preferredWidth = 390f;
            profileLayout.flexibleHeight = 1f;
            UiFactory.CreateVerticalLayout(profileCard.transform, 10, new RectOffset(14, 14, 14, 14));

            UiFactory.CreateSectionTitle(profileCard.transform, "Character");
            activeCharacterProfileText = UiFactory.CreateBodyText(profileCard.transform, "Open a character from the menu.");
            LayoutElement profileTextLayout = activeCharacterProfileText.GetComponent<LayoutElement>();
            profileTextLayout.flexibleHeight = 1f;

            UiFactory.CreateSectionTitle(profileCard.transform, "Memories");
            ScrollRect memoryScroll = UiFactory.CreateScrollRect(profileCard.transform, "MemoryScroll", out memoryListContent);
            LayoutElement memoryLayout = memoryScroll.GetComponent<LayoutElement>();
            memoryLayout.preferredHeight = 250f;

            GameObject chatCard = UiFactory.CreateCard("ChatCard", body.transform, new Color(0.11f, 0.13f, 0.17f, 1f));
            LayoutElement chatLayout = chatCard.GetComponent<LayoutElement>();
            chatLayout.flexibleWidth = 1f;
            chatLayout.flexibleHeight = 1f;
            UiFactory.CreateVerticalLayout(chatCard.transform, 10, new RectOffset(14, 14, 14, 14));

            UiFactory.CreateSectionTitle(chatCard.transform, "Chat");

            messageScrollRect = UiFactory.CreateScrollRect(chatCard.transform, "MessageScroll", out messageListContent);
            LayoutElement messageLayout = messageScrollRect.GetComponent<LayoutElement>();
            messageLayout.flexibleHeight = 1f;

            GameObject inputRow = UiFactory.CreatePanel("InputRow", chatCard.transform, new Color(0f, 0f, 0f, 0f));
            UiFactory.CreateHorizontalLayout(inputRow.transform, 10, new RectOffset(0, 0, 0, 0));
            chatInput = UiFactory.CreateInputField(inputRow.transform, "Type a message...", true);
            LayoutElement inputLayout = chatInput.GetComponent<LayoutElement>();
            inputLayout.flexibleWidth = 1f;
            inputLayout.preferredHeight = 74f;

            sendButton = UiFactory.CreateButton(inputRow.transform, "Send", new Color(0.29f, 0.55f, 0.94f, 1f), Color.white);
            LayoutElement sendLayout = sendButton.GetComponent<LayoutElement>();
            sendLayout.preferredWidth = 140f;
            sendLayout.preferredHeight = 74f;
            sendButton.onClick.AddListener(SendChatMessage);
        }

        private void ConnectAndLoadCharacters()
        {
            StartCoroutine(ConnectAndLoadCharactersRoutine());
        }

        private IEnumerator ConnectAndLoadCharactersRoutine()
        {
            string backendUrl = backendUrlInput != null ? backendUrlInput.text : initialBackendUrl;
            apiClient.BaseUrl = backendUrl;
            SetStatus("Connecting to backend...");

            string error = null;
            HealthResponse health = null;

            yield return apiClient.GetHealth(
                delegate (HealthResponse response)
                {
                    health = response;
                },
                delegate (string message)
                {
                    error = message;
                });

            if (!string.IsNullOrEmpty(error))
            {
                SetStatus("Connection failed: " + error);
                yield break;
            }

            if (health != null)
            {
                SetStatus("Backend online: " + apiClient.BaseUrl);
            }

            yield return RefreshCharactersRoutine();
        }

        private IEnumerator RefreshCharactersRoutine()
        {
            SetStatus("Loading characters...");

            string error = null;
            List<CharacterDto> loadedCharacters = new List<CharacterDto>();

            yield return apiClient.GetCharacters(
                delegate (List<CharacterDto> response)
                {
                    loadedCharacters = response;
                },
                delegate (string message)
                {
                    error = message;
                });

            if (!string.IsNullOrEmpty(error))
            {
                SetStatus("Character load failed: " + error);
                RenderCharacterList(new List<CharacterDto>());
                yield break;
            }

            characters = loadedCharacters;
            RenderCharacterList(characters);

            if (characters.Count > 0)
            {
                if (selectedCharacter == null)
                {
                    SelectCharacter(characters[0]);
                }
                else
                {
                    CharacterDto refreshed = FindCharacterById(selectedCharacter.id);
                    if (refreshed != null)
                    {
                        SelectCharacter(refreshed);
                    }
                }
            }
            else
            {
                SelectCharacter(null);
            }

            SetStatus("Loaded " + characters.Count + " character(s).");
        }

        private IEnumerator CreateCharacterRoutine()
        {
            CharacterCreateRequest payload = new CharacterCreateRequest();
            payload.name = characterNameInput.text.Trim();
            payload.personality = characterPersonalityInput.text.Trim();
            payload.background = characterBackgroundInput.text.Trim();
            payload.memory = characterMemoryInput.text.Trim();

            if (string.IsNullOrEmpty(payload.name) || string.IsNullOrEmpty(payload.personality) || string.IsNullOrEmpty(payload.background))
            {
                SetStatus("Name, personality, and background are required.");
                yield break;
            }

            SetStatus("Creating character...");
            string error = null;
            CharacterDto created = null;

            yield return apiClient.CreateCharacter(
                payload,
                delegate (CharacterDto response)
                {
                    created = response;
                },
                delegate (string message)
                {
                    error = message;
                });

            if (!string.IsNullOrEmpty(error))
            {
                SetStatus("Create failed: " + error);
                yield break;
            }

            SetStatus("Character created: " + created.name);
            yield return RefreshCharactersRoutine();
            SelectCharacter(created);
        }

        private IEnumerator LoadSelectedCharacterRoutine(int characterId)
        {
            SetStatus("Loading character...");

            string error = null;
            CharacterDto character = null;
            List<MessageDto> messages = new List<MessageDto>();
            List<MemoryDto> memories = new List<MemoryDto>();

            yield return apiClient.GetCharacter(
                characterId,
                delegate (CharacterDto response)
                {
                    character = response;
                },
                delegate (string message)
                {
                    error = message;
                });

            if (!string.IsNullOrEmpty(error))
            {
                SetStatus("Failed to load character: " + error);
                yield break;
            }

            selectedCharacter = character;
            SelectCharacter(selectedCharacter);

            yield return apiClient.GetMessages(
                characterId,
                100,
                delegate (List<MessageDto> response)
                {
                    messages = response;
                },
                delegate (string message)
                {
                    error = message;
                });

            if (!string.IsNullOrEmpty(error))
            {
                SetStatus("Failed to load messages: " + error);
                yield break;
            }

            yield return apiClient.GetMemories(
                characterId,
                50,
                delegate (List<MemoryDto> response)
                {
                    memories = response;
                },
                delegate (string message)
                {
                    error = message;
                });

            if (!string.IsNullOrEmpty(error))
            {
                SetStatus("Failed to load memories: " + error);
                yield break;
            }

            RenderCharacterProfile(character);
            RenderMemories(memories);
            RenderMessages(messages);
            ShowChat();
            SetStatus("Chat ready.");
        }

        private IEnumerator SendChatRoutine()
        {
            if (selectedCharacter == null)
            {
                SetStatus("Select a character first.");
                yield break;
            }

            string message = chatInput != null ? chatInput.text.Trim() : string.Empty;
            if (string.IsNullOrEmpty(message))
            {
                yield break;
            }

            chatInput.text = string.Empty;
            AppendMessage("user", message);
            SetStatus("Thinking...");

            string error = null;
            ChatResponse response = null;

            yield return apiClient.Chat(
                selectedCharacter.id,
                new ChatRequest { message = message },
                delegate (ChatResponse result)
                {
                    response = result;
                },
                delegate (string messageError)
                {
                    error = messageError;
                });

            if (!string.IsNullOrEmpty(error))
            {
                SetStatus("Chat failed: " + error);
                AppendSystemMessage("Backend error: " + error);
                yield break;
            }

            AppendMessage("assistant", response.reply);
            SetStatus(response.used_llm ? "Reply generated by LLM." : "Reply generated in dev mode.");
            ScrollMessagesToBottom();
        }

        private void RenderCharacterList(List<CharacterDto> items)
        {
            if (characterListContent == null)
            {
                return;
            }

            UiFactory.ClearChildren(characterListContent);

            if (items == null || items.Count == 0)
            {
                emptyCharacterListText = UiFactory.CreateMutedText(characterListContent, "No characters yet. Create one from the left panel.");
                LayoutElement layout = emptyCharacterListText.GetComponent<LayoutElement>();
                layout.preferredHeight = 34f;
                return;
            }

            emptyCharacterListText = null;

            for (int i = 0; i < items.Count; i++)
            {
                CharacterDto character = items[i];
                GameObject row = UiFactory.CreateCard("CharacterItem_" + character.id, characterListContent, new Color(0.17f, 0.19f, 0.24f, 1f));
                LayoutElement layout = row.GetComponent<LayoutElement>();
                layout.preferredHeight = 74f;

                Button button = row.AddComponent<Button>();
                button.targetGraphic = row.GetComponent<Image>();

                UiFactory.CreateVerticalLayout(row.transform, 2, new RectOffset(12, 12, 10, 10));
                Text nameText = UiFactory.CreateBodyText(row.transform, character.name);
                nameText.fontStyle = FontStyle.Bold;
                Text personalityText = UiFactory.CreateMutedText(row.transform, character.personality);
                personalityText.fontSize = 12;

                CharacterDto localCharacter = character;
                button.onClick.AddListener(delegate
                {
                    SelectCharacter(localCharacter);
                });
            }
        }

        private void SelectCharacter(CharacterDto character)
        {
            selectedCharacter = character;
            bool hasCharacter = selectedCharacter != null;

            if (openChatButton != null)
            {
                openChatButton.interactable = hasCharacter;
            }

            if (hasCharacter)
            {
                if (selectedCharacterPreviewText != null)
                {
                    selectedCharacterPreviewText.text = BuildCharacterSummary(selectedCharacter);
                }
            }
            else if (selectedCharacterPreviewText != null)
            {
                selectedCharacterPreviewText.text = "Choose a character from the list.";
            }
        }

        private void OpenSelectedCharacterChat()
        {
            if (selectedCharacter == null)
            {
                SetStatus("Choose a character first.");
                return;
            }

            StartCoroutine(LoadSelectedCharacterRoutine(selectedCharacter.id));
        }

        private void RenderCharacterProfile(CharacterDto character)
        {
            if (activeCharacterNameText != null)
            {
                activeCharacterNameText.text = character.name;
            }

            if (activeCharacterProfileText != null)
            {
                activeCharacterProfileText.text = BuildCharacterSummary(character);
            }
        }

        private void RenderMemories(List<MemoryDto> memories)
        {
            if (memoryListContent == null)
            {
                return;
            }

            UiFactory.ClearChildren(memoryListContent);

            if (memories == null || memories.Count == 0)
            {
                Text emptyText = UiFactory.CreateMutedText(memoryListContent, "No memories saved yet.");
                LayoutElement emptyLayout = emptyText.GetComponent<LayoutElement>();
                emptyLayout.preferredHeight = 28f;
                return;
            }

            for (int i = 0; i < memories.Count; i++)
            {
                MemoryDto memory = memories[i];
                GameObject card = UiFactory.CreateCard("Memory_" + memory.id, memoryListContent, new Color(0.15f, 0.17f, 0.22f, 1f));
                LayoutElement layout = card.GetComponent<LayoutElement>();
                layout.preferredHeight = 84f;
                UiFactory.CreateVerticalLayout(card.transform, 2, new RectOffset(10, 10, 8, 8));
                UiFactory.CreateBodyText(card.transform, "[" + memory.type + "] importance " + memory.importance + "/5");
                Text contentText = UiFactory.CreateMutedText(card.transform, memory.content);
                contentText.fontSize = 12;
            }
        }

        private void RenderMessages(List<MessageDto> messages)
        {
            if (messageListContent == null)
            {
                return;
            }

            UiFactory.ClearChildren(messageListContent);

            if (messages != null)
            {
                for (int i = 0; i < messages.Count; i++)
                {
                    AppendMessage(messages[i].role, messages[i].content);
                }
            }

            if (messages == null || messages.Count == 0)
            {
                AppendSystemMessage("Say hello to begin.");
            }

            ScrollMessagesToBottom();
        }

        private void AppendMessage(string role, string content)
        {
            if (messageListContent == null)
            {
                return;
            }

            GameObject row = new GameObject("MessageRow", typeof(RectTransform), typeof(HorizontalLayoutGroup), typeof(LayoutElement));
            row.transform.SetParent(messageListContent, false);

            LayoutElement rowLayout = row.GetComponent<LayoutElement>();
            rowLayout.preferredWidth = 0f;
            rowLayout.preferredHeight = 0f;

            HorizontalLayoutGroup layout = row.GetComponent<HorizontalLayoutGroup>();
            layout.childControlWidth = false;
            layout.childControlHeight = true;
            layout.childForceExpandWidth = false;
            layout.childForceExpandHeight = false;
            layout.spacing = 10f;
            layout.padding = new RectOffset(0, 0, 0, 0);

            bool userMessage = role == "user";
            Color bubbleColor = userMessage ? new Color(0.20f, 0.46f, 0.86f, 1f) : new Color(0.17f, 0.20f, 0.27f, 1f);

            if (userMessage)
            {
                UiFactory.AddSpacer(row.transform, 120f, 1f);
            }

            GameObject bubble = UiFactory.CreateCard("Bubble", row.transform, bubbleColor);
            LayoutElement bubbleLayout = bubble.GetComponent<LayoutElement>();
            bubbleLayout.preferredWidth = 620f;
            bubbleLayout.minWidth = 180f;
            bubbleLayout.flexibleWidth = 0f;
            bubbleLayout.preferredHeight = 0f;
            UiFactory.CreateVerticalLayout(bubble.transform, 4, new RectOffset(12, 12, 10, 10));

            Text label = UiFactory.CreateBodyText(bubble.transform, content);
            label.color = Color.white;
            LayoutElement labelLayout = label.GetComponent<LayoutElement>();
            labelLayout.flexibleWidth = 1f;

            if (!userMessage)
            {
                UiFactory.AddSpacer(row.transform, 120f, 1f);
            }
        }

        private void AppendSystemMessage(string content)
        {
            if (messageListContent == null)
            {
                return;
            }

            GameObject row = new GameObject("SystemRow", typeof(RectTransform), typeof(LayoutElement));
            row.transform.SetParent(messageListContent, false);
            LayoutElement rowLayout = row.GetComponent<LayoutElement>();
            rowLayout.preferredHeight = 36f;

            Text text = UiFactory.CreateMutedText(row.transform, content);
            text.alignment = TextAnchor.MiddleCenter;
            text.fontStyle = FontStyle.Italic;
            LayoutElement textLayout = text.GetComponent<LayoutElement>();
            textLayout.flexibleWidth = 1f;
        }

        private void ScrollMessagesToBottom()
        {
            if (messageScrollRect != null)
            {
                Canvas.ForceUpdateCanvases();
                messageScrollRect.verticalNormalizedPosition = 0f;
            }
        }

        private void ShowMainMenu()
        {
            if (mainMenuRoot != null)
            {
                mainMenuRoot.SetActive(true);
            }

            if (chatRoot != null)
            {
                chatRoot.SetActive(false);
            }

            SetStatus("Main menu ready.");
        }

        private void ShowChat()
        {
            if (mainMenuRoot != null)
            {
                mainMenuRoot.SetActive(false);
            }

            if (chatRoot != null)
            {
                chatRoot.SetActive(true);
            }
        }

        private void CreateCharacterFromForm()
        {
            StartCoroutine(CreateCharacterRoutine());
        }

        private void FillDemoCharacterForm()
        {
            if (characterNameInput != null)
            {
                characterNameInput.text = "Mira";
            }

            if (characterPersonalityInput != null)
            {
                characterPersonalityInput.text = "warm, curious, playful";
            }

            if (characterBackgroundInput != null)
            {
                characterBackgroundInput.text = "A virtual guide from a near-future city.";
            }

            if (characterMemoryInput != null)
            {
                characterMemoryInput.text = "The user is building an AI character demo.";
            }

            SetStatus("Demo form filled.");
        }

        private void SendChatMessage()
        {
            StartCoroutine(SendChatRoutine());
        }

        private void SetStatus(string value)
        {
            if (statusText != null)
            {
                statusText.text = value;
            }
        }

        private void EnsureEventSystem()
        {
            if (EventSystem.current != null)
            {
                return;
            }

            GameObject eventSystemObject = new GameObject("EventSystem", typeof(EventSystem), typeof(StandaloneInputModule));
            DontDestroyOnLoad(eventSystemObject);
        }

        private CharacterDto FindCharacterById(int id)
        {
            for (int i = 0; i < characters.Count; i++)
            {
                if (characters[i].id == id)
                {
                    return characters[i];
                }
            }

            return null;
        }

        private static string BuildCharacterSummary(CharacterDto character)
        {
            return "Name: " + character.name + "\n\n" +
                   "Personality:\n" + character.personality + "\n\n" +
                   "Background:\n" + character.background + "\n\n" +
                   "Core Memory:\n" + character.memory;
        }
    }
}
