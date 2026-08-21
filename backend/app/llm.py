from dataclasses import dataclass

import httpx

from app.provider_store import get_provider_config
from app.prompt_defaults import DEFAULT_COMPANION_ROLEPLAY_PROMPT
from app.game_data import relationship_stage


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
                "Relationship progress:",
                f"- Score: {int(character.get('relationship', 0))}/100",
                f"- Stage: {relationship_stage(int(character.get('relationship', 0)))}",
                f"- Money available for shared life: {int(character.get('money', 0))}",
                f"- Home: {character.get('room_name', '出租屋')} - {character.get('room_description', '')}",
                "Let relationship progress affect warmth, initiative, remembered details, and scene intimacy. Do not narrate the numeric score.",
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
        relationship = int(character.get("relationship", 0))
        stage = relationship_stage(relationship)
        if relationship >= 60:
            tone = "她熟悉你的习惯，主动靠近了一些"
        elif relationship >= 30:
            tone = "她已经比刚认识时更愿意敞开心扉"
        else:
            tone = "她还在一点点熟悉你的生活"
        reply = (
            f"[Dev Reply - configure DEEPSEEK_API_KEY for real LLM output]\n"
            f"{name}（{stage}）：主人，我听见你说“{user_message}”了。"
            f"{tone}。我会按照自己的性格回应你：{personality}。"
        )
        return LLMResult(reply=reply, used_llm=False)
