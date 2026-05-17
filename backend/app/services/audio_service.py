import asyncio
import logging
from pathlib import Path

import edge_tts

logger = logging.getLogger(__name__)


class AudioGenerationService:
    def generate_section_audio(self, text: str, voice: str, output_path: Path) -> None:
        cleaned_text = " ".join(text.split())
        if not cleaned_text:
            cleaned_text = "No lecture content was available for this section."
        logger.info(f"[AUDIO DEBUG] voice={voice} chars={len(cleaned_text)} words={len(cleaned_text.split())} path={output_path}")
        logger.info(f"[AUDIO DEBUG] text preview: {cleaned_text[:200]}")
        asyncio.run(self._save_audio(cleaned_text, voice, output_path))

    async def _save_audio(self, text: str, voice: str, output_path: Path) -> None:
        communicate = edge_tts.Communicate(text=text, voice=voice)
        await communicate.save(str(output_path))