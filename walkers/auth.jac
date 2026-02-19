# walkers/auth.jac
import schema.graph_schema;
import utils.security;

walker: pub Signup {
    has email: str;
    has password: str;
    has name: str;

    can enter with AppRoot entry {
        # naive duplicate check
        # to be implemented in the future
        existing: list[User] = [];
        visit [-->] else {

        };  # no-op in MVP

        # Create user
        uid = security.fake_uuid("u");
        # Create a new node specific to the new user
        new_user = User(
            user_id=uid,
            email=self.email,
            password_hash=security.hash_password(self.password),
            name=self.name,
            created_at=security.now_iso()
        );
        # Create a link that connects to the new node
        here ++> new_user; 
        report {"user_id": uid};
    }
}

walker: pub Login {
    has email: str;
    has password: str;

    can enter with AppRoot entry {
        # MVP: traverse all users (index to be added in the future)
        found: User = null;
        for u in [-->] :User {
            if u.email == self.email {
                found = u;
            }
        }
        if found is null {
            report {"error": "invalid_credentials"};
            disengage;
        }

        if !security.verify_password(self.password, found.password_hash) {
            report {"error": "invalid_credentials"};
            disengage;
        }

        tok = security.issue_token(found.user_id);
        report {"token": tok};
    }
}
