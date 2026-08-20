using UnityEngine;
using UnityEngine.UI;

namespace AIGCCharacterSimulator.Client
{
    public static class UiFactory
    {
        public static Font DefaultFont
        {
            get { return Resources.GetBuiltinResource<Font>("Arial.ttf"); }
        }

        public static GameObject CreateRoot(string name, Transform parent)
        {
            GameObject root = new GameObject(name, typeof(RectTransform));
            root.transform.SetParent(parent, false);
            RectTransform rect = root.GetComponent<RectTransform>();
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
            return root;
        }

        public static GameObject CreatePanel(string name, Transform parent, Color color)
        {
            GameObject panel = new GameObject(name, typeof(RectTransform), typeof(Image), typeof(LayoutElement));
            panel.transform.SetParent(parent, false);
            RectTransform rect = panel.GetComponent<RectTransform>();
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;

            Image image = panel.GetComponent<Image>();
            image.color = color;
            return panel;
        }

        public static GameObject CreateCard(string name, Transform parent, Color color)
        {
            GameObject card = new GameObject(name, typeof(RectTransform), typeof(Image), typeof(LayoutElement));
            card.transform.SetParent(parent, false);
            Image image = card.GetComponent<Image>();
            image.color = color;
            RectTransform rect = card.GetComponent<RectTransform>();
            rect.localScale = Vector3.one;
            return card;
        }

        public static VerticalLayoutGroup CreateVerticalLayout(Transform parent, int spacing, RectOffset padding)
        {
            VerticalLayoutGroup layout = parent.gameObject.AddComponent<VerticalLayoutGroup>();
            layout.spacing = spacing;
            layout.padding = padding;
            layout.childAlignment = TextAnchor.UpperLeft;
            layout.childControlWidth = true;
            layout.childControlHeight = true;
            layout.childForceExpandWidth = true;
            layout.childForceExpandHeight = false;
            return layout;
        }

        public static HorizontalLayoutGroup CreateHorizontalLayout(Transform parent, int spacing, RectOffset padding)
        {
            HorizontalLayoutGroup layout = parent.gameObject.AddComponent<HorizontalLayoutGroup>();
            layout.spacing = spacing;
            layout.padding = padding;
            layout.childAlignment = TextAnchor.UpperLeft;
            layout.childControlWidth = true;
            layout.childControlHeight = true;
            layout.childForceExpandWidth = false;
            layout.childForceExpandHeight = true;
            return layout;
        }

        public static Text CreateText(Transform parent, string value, int size, Color color, TextAnchor alignment, FontStyle style, bool richText)
        {
            GameObject textObject = new GameObject("Text", typeof(RectTransform), typeof(Text), typeof(LayoutElement));
            textObject.transform.SetParent(parent, false);
            RectTransform rect = textObject.GetComponent<RectTransform>();
            rect.localScale = Vector3.one;

            Text text = textObject.GetComponent<Text>();
            text.font = DefaultFont;
            text.text = value;
            text.fontSize = size;
            text.color = color;
            text.alignment = alignment;
            text.fontStyle = style;
            text.supportRichText = richText;
            text.horizontalOverflow = HorizontalWrapMode.Wrap;
            text.verticalOverflow = VerticalWrapMode.Overflow;
            return text;
        }

        public static Text CreateSectionTitle(Transform parent, string value)
        {
            return CreateText(parent, value, 20, new Color(0.95f, 0.96f, 0.98f, 1f), TextAnchor.MiddleLeft, FontStyle.Bold, false);
        }

        public static Text CreateBodyText(Transform parent, string value)
        {
            return CreateText(parent, value, 15, new Color(0.88f, 0.90f, 0.94f, 1f), TextAnchor.UpperLeft, FontStyle.Normal, false);
        }

        public static Text CreateMutedText(Transform parent, string value)
        {
            return CreateText(parent, value, 13, new Color(0.70f, 0.74f, 0.80f, 1f), TextAnchor.UpperLeft, FontStyle.Normal, false);
        }

        public static Button CreateButton(Transform parent, string label, Color color, Color textColor)
        {
            GameObject buttonObject = new GameObject(label + "Button", typeof(RectTransform), typeof(Image), typeof(Button), typeof(LayoutElement));
            buttonObject.transform.SetParent(parent, false);

            Image image = buttonObject.GetComponent<Image>();
            image.color = color;

            Button button = buttonObject.GetComponent<Button>();
            button.targetGraphic = image;

            LayoutElement layout = buttonObject.GetComponent<LayoutElement>();
            layout.preferredHeight = 42f;
            layout.minHeight = 42f;

            Text text = CreateText(buttonObject.transform, label, 16, textColor, TextAnchor.MiddleCenter, FontStyle.Bold, false);
            RectTransform textRect = text.GetComponent<RectTransform>();
            textRect.anchorMin = Vector2.zero;
            textRect.anchorMax = Vector2.one;
            textRect.offsetMin = new Vector2(8f, 6f);
            textRect.offsetMax = new Vector2(-8f, -6f);
            return button;
        }

