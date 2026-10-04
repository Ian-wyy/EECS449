"""usePlanner: the one client-side brain shared by the web and mobile apps.

Session (login / signup / logout), the dashboard, and every mutation live
here; the two renderers only draw. Each mutation is a typed walker spawn
bridged to the `planner` service, followed by one dashboard refresh.
"""

import from "@jac/runtime" {
    jacLogin,
    jacLogout,
    jacSignup,
    jacIsLoggedIn,
    __getLocalStorage,
    __setLocalStorage,
    __removeLocalStorage,
    BridgeError,
    BridgeRejected,
    BridgeUnavailable
}
import from core.planner {
    CourseView,
    Dashboard,
    TaskView,
    add_course,
    delete_course,
    delete_task,
    get_dashboard,
    quick_add,
    set_capacity,
    toggle_task,
    update_task
}

glob USER_KEY: str = "studypilot_username";

obj TaskEdit {
    has num: int = 0,
        title: str = "",
        notes: str = "",
        course: str = "",
        due: str = "",
        due_time: str = "",
        priority: int = 2,
        est_minutes: int = 0;
}

obj PlannerState {
    has loggedIn: bool,
        checking: bool,
        signup: bool,
        username: str,
        password: str,
        authError: str,
        busy: bool,
        dash: Dashboard | None,
        loading: bool,
        refreshing: bool,
        error: str,
        notice: str,
        setUsername: Callable[[str], None],
        setPassword: Callable[[str], None],
        toggleMode: Callable[[], None],
        submit: Callable[[], None],
        logout: Callable[[], None],
        refresh: Callable[[], None],
        quickAdd: Callable[[str], bool],
        toggle: Callable[[int], None],
        saveTask: Callable[[TaskEdit], bool],
        removeTask: Callable[[int], None],
        saveCourse: Callable[[str, str, str], bool],
        removeCourse: Callable[[str], None],
        setBudget: Callable[[int], None],
        dismiss: Callable[[], None];
}

def pad2(n: float) -> str {
    return ("0" if n < 10 else "") + str(n);
}

"""A day relative to today in the viewer's own timezone, as YYYY-MM-DD."""
def:pub local_day(offset: int) -> str {
    d = new(Date);  # jac:ignore[E1053]
    d.setDate(d.getDate() + offset);
    return str(d.getFullYear()) + "-" + pad2(d.getMonth() + 1) + "-" + pad2(d.getDate());
}

def:pub local_today -> str {
    return local_day(0);
}

def:pub edit_of(t: TaskView) -> TaskEdit {
    return TaskEdit(
        num=t.num,
        title=t.title,
        notes=t.notes,
        course=t.course,
        due=t.due,
        due_time=t.due_time,
        priority=t.priority,
        est_minutes=t.est_minutes
    );
}

def:pub fmt_minutes(mins: int) -> str {
    if mins <= 0 {
        return "0m";
    }
    h = mins // 60;
    m = mins % 60;
    if h and m {
        return str(h) + "h " + str(m) + "m";
    }
    return str(h) + "h" if h else str(m) + "m";
}

