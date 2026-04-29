STUDENT_DOMAINS = [
    ".edu", ".edu.pk", ".ac.uk",
    ".ac.jp", ".ac.au", ".edu.au",
    ".ac.nz", ".edu.sg",
]

def is_student_email(email: str) -> bool:
    email_lower = email.lower()
    return any(email_lower.endswith(domain) for domain in STUDENT_DOMAINS)