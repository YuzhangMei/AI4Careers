import from byllm.lib { Model }
import from typing { Optional }

import re;

glob llm = Model(model_name="gpt-4o"); 


obj Education {
    has degree: str;
    has institution: str;
    has year: Optional[int] = None;
}

obj Experience {
    has title: str;
    has company: str;
    has years: Optional[int] = None;
    has description: str;

obj Resume {
    has name: str;
    has email: str;
    has phone: Optional[str] = None;
    has skills: list[str] = [];
    has education: list[Education] = [];
    has experience: list[Experience] = [];
}

sem Resume.skills = "A list of skills (short canonical names). Examples: Python, SQL, AWS, React, NLP.";
sem Experience.description = "Plain text summary of responsibilities/impact; preserve bullet-like lines if present.";

"""
Parse this resume text into structured data.
Rules:
- Do not invent facts.
- If missing, return empty lists / null (Optional fields).
- Skills should be concise canonical strings.
"""
def parse_resume(text: str) -> Resume by llm(temperature=0.0);


glob ACTION_VERBS = [
    "built","created","designed","developed","implemented","led","owned","shipped","launched",
    "improved","optimized","reduced","increased","accelerated","automated","analyzed","delivered",
    "deployed","tested","validated","integrated","migrated","refactored","collaborated","managed",
    "presented","researched","trained","mentored"
];

obj ChecklistMetrics {
    has total_bullets: int;
    has action_verb_coverage: float;  # 0-100
    has quant_coverage: float;        # 0-100
    has repetition_index: float;      # 0-100 (higher = less repetition)
    has notes: list[str] = [];
}

obj BulletRewrite {
    has original: str;
    has improved: str;
    has reason: str;
}

obj QualityFeedback {
    has star_notes: str;                 
    has issues: list[str];               
    has top_rewrites: list[BulletRewrite];
    has next_steps: list[str];          
}

"""
Given resume text, extracted bullets, and basic metrics, provide:
1) STAR-focused assessment (what's missing: situation/task/action/result)
2) Top issues
3) Up to 3 rewritten bullets (do not add new claims; only rephrase and reorganize)
"""
def llm_quality_feedback(
    resume_text: str,
    bullets: list[str],
    action_verb_coverage: float,
    quant_coverage: float,
    repetition_index: float
) -> QualityFeedback by llm(temperature=0.0, max_tokens=900);


def _strip_bullet_prefix(line: str) -> str {
    # remove common bullet markers
    return line.strip().lstrip("•*-–—").strip();
}

def _first_word(line: str) -> str {
    txt = _strip_bullet_prefix(line);
    parts = txt.split();
    if len(parts) == 0 { return ""; }
    # normalize: remove trailing punctuation
    return parts[0].lower().strip(",:;.");
}

def _starts_with_action_verb(line: str) -> bool {
    w = _first_word(line);
    return w in ACTION_VERBS;
}

def _contains_number(line: str) -> bool {
    # true if any digit exists
    return re.search(r"\d", line) != None;
}

def extract_bullets(resume_text: str) -> list[str] {
    bullets = [];
    for raw in resume_text.splitlines() {
        line = raw.strip();
        if not line { continue; }
        # naive bullet detection
        if line.startswith("•") or line.startswith("-") or line.startswith("*") {
            b = _strip_bullet_prefix(line);
            if b { bullets.append(b); }
        }
    }
    return bullets;
}

def compute_metrics(bullets: list[str]) -> ChecklistMetrics {
    total = len(bullets);
    if total == 0 {
        return ChecklistMetrics(
            total_bullets=0,
            action_verb_coverage=0.0,
            quant_coverage=0.0,
            repetition_index=0.0,
            notes=["No bullet points detected. Consider using bullet format for experience/project impact."]
        );
    }

    action_cnt = 0;
    quant_cnt = 0;
    verb_counts = {};

    for b in bullets {
        if _starts_with_action_verb(b) { action_cnt += 1; }
        if _contains_number(b) { quant_cnt += 1; }

        v = _first_word(b);
        if v {
            verb_counts[v] = verb_counts.get(v, 0) + 1;
        }
    }

    unique_verbs = len(verb_counts);
    repetition_index = (unique_verbs / total) * 100.0;

    notes = [];
    if action_cnt / total < 0.6 {
        notes.append("Low action-verb coverage: many bullets may not start with a strong verb.");
    }
    if quant_cnt / total < 0.3 {
        notes.append("Low quantification: consider adding numbers/metrics where truthful (%, $, time saved, users, latency).");
    }
    if repetition_index < 0.5 * 100.0 {
        notes.append("High repetition: many bullets start with the same verb; vary verbs and focus on distinct outcomes.");
    }

    return ChecklistMetrics(
        total_bullets=total,
        action_verb_coverage=(action_cnt / total) * 100.0,
        quant_coverage=(quant_cnt / total) * 100.0,
        repetition_index=repetition_index,
        notes=notes
    );
}


def resume_to_dict(r: Resume) -> dict {
    return {
        "name": r.name,
        "email": r.email,
        "phone": r.phone,
        "skills": r.skills,
        "education": [
            {"degree": e.degree, "institution": e.institution, "year": e.year}
            for e in r.education
        ],
        "experience": [
            {"title": x.title, "company": x.company, "years": x.years, "description": x.description}
            for x in r.experience
        ]
    };
}

def metrics_to_dict(m: ChecklistMetrics) -> dict {
    return {
        "total_bullets": m.total_bullets,
        "action_verb_coverage": m.action_verb_coverage,
        "quant_coverage": m.quant_coverage,
        "repetition_index": m.repetition_index,
        "notes": m.notes
    };
}

def feedback_to_dict(f: QualityFeedback) -> dict {
    return {
        "star_notes": f.star_notes,
        "issues": f.issues,
        "top_rewrites": [
            {"original": br.original, "improved": br.improved, "reason": br.reason}
            for br in f.top_rewrites
        ],
        "next_steps": f.next_steps
    };
}


walker:pub parse_resume_api {
    has text: str;

    can run with Root entry {
        r = parse_resume(self.text);
        report resume_to_dict(r);
    }
}

walker:pub resume_quality_api {
    has text: str;

    can run with Root entry {
        bullets = extract_bullets(self.text);
        m = compute_metrics(bullets);
        fb = llm_quality_feedback(self.text, bullets, m.action_verb_coverage, m.quant_coverage, m.repetition_index);

        report {
            "metrics": metrics_to_dict(m),
            "bullets_detected": bullets,
            "feedback": feedback_to_dict(fb)
        };
    }
}