        public static InputField CreateInputField(Transform parent, string placeholder, bool multiline)
        {
            GameObject fieldObject = new GameObject("InputField", typeof(RectTransform), typeof(Image), typeof(InputField), typeof(LayoutElement));
            fieldObject.transform.SetParent(parent, false);

            Image background = fieldObject.GetComponent<Image>();
            background.color = new Color(1f, 1f, 1f, 0.08f);

            LayoutElement layout = fieldObject.GetComponent<LayoutElement>();
            layout.preferredHeight = multiline ? 74f : 40f;
            layout.minHeight = multiline ? 74f : 40f;

            InputField field = fieldObject.GetComponent<InputField>();
            field.transition = Selectable.Transition.ColorTint;

            GameObject textObject = new GameObject("Text", typeof(RectTransform), typeof(Text));
            textObject.transform.SetParent(fieldObject.transform, false);
            RectTransform textRect = textObject.GetComponent<RectTransform>();
            textRect.anchorMin = Vector2.zero;
            textRect.anchorMax = Vector2.one;
            textRect.offsetMin = new Vector2(10f, 6f);
            textRect.offsetMax = new Vector2(-10f, -6f);

            Text text = textObject.GetComponent<Text>();
            text.font = DefaultFont;
            text.fontSize = 16;
            text.color = new Color(0.96f, 0.97f, 0.99f, 1f);
            text.alignment = TextAnchor.UpperLeft;
            text.horizontalOverflow = HorizontalWrapMode.Wrap;
            text.verticalOverflow = VerticalWrapMode.Overflow;
            text.supportRichText = false;

            GameObject placeholderObject = new GameObject("Placeholder", typeof(RectTransform), typeof(Text));
            placeholderObject.transform.SetParent(fieldObject.transform, false);
            RectTransform placeholderRect = placeholderObject.GetComponent<RectTransform>();
            placeholderRect.anchorMin = Vector2.zero;
            placeholderRect.anchorMax = Vector2.one;
            placeholderRect.offsetMin = new Vector2(10f, 6f);
            placeholderRect.offsetMax = new Vector2(-10f, -6f);

            Text placeholderText = placeholderObject.GetComponent<Text>();
            placeholderText.font = DefaultFont;
            placeholderText.fontSize = 16;
            placeholderText.color = new Color(0.78f, 0.81f, 0.86f, 0.55f);
            placeholderText.alignment = TextAnchor.UpperLeft;
            placeholderText.horizontalOverflow = HorizontalWrapMode.Wrap;
            placeholderText.verticalOverflow = VerticalWrapMode.Overflow;
            placeholderText.supportRichText = false;
            placeholderText.text = placeholder;

            field.textComponent = text;
            field.placeholder = placeholderText;
            field.lineType = multiline ? InputField.LineType.MultiLineNewline : InputField.LineType.SingleLine;
            field.contentType = InputField.ContentType.Standard;
            return field;
        }

        public static ScrollRect CreateScrollRect(Transform parent, string name, out RectTransform content)
        {
            GameObject root = new GameObject(name, typeof(RectTransform), typeof(Image), typeof(Mask), typeof(ScrollRect), typeof(LayoutElement));
            root.transform.SetParent(parent, false);

            Image background = root.GetComponent<Image>();
            background.color = new Color(1f, 1f, 1f, 0.04f);

            Mask mask = root.GetComponent<Mask>();
            mask.showMaskGraphic = false;

            ScrollRect scrollRect = root.GetComponent<ScrollRect>();
            scrollRect.horizontal = false;
            scrollRect.vertical = true;
            scrollRect.movementType = ScrollRect.MovementType.Clamped;
            scrollRect.scrollSensitivity = 20f;

            GameObject viewport = new GameObject("Viewport", typeof(RectTransform), typeof(Image));
            viewport.transform.SetParent(root.transform, false);
            RectTransform viewportRect = viewport.GetComponent<RectTransform>();
            viewportRect.anchorMin = Vector2.zero;
            viewportRect.anchorMax = Vector2.one;
            viewportRect.offsetMin = Vector2.zero;
            viewportRect.offsetMax = Vector2.zero;

            Image viewportImage = viewport.GetComponent<Image>();
            viewportImage.color = new Color(1f, 1f, 1f, 0.01f);

            GameObject contentObject = new GameObject("Content", typeof(RectTransform), typeof(VerticalLayoutGroup), typeof(ContentSizeFitter));
            contentObject.transform.SetParent(viewport.transform, false);
            content = contentObject.GetComponent<RectTransform>();
            content.anchorMin = new Vector2(0f, 1f);
            content.anchorMax = new Vector2(1f, 1f);
            content.pivot = new Vector2(0.5f, 1f);
            content.anchoredPosition = Vector2.zero;
            content.sizeDelta = new Vector2(0f, 0f);

            VerticalLayoutGroup layout = contentObject.GetComponent<VerticalLayoutGroup>();
            layout.childControlWidth = true;
            layout.childControlHeight = true;
            layout.childForceExpandWidth = true;
            layout.childForceExpandHeight = false;
            layout.spacing = 8f;
            layout.padding = new RectOffset(8, 8, 8, 8);

            ContentSizeFitter fitter = contentObject.GetComponent<ContentSizeFitter>();
            fitter.horizontalFit = ContentSizeFitter.FitMode.Unconstrained;
            fitter.verticalFit = ContentSizeFitter.FitMode.PreferredSize;

            scrollRect.viewport = viewportRect;
            scrollRect.content = content;
            return scrollRect;
        }

        public static void ClearChildren(Transform parent)
        {
            for (int i = parent.childCount - 1; i >= 0; i--)
            {
                Object.Destroy(parent.GetChild(i).gameObject);
            }
        }

        public static void AddSpacer(Transform parent, float width, float height)
        {
            GameObject spacer = new GameObject("Spacer", typeof(RectTransform), typeof(LayoutElement));
            spacer.transform.SetParent(parent, false);
            LayoutElement element = spacer.GetComponent<LayoutElement>();
            element.minWidth = width;
            element.minHeight = height;
            element.preferredWidth = width;
            element.preferredHeight = height;
            element.flexibleWidth = 1f;
        }
    }
}
