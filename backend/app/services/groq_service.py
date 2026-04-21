import json

import requests

from app.core.config import get_settings


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
            "messages": [
                {
                    "role": "system",
                    "content": (
                        "You turn class notes into natural spoken lecture scripts. "
                        "You must return valid JSON only."
                    ),
                },
                {
                    "role": "user",
                    "content": prompt,
                },
            ],
        }

        try:
            response = requests.post(self.url, headers=headers, json=payload, timeout=90)
            response.raise_for_status()
            data = response.json()
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

        cleaned = response_text.strip()
        if cleaned.startswith("```"):
            cleaned = cleaned.strip("`")
            if cleaned.startswith("json"):
                cleaned = cleaned[4:].strip()

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
                    "script": raw_text or "The lecture script could not be generated.",
                }
            ],
        }
