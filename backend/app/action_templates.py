from dataclasses import dataclass


@dataclass(frozen=True)
class ActionTemplate:
    action_key: str
    action_name: str
    action_prompt: str


DEFAULT_ACTION_TEMPLATES: list[ActionTemplate] = [
    ActionTemplate(
        action_key="idle",
        action_name="Idle",
        action_prompt="standing in a natural idle pose, relaxed and calm",
    ),
    ActionTemplate(
        action_key="smile",
        action_name="Smile",
        action_prompt="smiling warmly with a soft friendly expression",
    ),
    ActionTemplate(
        action_key="greet",
        action_name="Greet",
        action_prompt="raising one hand in a gentle greeting pose",
    ),
    ActionTemplate(
        action_key="drink_tea",
        action_name="Drink Tea",
        action_prompt="holding a tea cup and taking a small sip",
    ),
    ActionTemplate(
        action_key="read_book",
        action_name="Read Book",
        action_prompt="sitting or standing while reading an open book",
    ),
    ActionTemplate(
        action_key="sleepy",
        action_name="Sleepy",
        action_prompt="looking sleepy and softly rubbing one eye",
    ),
]

