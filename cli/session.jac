"""Where the CLI's server lives and who it signs in as.

The session (server URL, username, token) is saved to
~/.config/studypilot/session.json so every later command reuses it.
"""

import json;
import os;
import pathlib;
import urllib.error;
import urllib.request;
import from jaclang.server { sv_client }

glob DEFAULT_SERVER: str = "http://localhost:8000",
     SERVER_ENV: str = "STUDYPILOT_SERVER",
     HOME_ENV: str = "STUDYPILOT_HOME",
     PLANNER_APP: str = "planner",
     PLANNER_ROUTE: str = "/api/planner";

obj Session {
    has server: str = "",
        username: str = "",
        token: str = "";
}

obj AuthResult {
    has ok: bool = False,
        token: str = "",
        error: str = "";
}

def session_path -> pathlib.Path {
    home = os.environ.get(HOME_ENV, "");
    base = pathlib.Path(home) if home else pathlib.Path.home() / ".config" / "studypilot";
    return base / "session.json";
}

def load_session -> Session {
    path = session_path();
    if not path.exists() {
        return Session();
    }
    try {
        raw: dict[str, str] = json.loads(path.read_text());
        return Session(
            server=str(raw.get("server", "")),
            username=str(raw.get("username", "")),
            token=str(raw.get("token", ""))
        );
    } except Exception {
        return Session();
    }
}

def save_session(s: Session) {
    path = session_path();
    path.parent.mkdir(parents=True, exist_ok=True);
    path.write_text(
        json.dumps({"server": s.server, "username": s.username, "token": s.token})
    );
    path.chmod(0o600);
}

def clear_session {
    path = session_path();
    if path.exists() {
        path.unlink();
    }
}

"""--server beats $STUDYPILOT_SERVER beats the saved session beats localhost:8000."""
def resolve_server(flag: str, saved: Session) -> str {
    chosen = flag or os.environ.get(SERVER_ENV, "") or saved.server or DEFAULT_SERVER;
    if not chosen.startswith("http://") and not chosen.startswith("https://") {
        chosen = "http://" + chosen;
    }
    return chosen.rstrip("/");
}

def _post(url: str, payload: dict[str, any]) -> dict[str, any] {
    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json"},
        method="POST"
    );
    try {
        with urllib.request.urlopen(req, timeout=10) as resp {
            return json.loads(resp.read() or b"{}");
        }
    } except urllib.error.HTTPError as e {
        try {
            return json.loads(e.read() or b"{}");
        } except Exception {
            return {"ok": False, "error": {"message": "HTTP " + str(e.code)}};
        }
    }
}

def _error_text(body: dict[str, any], fallback: str) -> str {
    err: any = body.get("error") or body.get("detail") or "";
    if isinstance(err, dict) {
        return str(err.get("message") or fallback);
    }
    if isinstance(err, list) and err {
        first: any = err[0];
        return str(first.get("msg") if isinstance(first, dict) else first);
    }
    return str(err) if err else fallback;
}

def login(server: str, username: str, password: str) -> AuthResult {
    try {
        body = _post(
            server + "/user/login",
            {
                "identity": {"type": "username", "value": username},
                "credential": {"type": "password", "password": password}
            }
        );
    } except Exception as e {
        return AuthResult(error="cannot reach " + server + " (" + str(e) + ")");
    }
    data: any = body.get("data") or {};
    if body.get("ok") and isinstance(data, dict) and data.get("token") {
        return AuthResult(ok=True, token=str(data["token"]));
    }
    return AuthResult(error=_error_text(body, "invalid username or password"));
}

def register(server: str, username: str, password: str) -> AuthResult {
    try {
        body = _post(
            server + "/user/register",
            {
                "identities": [{"type": "username", "value": username}],
                "credential": {"type": "password", "password": password}
            }
        );
    } except Exception as e {
        return AuthResult(error="cannot reach " + server + " (" + str(e) + ")");
    }
    if not body.get("ok") {
        return AuthResult(error=_error_text(body, "registration failed"));
    }
    return login(server, username, password);
}

"""Point the typed planner bridge at the server, signed in as this session."""
def connect(server: str, token: str) {
    sv_client.register(PLANNER_APP, server, PLANNER_ROUTE);
    sv_client.set_bearer_token(token);
}
