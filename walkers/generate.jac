# walkers/generate.jac
import schema.graph_schema;
import utils.security;
import utils.llm;

walker: pub GeneratePitch {
    has token: str;
    has role_id: str;
    has style: str = "career_fair";
    has length: str = "short";

    can enter with AppRoot entry {
        uid = security.token_to_user_id(self.token);
        if uid == "" { report {"error":"unauthorized"}; disengage; }

        me: User = null;
        res: Resume = null;
        for u in [-->] :User {
            if u.user_id == uid {
                me = u;
                for r in u[-->(OwnsResume)-->] :Resume { res = r; break; }
            }
        }
        if me is null || res is null { report {"error":"missing_resume"}; disengage; }

        role: Role = null;
        for rr in [-->] :Role { if rr.role_id == self.role_id { role = rr; } }
        if role is null { report {"error":"role_not_found"}; disengage; }

        prompt = "Generate a " + self.length + " " + self.style + " elevator pitch.\n"
               + "Candidate: " + me.name + "\n"
               + "Role: " + role.title + "\n"
               + "Skills: " + str(res.skills) + "\n"
               + "Top bullets: " + str(res.experience_bullets[0:3]) + "\n";

        content = llm.llm_generate(prompt);

        aid = security.fake_uuid("a");
        art = Artifact(
            artifact_id=aid,
            type="pitch",
            role_id=self.role_id,
            content=content,
            structured={"hook":"", "experience":[], "fit":"", "ask":""},
            model="LLM_STUB",
            prompt_version="v0",
            created_at=security.now_iso()
        );

        me ++> OwnsArtifact() ++> art;

        report {"artifact_id": aid, "content": art.content, "structured": art.structured};
    }
}

walker: pub RewriteResumeForRole {
    has token: str;
    has role_id: str;

    can enter with AppRoot entry {
        uid = security.token_to_user_id(self.token);
        if uid == "" { report {"error":"unauthorized"}; disengage; }

        me: User = null;
        res: Resume = null;
        for u in [-->] :User {
            if u.user_id == uid {
                me = u;
                for r in u[-->(OwnsResume)-->] :Resume { res = r; break; }
            }
        }
        if me is null || res is null { report {"error":"missing_resume"}; disengage; }

        role: Role = null;
        for rr in [-->] :Role { if rr.role_id == self.role_id { role = rr; } }
        if role is null { report {"error":"role_not_found"}; disengage; }

        prompt = "Rewrite resume bullets to better match role.\n"
               + "Role description: " + role.description + "\n"
               + "Original bullets: " + str(res.experience_bullets) + "\n";

        rewritten = llm.llm_generate(prompt);

        aid = security.fake_uuid("a");
        art = Artifact(
            artifact_id=aid,
            type="rewrite",
            role_id=self.role_id,
            content=rewritten,
            structured={"rewritten_bullets": []},
            model="LLM_STUB",
            prompt_version="v0",
            created_at=security.now_iso()
        );

        me ++> OwnsArtifact() ++> art;

        report {"artifact_id": aid, "content": art.content};
    }
}
