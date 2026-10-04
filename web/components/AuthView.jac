"""Sign in / create account."""

import from core.state { PlannerState }
import from .Sidebar { Brand }

def:pub AuthView(model: PlannerState) -> JsxElement {
    <div className="auth">
        <div className="auth-card">
            <Brand/>
            <h1>{"Create your planner" if model.signup else "Welcome back"}</h1>
            <p className="lead">
                {"One plan for coursework and life, on web, phone and terminal."
                    if model.signup
                    else "Sign in to see today's plan."}
            </p>
            {if model.authError {
                <div className="alert">{model.authError}</div>
            }}
            <form
                onSubmit={lambda (e: FormEvent) {
                    e.preventDefault();
                    model.submit();
                }}
            >
                <div className="field">
                    <label>Username</label>
                    <input
                        className="input"
                        autoComplete="username"
                        value={model.username}
                        onChange={lambda (e: ChangeEvent) { model.setUsername(e.target.value); }}
                    />
                </div>
                <div className="field">
                    <label>Password</label>
                    <input
                        className="input"
                        type="password"
                        autoComplete={"new-password" if model.signup else "current-password"}
                        value={model.password}
                        onChange={lambda (e: ChangeEvent) { model.setPassword(e.target.value); }}
                    />
                </div>
                <button className="btn primary block" type="submit" disabled={model.busy}>
                    {"Please wait…" if model.busy else ("Create account" if model.signup else "Sign in")}
                </button>
            </form>
            <div className="auth-foot">
                {"Already have an account? " if model.signup else "New here? "}
                <button className="link" type="button" onClick={lambda { model.toggleMode(); }}>
                    {"Sign in" if model.signup else "Create an account"}
                </button>
            </div>
        </div>
    </div>
}
