# walkers/resume.jac
import schema.graph_schema;
import utils.security;
import utils.parsing;

walker ResumeUpload {
    has token: str;
    has filename: str;
    has raw_text: str;   # MVP: 先传文本，后续再做文件上传

    can enter with AppRoot entry {
        uid = security.token_to_user_id(self.token);
        if uid == "" { report {"error":"unauthorized"}; disengage; }

        me: User = null;
        for u in [-->] :User { if u.user_id == uid { me = u; } }
        if me is null { report {"error":"unauthorized"}; disengage; }

        rid = security.fake_uuid("r");
        ext = parsing.parse_resume_text(self.raw_text);

        res = Resume(
            resume_id=rid,
            filename=self.filename,
            file_path="",
            uploaded_at=security.now_iso(),
            skills=ext["skills"],
            experience_bullets=ext["experience_bullets"],
            projects=ext["projects"],
            education=ext["education"]
        );

        me ++> OwnsResume() ++> res;

        report {"resume_id": rid, "status": "parsed", "extraction_summary": {"skills_count": len(res.skills)}};
    }
}

walker GetResume {
    has token: str;
    has resume_id: str;

    can enter with AppRoot entry {
        uid = security.token_to_user_id(self.token);
        if uid == "" { report {"error":"unauthorized"}; disengage; }

        # find resume under user
        for u in [-->] :User {
            if u.user_id == uid {
                for r in u[-->(OwnsResume)-->] :Resume {
                    if r.resume_id == self.resume_id {
                        report {
                            "resume_id": r.resume_id,
                            "skills": r.skills,
                            "experience_bullets": r.experience_bullets,
                            "projects": r.projects,
                            "education": r.education
                        };
                        disengage;
                    }
                }
            }
        }
        report {"error":"not_found"};
    }
}
