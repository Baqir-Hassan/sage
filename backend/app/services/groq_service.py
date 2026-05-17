import json
import logging
import re

import requests

from app.core.config import get_settings

logger = logging.getLogger(__name__)


class GroqService:
    def __init__(self) -> None:
        settings = get_settings()
        self.api_key = settings.groq_api_key
        self.model = settings.groq_model
        self.url = "https://api.groq.com/openai/v1/chat/completions"

    def generate_lecture_script(self, prompt: str) -> dict:
        if not self.api_key:
            return self._fallback_payload("Groq API key is not configured yet.")

        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }
        payload = {
            "model": self.model,
            "temperature": 0.2,
            "max_tokens": 32000,  # Fix 1: use near-max to avoid cutoff
            "response_format": {"type": "json_object"},  # Fix 4: force JSON output
            "messages": [
                {
                    "role": "system",
                    "content": (
                        "You turn class notes into natural spoken lecture scripts that sound like a real teacher "
                        "guiding a class. Break the content into MULTIPLE detailed sections (at least 3-5 sections). "
                        "For each section, create a comprehensive script that explains the topic thoroughly. "
                        "Open each lecture in a teacher-like way, such as introducing what today's lesson covers, "
                        "and keep the explanation warm, clear, and instructional. Include important definitions, formulas, and examples. "
                        "Cover ALL the material from the notes, not just a brief overview. "
                        "You must return valid JSON only, using exactly this structure:\n"
                        "{\n"
                        '  "subject": "...",\n'
                        '  "playlist_title": "...",\n'
                        '  "lecture_title": "...",\n'
                        '  "lecture_description": "...",\n'
                        '  "sections": [\n'
                        '    { "title": "...", "script": "..." }\n'
                        "  ]\n"
                        "}"  # Fix 3: define exact JSON schema
                    ),
                },
                {
                    "role": "user",
                    "content": prompt,
                },
            ],
        }

        try:
            response = requests.post(self.url, headers=headers, json=payload, timeout=120)  # slightly longer timeout
            response.raise_for_status()
            data = response.json()
            logger.info(f"Groq raw response: {json.dumps(data, indent=2)}")

            # Check for finish_reason to detect truncation early
            finish_reason = data["choices"][0].get("finish_reason")
            if finish_reason == "length":
                logger.warning("Groq response was truncated (finish_reason=length). Consider reducing input size.")

            content = data["choices"][0]["message"]["content"]
            return self._parse_response_text(content)
        except requests.HTTPError as exc:
            return self._fallback_payload(f"Groq HTTP error: {exc}")
        except requests.RequestException as exc:
            return self._fallback_payload(f"Groq request error: {exc}")
        except Exception as exc:
            return self._fallback_payload(f"Groq unexpected error: {exc}")

    def _parse_response_text(self, response_text: str | None) -> dict:
        if not response_text:
            return self._fallback_payload("Groq returned an empty response.")

        # Fix 2: reliably strip markdown code fences
        cleaned = response_text.strip()
        cleaned = re.sub(r"^```(?:json)?\s*", "", cleaned)
        cleaned = re.sub(r"\s*```$", "", cleaned).strip()

        try:
            payload = json.loads(cleaned)
        except json.JSONDecodeError:
            return self._fallback_payload(cleaned[:4000])

        if not isinstance(payload, dict):
            return self._fallback_payload(cleaned[:4000])

        sections = payload.get("sections")
        if not isinstance(sections, list):
            payload["sections"] = []
        return payload

    def _fallback_payload(self, raw_text: str) -> dict:
        return {
            "subject": "General",
            "playlist_title": "Imported Notes",
            "lecture_title": "Generated Lecture",
            "lecture_description": "Fallback lecture payload created because Groq did not return valid JSON.",
            "sections": [
                {
                    "title": "Lecture Overview",
                    "script": (
                        "Today's lecture is about the material in your uploaded notes. "
                        f"{raw_text or 'The lecture script could not be generated.'}"
                    ),
                }
            ],
        }