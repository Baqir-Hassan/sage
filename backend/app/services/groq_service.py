import json
import logging
import re
import time

import requests

from app.core.config import get_settings

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Token / character budget constants (tuned for Groq free tier: 12,000 TPM)
# ---------------------------------------------------------------------------
# ~1 token ≈ 4 characters.  We target <4 000 tokens per request so that even
# two back-to-back calls stay inside the 12 000 TPM window with room to spare.
_MAX_CHUNK_CHARS = 1_500   # ≈ 375 input tokens per chunk
_MAX_OUTPUT_TOKENS = 2_500  # output budget per chunk
_INTER_CHUNK_DELAY = 3      # seconds to wait between successive Groq calls


class GroqService:
    def __init__(self) -> None:
        settings = get_settings()
        self.api_key = settings.groq_api_key
        self.model = settings.groq_model
        self.url = "https://api.groq.com/openai/v1/chat/completions"

    # ------------------------------------------------------------------
    # Public interface
    # ------------------------------------------------------------------

    def generate_lecture_script(self, prompt: str) -> dict:
        if not self.api_key:
            return self._fallback_payload("Groq API key is not configured yet.")

        chunks = self._chunk_prompt(prompt, max_chars=_MAX_CHUNK_CHARS)
        logger.info(f"Split prompt into {len(chunks)} chunk(s).")

        all_sections: list[dict] = []
        base_payload: dict | None = None

        for i, chunk in enumerate(chunks):
            chunk_prompt = (
                f"Part {i + 1} of {len(chunks)} of the notes:\n\n{chunk}\n\n"
                "Return JSON with a 'sections' list for this part. "
                + (
                    "Also include 'subject', 'playlist_title', 'lecture_title', "
                    "and 'lecture_description' fields — only needed in part 1."
                    if i == 0
                    else "Only the 'sections' key is required for this part."
                )
            )

            result = self._call_groq(chunk_prompt)

            if base_payload is None:
                base_payload = result

            sections = result.get("sections", [])
            if sections:
                all_sections.extend(sections)
            else:
                logger.warning(f"Chunk {i + 1} returned no sections.")

            # Respect the per-minute token limit between calls
            if i < len(chunks) - 1:
                logger.info(f"Waiting {_INTER_CHUNK_DELAY}s before next chunk…")
                time.sleep(_INTER_CHUNK_DELAY)

        if not base_payload:
            return self._fallback_payload("No chunks were processed successfully.")

        if not all_sections:
            return self._fallback_payload("Groq returned no sections across all chunks.")

        base_payload["sections"] = all_sections
        logger.info(f"Final lecture has {len(all_sections)} section(s).")
        return base_payload

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _call_groq(self, prompt: str) -> dict:
        """Make a single Groq API call and return a parsed payload dict."""
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }
        payload = {
            "model": self.model,
            "temperature": 0.2,
            "max_tokens": _MAX_OUTPUT_TOKENS,
            "messages": [
                {
                    "role": "system",
                    "content": (
                        "You turn class notes into natural spoken lecture scripts that sound like a real teacher "
                        "guiding a class. Break the content into MULTIPLE detailed sections (at least 3-5 sections). "
                        "For each section, create a comprehensive script that explains the topic thoroughly. "
                        "Open each lecture in a teacher-like way, such as introducing what today's lesson covers, "
                        "and keep the explanation warm, clear, and instructional. "
                        "Include important definitions, formulas, and examples. "
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
                        "}\n"
                        "Return ONLY the JSON object — no markdown fences, no extra text."
                    ),
                },
                {"role": "user", "content": prompt},
            ],
        }

        try:
            response = requests.post(
                self.url, headers=headers, json=payload, timeout=120
            )
            response.raise_for_status()
            data = response.json()
            logger.info(f"Groq raw response: {json.dumps(data, indent=2)}")

            finish_reason = data["choices"][0].get("finish_reason")
            if finish_reason == "length":
                logger.warning(
                    "Groq response was truncated (finish_reason=length). "
                    "Consider reducing _MAX_CHUNK_CHARS or _MAX_OUTPUT_TOKENS."
                )

            content = data["choices"][0]["message"]["content"]
            return self._parse_response_text(content)

        except requests.HTTPError as exc:
            logger.error(
                f"Groq HTTP error: {exc.response.status_code} - {exc.response.text}"
            )
            return self._fallback_payload(f"Groq HTTP error: {exc}")
        except requests.RequestException as exc:
            logger.error(f"Groq request error: {exc}")
            return self._fallback_payload(f"Groq request error: {exc}")
        except Exception as exc:
            logger.error(f"Groq unexpected error: {exc}")
            return self._fallback_payload(f"Groq unexpected error: {exc}")

    def _chunk_prompt(self, text: str, max_chars: int) -> list[str]:
        """
        Split *text* into chunks of at most *max_chars* characters,
        trying to break at sentence boundaries ('. ') to preserve context.
        """
        chunks: list[str] = []
        while len(text) > max_chars:
            split_at = text.rfind(". ", 0, max_chars)
            if split_at == -1:
                # No sentence boundary found — hard-split at max_chars
                split_at = max_chars
            else:
                split_at += 1  # include the period
            chunks.append(text[:split_at].strip())
            text = text[split_at:].strip()
        if text:
            chunks.append(text)
        return chunks

    def _parse_response_text(self, response_text: str | None) -> dict:
        if not response_text:
            return self._fallback_payload("Groq returned an empty response.")

        # Strip markdown code fences if the model added them despite instructions
        cleaned = response_text.strip()
        cleaned = re.sub(r"^```(?:json)?\s*", "", cleaned)
        cleaned = re.sub(r"\s*```$", "", cleaned).strip()

        try:
            payload = json.loads(cleaned)
        except json.JSONDecodeError:
            logger.error(f"JSON decode failed. Raw text (first 500 chars): {cleaned[:500]}")
            return self._fallback_payload(cleaned[:4000])

        if not isinstance(payload, dict):
            return self._fallback_payload(cleaned[:4000])

        if not isinstance(payload.get("sections"), list):
            payload["sections"] = []

        return payload

    def _fallback_payload(self, raw_text: str) -> dict:
        return {
            "subject": "General",
            "playlist_title": "Imported Notes",
            "lecture_title": "Generated Lecture",
            "lecture_description": (
                "Fallback lecture payload created because Groq did not return valid JSON."
            ),
            "sections": [
                {
                    "title": "Lecture Overview",
                    "script": (
                        "Today's lecture is about the material in your uploaded notes. "
                        f"{raw_text or 'The lecture script could not be generated.'}"
                    ),
                }
            ],
        }s