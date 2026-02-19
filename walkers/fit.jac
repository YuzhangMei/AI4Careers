# walkers/fit.jac
import schema.graph_schema;
import utils.security;

walker: pub FitScoreRole {
    has token: str;
    has role_id: str;

    can enter with AppRoot entry {
        uid = security.token_to_user_id(self.token);
        if uid == "" { report {"error":"unauthorized"}; disengage; }

        me: User = null;
        my_resume: Resume = null;

        for u in [-->] :User {
            if u.user_id == uid {
                me = u;
                # choose latest resume (MVP: first one)
                for r in u[-->(OwnsResume)-->] :Resume { my_resume = r; break; }
            }
        }
        if me is null || my_resume is null {
            report {"error":"missing_resume"};
            disengage;
        }

        role: Role = null;
        for rr in [-->] :Role { if rr.role_id == self.role_id { role = rr; } }
        if role is null { report {"error":"role_not_found"}; disengage; }

        # MVP: extremely simple matching: overlap between resume skills and role.tags (or keywords from description)
        role_keywords: list[str] = role.tags;
        if len(role_keywords) == 0 { role_keywords = ["Python", "SQL"]; } # fallback

        matched: list[str] = [];
        missing: list[str] = [];

        for k in role_keywords {
            if k in my_resume.skills { matched.append(k); }
            else { missing.append(k); }
        }

        # score heuristic
        score = int(100 * len(matched) / max(1, len(role_keywords)));

        fit_id = security.fake_uuid("fit");
        fs = FitScore(
            fit_id=fit_id,
            score=score,
            matched_skills=matched,
            missing_skills=missing,
            top_keywords=role_keywords,
            explanation="(MVP) Score based on skill overlap.",
            created_at=security.now_iso()
        );

        me ++> HasFitScore() ++> fs;

        report {
            "score": fs.score,
            "matched_skills": fs.matched_skills,
            "missing_skills": fs.missing_skills,
            "top_keywords": fs.top_keywords,
            "explanation": fs.explanation
        };
    }
}
