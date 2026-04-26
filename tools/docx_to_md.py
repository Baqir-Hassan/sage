from __future__ import annotations

import re
import zipfile
from pathlib import Path
import xml.etree.ElementTree as ET


W_NS = {"w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main"}
R_NS = {"r": "http://schemas.openxmlformats.org/officeDocument/2006/relationships"}


def _norm_ws(s: str) -> str:
    return re.sub(r"[ \t]+", " ", s).strip()


def _style_to_md_prefix(style: str | None) -> str | None:
    if not style:
        return None
    style = style.lower()
    # Common Word heading style IDs: Heading1/heading 1 etc.
    if "heading1" in style or style in {"heading1", "title"}:
        return "## "
    if "heading2" in style or style in {"heading2"}:
        return "### "
    if "heading3" in style or style in {"heading3"}:
        return "#### "
    return None


def docx_to_markdown(docx_path: Path, out_md_path: Path, media_out_dir: Path) -> None:
    media_out_dir.mkdir(parents=True, exist_ok=True)

    with zipfile.ZipFile(docx_path) as z:
        document_xml = z.read("word/document.xml")
        rels_xml = z.read("word/_rels/document.xml.rels")

        rels_root = ET.fromstring(rels_xml)
        rid_to_target: dict[str, str] = {}
        for rel in rels_root.findall("Relationship"):
            rid = rel.attrib.get("Id")
            target = rel.attrib.get("Target")
            if rid and target:
                rid_to_target[rid] = target

        root = ET.fromstring(document_xml)
        lines: list[str] = []
        paragraph_nodes = root.findall(".//w:p", W_NS)

        for p in paragraph_nodes:
            p_style = None
            ppr = p.find("w:pPr", W_NS)
            if ppr is not None:
                ps = ppr.find("w:pStyle", W_NS)
                if ps is not None:
                    p_style = ps.attrib.get(f"{{{W_NS['w']}}}val")

            text_chunks: list[str] = []
            for t in p.findall(".//w:t", W_NS):
                if t.text:
                    text_chunks.append(t.text)
            paragraph_text = _norm_ws("".join(text_chunks))

            # Detect embedded images and export them
            image_rids: list[str] = []
            for blip in p.findall(".//a:blip", {**W_NS, "a": "http://schemas.openxmlformats.org/drawingml/2006/main"}):
                rid = blip.attrib.get(f"{{{R_NS['r']}}}embed")
                if rid:
                    image_rids.append(rid)
            for rid in image_rids:
                target = rid_to_target.get(rid)
                if not target:
                    continue
                # target is like 'media/image1.png'
                media_path = f"word/{target}"
                if media_path not in z.namelist():
                    continue
                blob = z.read(media_path)
                filename = Path(target).name
                out_img = media_out_dir / filename
                out_img.write_bytes(blob)
                lines.append(f"![diagram]({media_out_dir.name}/{filename})")
                lines.append("")

            if not paragraph_text:
                continue

            md_prefix = _style_to_md_prefix(p_style)
            if md_prefix:
                lines.append(f"{md_prefix}{paragraph_text}")
            else:
                lines.append(paragraph_text)
            lines.append("")

    out_md_path.write_text("\n".join(lines), encoding="utf-8")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("--docx", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--media-dir", default="thesis_media")
    args = parser.parse_args()

    docx = Path(args.docx)
    out = Path(args.out)
    media_dir = out.parent / args.media_dir
    docx_to_markdown(docx, out, media_dir)

