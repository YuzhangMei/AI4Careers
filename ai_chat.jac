import json;

import from db {
    get_latest_resume,
    get_all_events,
    get_companies,
    get_company,
    get_roles,
    get_user_by_id
}
import from security { token_to_user_id }

glob DEFAULT_EVENT_ID: str = "evt_umich_fall_2025";

obj CareerFairAssistant {
    has user_id: str;
    has event_id: str = DEFAULT_EVENT_ID;

    def get_resume_text() -> str {
        resume = get_latest_resume(self.user_id);
        if resume is None {
            return "No resume found for this user.";
        }

        raw_text = resume["raw_text"] if "raw_text" in resume else "";
        if raw_text == "" {
            return "Resume exists, but raw text is empty.";
        }

        return raw_text;
    }

    def get_user_profile() -> str {
        user = get_user_by_id(self.user_id);
        if user is None {
            return "User not found.";
        }

        profile = {
            "user_id": user["user_id"],
            "name": user["name"],
            "email": user["email"],
            "needs_sponsorship": user["needs_sponsorship"],
            "work_authorization": user["work_authorization"],
            "preferred_locations": user["preferred_locations"],
            "work_modes": user["work_modes"],
            "role_types": user["role_types"]
        };
        return json.dumps(profile);
    }

    def list_event_summary() -> str {
        events = get_all_events();
        return json.dumps(events);
    }

    def list_companies_for_event() -> str {
        companies = get_companies(
            self.event_id,
            {
                "fair_day": "",
                "position_type": "",
                "sponsors": "",
                "region": "",
                "major_search": ""
            }
        );
        return json.dumps(companies);
    }

    def search_companies(query: str) -> str {
        companies = get_companies(
            self.event_id,
            {
                "fair_day": "",
                "position_type": "",
                "sponsors": "",
                "region": "",
                "major_search": ""
            }
        );

        q = query.lower().strip();
        if q == "" {
            return json.dumps(companies[:20]);
        }

        matched: list = [];
        for company in companies {
            haystack = (
                company["name"] + " " + company["fair_day"] + " " + " ".join(
                    company["positions"]
                ) + " " + " ".join(company["degree_levels"]) + " " + " ".join(
                    company["sponsorship"]
                ) + " " + " ".join(company["regions"]) + " " + company["description"]
            ).lower();

            if q in haystack {
                matched.append(company);
            }
        }

        return json.dumps(matched[:20]);
    }

    def get_company_details(company_id: str) -> str {
        company = get_company(self.event_id, company_id);
        if company is None {
            return "Company not found.";
        }
        return json.dumps(company);
    }

    def list_roles_for_event() -> str {
        roles = get_roles(self.event_id);
        return json.dumps(roles);
    }

    def search_roles(query: str) -> str {
        roles = get_roles(self.event_id);
        q = query.lower().strip();

        if q == "" {
            return json.dumps(roles[:30]);
        }

        matched: list = [];
        for role in roles {
            haystack = (
                role["title"] + " " + role["location"] + " " + role["work_mode"] + " " + role[
                    "sponsorship"
                ]
            ).lower();

            if q in haystack {
                matched.append(role);
            }
        }

        return json.dumps(matched[:30]);
    }

    def answer(question: str, history_text: str) -> str by llm(
        tools=[
            self.get_resume_text,
            self.get_user_profile,
            self.list_event_summary,
            self.list_companies_for_event,
            self.search_companies,
            self.get_company_details,
            self.list_roles_for_event,
            self.search_roles
        ]
    );
}

sem CareerFairAssistant.answer = "You are an AI career fair assistant for a University of Michigan student. Answer naturally and helpfully. Use tools before making claims about the student's resume or the career fair database. If asked for the best-fit companies, compare the student's resume, profile, locations, sponsorship needs, and company/role information, then recommend a few concrete companies with reasons. If resume data is missing, say so clearly and ask the user to upload one.";
sem CareerFairAssistant.answer.question = "The user's newest chat message.";
sem CareerFairAssistant.answer.history_text = "Conversation history formatted as plain text, oldest to newest.";

sem CareerFairAssistant.get_resume_text = "Get the latest uploaded resume text for the current user.";
sem CareerFairAssistant.get_user_profile = "Get the current user's stored profile and job preferences.";
sem CareerFairAssistant.list_event_summary = "List available career fair events in the database.";
sem CareerFairAssistant.list_companies_for_event = "List company summaries for the current career fair event.";
sem CareerFairAssistant.search_companies = "Search company summaries by keyword such as software, robotics, sponsorship, Michigan, or a company name.";
sem CareerFairAssistant.get_company_details = "Get full details for one company using company_id.";
sem CareerFairAssistant.list_roles_for_event = "List role summaries for the current event.";
sem CareerFairAssistant.search_roles = "Search role summaries by keyword such as intern, software, ML, data, embedded, or location.";

def history_to_text(history: list) -> str {
    lines: list[str] = [];

    for msg in history {
        role = msg["role"] if "role" in msg else "user";
        content = msg["content"] if "content" in msg else "";
        lines.append(role + ": " + content);
    }

    return "\n".join(lines);
}

walker:pub ChatWithAI {
    has token: str;
    has question: str;
    has history: list = [];
    has event_id: str = DEFAULT_EVENT_ID;

    can chat with Root entry {
        uid = token_to_user_id(self.token);
        if uid == "" {
            report {"error": "unauthorized"};
            return;
        }

        assistant = CareerFairAssistant(user_id=uid, event_id=self.event_id);
        history_text = history_to_text(self.history);

        try {
            answer = assistant.answer(self.question, history_text);
            report {"answer": answer};
        } except Exception as e {
            report {"error": "ai_chat_failed", "details": str(e)};
        }
    }
}
