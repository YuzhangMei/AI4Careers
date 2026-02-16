# schema/graph_schema.jac
node AppRoot {
    has app_name: str = "AI4Career";
}

# ========== User & Auth ==========
node User {
    has user_id: str;
    has email: str;
    has password_hash: str;
    has name: str;
    has created_at: str;
    has needs_sponsorship: bool = false;
    has work_authorization: str = "";
    has preferred_locations: list[str] = [];
    has work_modes: list[str] = [];
    has role_types: list[str] = [];
}

edge OwnsResume;
edge OwnsArtifact;
edge HasFitScore;

# ========== Resume ==========
node Resume {
    has resume_id: str;
    has filename: str;
    has file_path: str;
    has uploaded_at: str;
    # extraction (MVP: store directly as fields; later you can normalize)
    has skills: list[str] = [];
    has experience_bullets: list[str] = [];
    has projects: list[str] = [];
    has education: dict = {};
}

# ========== Career Fair Data ==========
node Event {
    has event_id: str;
    has name: str;
    has term: str;
    has start_date: str;
    has end_date: str;
}

edge HasCompany;
edge HasRole;

node Company {
    has company_id: str;
    has name: str;
    has icon_url: str = "";
}

node Role {
    has role_id: str;
    has title: str;
    has location: str = "";
    has work_mode: str = "";
    has sponsorship: str = "Unknown";
    has description: str = "";
    # Optional structured metadata for filtering / keywords
    has tags: list[str] = [];
}

# ========== Fit & Artifacts ==========
node FitScore {
    has fit_id: str;
    has score: int;
    has matched_skills: list[str] = [];
    has missing_skills: list[str] = [];
    has top_keywords: list[str] = [];
    has explanation: str = "";
    has created_at: str = "";
}

node Artifact {
    has artifact_id: str;
    has type: str;  # pitch | rewrite | cover_letter
    has role_id: str = "";
    has content: str = "";
    has structured: dict = {};
    has model: str = "";
    has prompt_version: str = "v0";
    has created_at: str = "";
}
