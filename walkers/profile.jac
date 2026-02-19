# walkers/profile.jac
import schema.graph_schema;
import utils.security;

walker: pub Me {
    has token: str;

    can enter with AppRoot entry {
        uid = security.token_to_user_id(self.token);
        if uid == "" { report {"error":"unauthorized"}; disengage; }

        me: User = null;
        for u in [-->] :User {
            if u.user_id == uid { me = u; }
        }
        if me is null { report {"error":"unauthorized"}; disengage; }

        report {
            "user_id": me.user_id,
            "name": me.name,
            "preferences": {
                "needs_sponsorship": me.needs_sponsorship,
                "work_authorization": me.work_authorization,
                "preferred_locations": me.preferred_locations,
                "work_modes": me.work_modes,
                "role_types": me.role_types
            }
        };
    }
}

walker: pub UpdatePreferences {
    has token: str;
    has needs_sponsorship: bool;
    has work_authorization: str;
    has preferred_locations: list[str];
    has work_modes: list[str];
    has role_types: list[str];

    can enter with AppRoot entry {
        uid = security.token_to_user_id(self.token);
        if uid == "" { report {"error":"unauthorized"}; disengage; }

        me: User = null;
        for u in [-->] :User {
            if u.user_id == uid { me = u; }
        }
        if me is null { report {"error":"unauthorized"}; disengage; }

        me.needs_sponsorship = self.needs_sponsorship;
        me.work_authorization = self.work_authorization;
        me.preferred_locations = self.preferred_locations;
        me.work_modes = self.work_modes;
        me.role_types = self.role_types;

        report {"ok": true};
    }
}
