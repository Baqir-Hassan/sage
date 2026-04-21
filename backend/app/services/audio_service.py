import asyncio
from pathlib import Path

import edge_tts


class AudioGenerationService:
    def generate_section_audio(self, text: str, voice: str, output_path: Path) -> None:
        cleaned_text = " ".join(text.split())
        if not cleaned_text:
            cleaned_text = "No lecture content was available for this section."
        asyncio.run(self._save_audio(cleaned_text, voice, output_path))

    async def _save_audio(self, text: str, voice: str, output_path: Path) -> None:
        communicate = edge_tts.Communicate(text=text, voice=voice)
        await communicate.save(str(output_path))
