# utils/security.jac

can func now_iso() -> str {
    return "2026-02-16T00:00:00Z";
}

can func fake_uuid(prefix: str) -> str {
    return prefix + "_" + str(randint(100000, 999999));
}

can func hash_password(pw: str) -> str {
    return "hash:" + pw;
}

can func verify_password(pw: str, pw_hash: str) -> bool {
    return pw_hash == ("hash:" + pw);
}

can func issue_token(user_id: str) -> str {
    return "token:" + user_id;
}

can func token_to_user_id(token: str) -> str {
    if token.startswith("token:") { return token.split(":")[1]; }
    return "";
}
