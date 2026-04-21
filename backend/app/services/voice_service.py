from app.core.config import get_settings


def resolve_tts_voice(voice_option: str) -> str:
    settings = get_settings()
    if voice_option == "male":
        return settings.default_male_voice
    return settings.default_female_voice
