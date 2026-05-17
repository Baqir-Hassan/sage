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
# ~1 token ≈ 4 characters.
# 4,000 chars ≈ 1,000 input tokens.  With ~2,500 output tokens that puts each
# request at ~3,500 tokens — safely under the 12,000 TPM free-tier limit even
# if two calls overlap inside the same minute window.
# Each chunk produces 3-5 sections × 150-200 words ≈ 2.5-3 min of audio.
_MAX_CHUNK_CHARS = 4_000   # ≈ 1,000 input tokens per chunk
_MAX_OUTPUT_TOKENS = 2_500  # enough for 3-5 detailed sections
_INTER_CHUNK_DELAY = 6      # seconds to wait between successive Groq calls
 
 
class GroqService:
    def __init__(self) -> None:
        settings = get_settings()
        self.api_key = settings.groq_api_key
        self.model = settings.groq_model
        self.url = "https://api.groq.com/openai/v1/chat/completions"
 
    # ------------------------------------------------------------------
    # Public interface
    # ------------------------------------------------------------------
 
    def generate_lecture_script(self, prompt: str) -> list[dict]:
        """
        Split the prompt into chunks and return a LIST of lecture payloads —
        one payload per chunk — so the caller can create a separate lecture
        (with its own audio tracks) for each part of the notes.
        """
        if not self.api_key:
            return [self._fallback_payload("Groq API key is not configured yet.")]
 
        chunks = self._chunk_prompt(prompt, max_chars=_MAX_CHUNK_CHARS)
        logger.info(f"Split prompt into {len(chunks)} chunk(s).")
 
        results: list[dict] = []
        last_section_title: str | None = None
 
        for i, chunk in enumerate(chunks):
            # Tell the model where it is in the series so it continues naturally
            if i == 0:
                continuity = (
                    "This is the first part of the lecture series. "
                    "Open with a warm teacher-like introduction covering what "
                    "today's lesson is about. Do NOT write a conclusion."
                )
            elif i == len(chunks) - 1:
                continuity = (
                    f"This is part {i + 1} of {len(chunks)} — the final part. "
                    f"The previous lecture ended on: '{last_section_title}'. "
                    "Begin by briefly acknowledging you are continuing from last time, "
                    "then teach the remaining material and close with a proper conclusion. "
                    "Do NOT re-introduce the whole subject from scratch."
                )
            else:
                continuity = (
                    f"This is part {i + 1} of {len(chunks)} of the lecture series. "
                    f"The previous lecture ended on: '{last_section_title}'. "
                    "Begin by briefly acknowledging you are continuing from last time, "
                    "then carry on teaching naturally. "
                    "Do NOT write an introduction or conclusion — just continue teaching. "
                    "Do NOT re-introduce the whole subject from scratch."
                )
 
            chunk_prompt = (
                f"{continuity}\n\n"
                f"Notes for this part:\n{chunk}\n\n"
                + (
                    "Return JSON with 'subject', 'playlist_title', 'lecture_title', "
                    "'lecture_description', and 'sections'."
                    if i == 0
                    else (
                        "Return JSON with 'subject', 'playlist_title', "
                        f"'lecture_title' (set to 'Part {i + 1}: <topic of this chunk>'), "
                        "'lecture_description', and 'sections'."
                    )
                )
            )
 
            result = self._call_groq(chunk_prompt)
            results.append(result)
 
            # Track the last section title for the next chunk's continuity prompt
            sections = result.get("sections", [])
            if sections:
                last_section_title = sections[-1].get("title", "the previous topic")
            else:
                logger.warning(f"Chunk {i + 1} returned no sections.")
 
            if i < len(chunks) - 1:
                logger.info(f"Waiting {_INTER_CHUNK_DELAY}s before next chunk…")
                time.sleep(_INTER_CHUNK_DELAY)
 
        if not results:
            return [self._fallback_payload("No chunks were processed successfully.")]
 
        logger.info(f"Generated {len(results)} lecture(s) from {len(chunks)} chunk(s).")
        return results
 
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
                        "guiding a class. Break the content into 3-5 sections per part. "
                        "Each section script MUST be between 150 and 200 words — this is strict. "
                        "Do not write short sections. Each script should take about 60-90 seconds to read aloud. "
                        "Keep the explanation warm, clear, and instructional. "
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
        }