def:pub usePlanner -> PlannerState {
    has loggedIn: bool = False,
        checking: bool = True,
        signup: bool = False,
        username: str = "",
        password: str = "",
        authError: str = "",
        busy: bool = False,
        dash: Dashboard | None = None,
        loading: bool = False,
        refreshing: bool = False,
        error: str = "",
        notice: str = "";

    can with entry {
        loggedIn = jacIsLoggedIn();
        username = __getLocalStorage(USER_KEY) or "";
        checking = False;
    }

    can with [loggedIn] entry {
        if loggedIn {
            loading = True;
            refresh();
        }
    }

    def flash(text: str) {
        notice = text;
        setTimeout(lambda { notice = ""; }, 2600);  # jac:ignore[E1053]
    }

    def fail(e: any) {
        if isinstance(e, BridgeRejected) {
            error = "Your session expired. Please sign in again.";
            logout();
        } elif isinstance(e, BridgeUnavailable) {
            error = "Can't reach the StudyPilot server. Is `jac run` still running?";
        } elif isinstance(e, BridgeError) {
            error = "The server had a problem: " + str(e.detail or "unknown error");
        } else {
            error = "Something went wrong. Please try again.";
        }
    }

    async def refresh {
        refreshing = True;
        try {
            res = root spawn get_dashboard(today=local_today());
            if res.reports {
                dash = res.reports[0];
            }
            error = "";
        } except Exception as e {
            fail(e);
        } finally {
            loading = False;
            refreshing = False;
        }
    }

    async def submit {
        if busy {
            return;
        }
        authError = "";
        name = username.strip();
        if not name or not password {
            authError = "Please enter a username and password.";
            return;
        }
        if signup and len(password) < 4 {
            authError = "Use at least 4 characters for the password.";
            return;
        }
        busy = True;
        try {
            if signup {
                made = await jacSignup(name, password);
                if not made.success {
                    authError = str(made.error) if made.error else "Could not create that account.";
                    return;
                }
            }
            if await jacLogin(name, password) {
                __setLocalStorage(USER_KEY, name);
                username = name;
                password = "";
                error = "";
                loggedIn = True;
            } else {
                authError = "Wrong username or password.";
            }
        } except Exception {
            authError = "Can't reach the StudyPilot server.";
        } finally {
            busy = False;
        }
    }

    def logout {
        jacLogout();
        __removeLocalStorage(USER_KEY);
        loggedIn = False;
        dash = None;
        password = "";
        signup = False;
    }

    async def quickAdd(text: str) -> bool {
        if not text.strip() {
            return False;
        }
        try {
            res = root spawn quick_add(text=text, today=local_today());
            if not res.reports {
                error = "Give the task a title, not just tags.";
                return False;
            }
            t: TaskView = res.reports[0];
            flash("Added #" + str(t.num) + " · " + t.title + (" · " + t.course if t.course else "") + " · " + t.due_label);
            await refresh();
            return True;
        } except Exception as e {
            fail(e);
        }
        return False;
    }

    async def toggle(num: int) {
        try {
            res = root spawn toggle_task(num=num, today=local_today());
            if res.reports and res.reports[0].done {
                flash("Nice! #" + str(num) + " done.");
            }
            await refresh();
        } except Exception as e {
            fail(e);
        }
    }

    async def saveTask(edit: TaskEdit) -> bool {
        try {
            res = root spawn update_task(
                num=edit.num,
                title=edit.title,
                notes=edit.notes,
                course=edit.course,
                due=edit.due,
                due_time=edit.due_time,
                priority=edit.priority,
                est_minutes=edit.est_minutes,
                today=local_today()
            );
            if not res.reports {
                error = "That task no longer exists.";
                return False;
            }
            flash("Saved #" + str(edit.num));
            await refresh();
            return True;
        } except Exception as e {
            fail(e);
        }
        return False;
    }

    async def removeTask(num: int) {
        try {
            root spawn delete_task(num=num);
            flash("Deleted #" + str(num));
            await refresh();
        } except Exception as e {
            fail(e);
        }
    }

    async def saveCourse(code: str, name: str, color: str) -> bool {
        try {
            res = root spawn add_course(code=code, name=name, color=color);
            if not res.reports {
                error = "Course codes need letters or numbers.";
                return False;
            }
            c: CourseView = res.reports[0];
            flash("Saved " + c.code);
            await refresh();
            return True;
        } except Exception as e {
            fail(e);
        }
        return False;
    }

    async def removeCourse(code: str) {
        try {
            root spawn delete_course(code=code);
            flash("Deleted " + code + " — its tasks moved to your inbox");
            await refresh();
        } except Exception as e {
            fail(e);
        }
    }

    async def setBudget(minutes: int) {
        try {
            root spawn set_capacity(minutes=minutes);
            await refresh();
        } except Exception as e {
            fail(e);
        }
    }

    return PlannerState(
        loggedIn=loggedIn,
        checking=checking,
        signup=signup,
        username=username,
        password=password,
        authError=authError,
        busy=busy,
        dash=dash,
        loading=loading,
        refreshing=refreshing,
        error=error,
        notice=notice,
        setUsername=lambda (v: str) { username = v; },
        setPassword=lambda (v: str) { password = v; },
        toggleMode=lambda {
            signup = not signup;
            authError = "";
        },
        submit=submit,
        logout=logout,
        refresh=refresh,
        quickAdd=quickAdd,
        toggle=toggle,
        saveTask=saveTask,
        removeTask=removeTask,
        saveCourse=saveCourse,
        removeCourse=removeCourse,
        setBudget=setBudget,
        dismiss=lambda { error = ""; }
    );
}
