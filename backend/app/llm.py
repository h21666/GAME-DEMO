from dataclasses import dataclass

import httpx

from app.provider_store import get_provider_config
from app.prompt_defaults import DEFAULT_COMPANION_ROLEPLAY_PROMPT


@dataclass
class LLMResult:
    reply: str
    used_llm: bool


class LLMClient:
    async def generate_character_reply(
        self,
        *,
        character: dict,
        recent_messages: list[dict],
        memories: list[dict],
        user_message: str,
    ) -> LLMResult:
        config = get_provider_config("text")

        if not config.get("api_key"):
            return self._generate_dev_reply(character=character, user_message=user_message)

        messages = self._build_messages(
            character=character,
            recent_messages=recent_messages,
            memories=memories,
            user_message=user_message,
        )

        payload = {
            "model": config["model"],
            "messages": messages,
            "temperature": config["temperature"],
            "max_tokens": config["max_tokens"],
        }

        if config.get("thinking_enabled"):
            payload["thinking"] = {"type": "enabled"}
        if config.get("reasoning_effort"):
            payload["reasoning_effort"] = config["reasoning_effort"]

        url = f"{config['base_url'].rstrip('/')}/chat/completions"
        headers = {
            "Authorization": f"Bearer {config['api_key']}",
            "Content-Type": "application/json",
        }

        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(url, headers=headers, json=payload)
            response.raise_for_status()

        data = response.json()
        reply = data["choices"][0]["message"]["content"].strip()
        return LLMResult(reply=reply, used_llm=True)

    def _build_messages(
        self,
        *,
        character: dict,
        recent_messages: list[dict],
        memories: list[dict],
        user_message: str,
    ) -> list[dict]:
        memory_lines = []
        if character.get("memory"):
            memory_lines.append(f"Core memory: {character['memory']}")
        for memory in memories:
            memory_lines.append(
                f"- [{memory['type']}, importance {memory['importance']}/5] {memory['content']}"
            )

        system_prompt = "\n".join(
            [
                "You are roleplaying as an interactive AI character.",
                "Stay in character and answer as the character, not as an assistant.",
                "Use the character profile, memories, and conversation history.",
                "Keep replies natural, emotionally consistent, and concise unless the user asks for detail.",
                DEFAULT_COMPANION_ROLEPLAY_PROMPT,
                "",
                f"Character name: {character['name']}",
                f"Personality: {character['personality']}",
                f"Background: {character['background']}",
                "Memories:",
                "\n".join(memory_lines) if memory_lines else "No saved memories yet.",
            ]
        )

        messages = [{"role": "system", "content": system_prompt}]
        for item in recent_messages:
            messages.append({"role": item["role"], "content": item["content"]})
        messages.append({"role": "user", "content": user_message})
        return messages

    def _generate_dev_reply(self, *, character: dict, user_message: str) -> LLMResult:
        name = character.get("name", "Character")
        personality = character.get("personality", "thoughtful")
        reply = (
            f"[Dev Reply - configure DEEPSEEK_API_KEY for real LLM output]\n"
            f"{name}: I heard you say: \"{user_message}\". "
            f"I will respond through my personality: {personality}."
        )
        return LLMResult(reply=reply, used_llm=False)
