# main.jac
import schema.graph_schema;
import walkers.auth;
import walkers.profile;
import walkers.resume;
import walkers.career_fair;
import walkers.fit;
import walkers.generate;

walker Init {
    can enter {
        root = AppRoot();
        here ++> root;
        report {"ok": true, "app": root.app_name};
    }
}

walker SeedDemoData {
    can enter with AppRoot entry {
        e = Event(event_id="ev_1", name="UMich Winter Career Fair", term="Winter 2026",
                  start_date="2026-01-20", end_date="2026-01-21");
        here ++> e;

        c = Company(company_id="co_1", name="Datadog", icon_url="");
        e ++> HasCompany() ++> c;

        r = Role(role_id="role_1", title="Software Engineer Intern",
                 location="NYC", work_mode="Hybrid", sponsorship="Unknown",
                 description="Backend services, distributed systems, Python, SQL",
                 tags=["Python","SQL","Distributed Systems"]);
        e ++> HasRole() ++> r;

        report {"seeded": true};
    }
}
