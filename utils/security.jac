# utils/security.jac

can func now_iso() -> str {
    # MVP: 你可以用更好的时间函数/插件
    return "2026-02-16T00:00:00Z";
}

can func fake_uuid(prefix: str) -> str {
    # MVP: 简易唯一 id（真实项目要换成 uuid）
    return prefix + "_" + str(randint(100000, 999999));
}

can func hash_password(pw: str) -> str {
    # MVP stub: 别用于生产
    return "hash:" + pw;
}

can func verify_password(pw: str, pw_hash: str) -> bool {
    return pw_hash == ("hash:" + pw);
}

can func issue_token(user_id: str) -> str {
    # MVP stub: 别用于生产
    return "token:" + user_id;
}

can func token_to_user_id(token: str) -> str {
    if token.startswith("token:") { return token.split(":")[1]; }
    return "";
}
