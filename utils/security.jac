# utils/security.jac

# now_iso: indicate current time
# better time function/extension to be implemented in the future
def now_iso() -> str {
    return "2026-02-16T00:00:00Z";
}

def fake_uuid(prefix: str) -> str {
    import random;
    return f"{prefix}_{random.randint(100000, 999999)}";
}

# Only used for MVP
# Encryption to be applied in the future
def hash_password(pw: str) -> str {
    return "hash:" + pw;
}

def verify_password(pw: str, pw_hash: str) -> bool {
    return pw_hash == ("hash:" + pw);
}

def issue_token(user_id: str) -> str {
    return "token:" + user_id;
}

# Encryption to be applied in the future
def token_to_user_id(token: str) -> str {
    if token.startswith("token:") {
        return token.split(":")[1];
    }
    return "";
}
