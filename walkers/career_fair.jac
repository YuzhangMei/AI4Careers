# walkers/career_fair.jac
import schema.graph_schema;

walker ListEvents {
    can enter with AppRoot entry {
        out: list[dict] = [];
        for e in [-->] :Event {
            out.append({
                "event_id": e.event_id,
                "name": e.name,
                "term": e.term,
                "start_date": e.start_date,
                "end_date": e.end_date
            });
        }
        report out;
    }
}

walker ListRoles {
    has event_id: str;
    has location: str = "";
    has work_mode: str = "";

    can enter with AppRoot entry {
        out: list[dict] = [];

        # find event
        for e in [-->] :Event {
            if e.event_id == self.event_id {
                for role in e[-->(HasRole)-->] :Role {
                    if self.location != "" && role.location != self.location { continue; }
                    if self.work_mode != "" && role.work_mode != self.work_mode { continue; }

                    # company is optional link; in MVP you can store company_name in Role too
                    out.append({
                        "role_id": role.role_id,
                        "title": role.title,
                        "location": role.location,
                        "work_mode": role.work_mode,
                        "sponsorship": role.sponsorship
                    });
                }
            }
        }
        report out;
    }
}
