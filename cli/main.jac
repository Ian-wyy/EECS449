"""plan -- StudyPilot from the terminal.

    jac run cli -- today            (or ./plan today)

Every command except login/signup/logout is a typed bridge call into the
`planner` service of a running StudyPilot server (`jac run`).
"""

import argparse;
import asyncio;
import datetime;
import getpass;
import os;
import sys;
import from jaclang.server.bridge {
    BridgeError,
    BridgeRejected,
    BridgeTimeout,
    BridgeUnavailable
}
import from core.views { CourseView, Dashboard, TaskView }
import from core.planner {
    add_course,
    delete_course,
    delete_task,
    get_dashboard,
    quick_add,
    set_capacity,
    toggle_task,
    update_task
}
import from cli.session {
    Session,
    clear_session,
    connect,
    load_session,
    login,
    register,
    resolve_server,
    save_session
}
import from cli.render {
    bold,
    dim,
    paint,
    render_courses,
    render_list,
    render_today,
    render_week,
    set_color,
    task_line
}

glob PROG: str = "plan",
     EXIT_OK: int = 0,
     EXIT_FAILURE: int = 1,
     EXIT_USAGE: int = 2,
     EXIT_UNAVAILABLE: int = 3,
     EXIT_AUTH: int = 5,
     QUICK_ADD_HELP: str = "#COURSE  !high|!low  @today|@tmr|@fri|@10/31|@+3d  @5pm  ~2h";

def warn(text: str) {
    print(text, file=sys.stderr);
}

def build_parser -> argparse.ArgumentParser {
    parser = argparse.ArgumentParser(
        prog=PROG,
        description="StudyPilot from the terminal. Talks to a running StudyPilot server (jac run).",
        epilog="quick-add syntax: " + QUICK_ADD_HELP
    );
    parser.add_argument(
        "--server", `default="", help="server URL (default: saved, $STUDYPILOT_SERVER, or http://localhost:8000)"
    );
    parser.add_argument("--no-color", action="store_true", help="plain output");
    cmds = parser.add_subparsers(dest="command", metavar="<command>");

    for name in ["login", "signup"] {
        p = cmds.add_parser(name, help=("sign in" if name == "login" else "create an account") + " and remember the session");
        p.add_argument("username", nargs="?", `default="");
        p.add_argument("--password", `default="", help="non-interactive (or set $STUDYPILOT_PASSWORD)");
    }
    cmds.add_parser("logout", help="forget the saved session");
    cmds.add_parser("whoami", help="show the saved session");
    cmds.add_parser("today", help="today's plan (default command)");
    cmds.add_parser("week", help="the next 7 days with workload bars");

    ls = cmds.add_parser("ls", help="all open tasks grouped by due date");
    ls.add_argument("--course", "-c", `default="", help="only this course");
    ls.add_argument("--done", action="store_true", help="also show tasks done this week");

    add = cmds.add_parser("add", help="quick-add a task: plan add Read ch. 4 #EECS449 @fri ~1h");
    add.add_argument("text", nargs="+");

    for name in ["done", "undo", "rm"] {
        helps = {"done": "mark tasks done", "undo": "mark tasks not done", "rm": "delete tasks"};
        p = cmds.add_parser(name, help=helps[name]);
        p.add_argument("nums", nargs="+", `type=int, metavar="NUM");
    }

    edit = cmds.add_parser("edit", help="change fields of a task");
    edit.add_argument("num", `type=int);
    edit.add_argument("--title", `default=None);
    edit.add_argument("--notes", `default=None);
    edit.add_argument("--course", `default=None, help="course code, or '' for none");
    edit.add_argument("--due", `default=None, help="YYYY-MM-DD, or '' for none");
    edit.add_argument("--time", `default=None, help="HH:MM, or '' for none");
    edit.add_argument("--priority", `type=int, choices=[1, 2, 3], `default=None);
    edit.add_argument("--est", `type=int, `default=None, help="estimate in minutes");

    cmds.add_parser("courses", help="courses with progress");
    course = cmds.add_parser("course", help="add or remove a course");
    course.add_argument("action", choices=["add", "rm"]);
    course.add_argument("code");
    course.add_argument("--name", `default="");
    course.add_argument("--color", `default="", help="hex color like #db2777");

    cap = cmds.add_parser("budget", help="set your daily focus budget in minutes");
    cap.add_argument("minutes", `type=int);
    return parser;
}

def today_iso -> str {
    return datetime.date.today().isoformat();
}

def explain(e: BridgeError, server: str) -> int {
    if isinstance(e, BridgeUnavailable) {
        warn("plan: cannot reach the StudyPilot server at " + server);
        warn("hint: start it from the repo root with `jac run`, or pass --server URL");
        return EXIT_UNAVAILABLE;
    }
    if isinstance(e, BridgeRejected) {
        warn("plan: the server rejected the request (" + (e.detail or "not signed in") + ")");
        warn("hint: sign in again with `plan login`");
        return EXIT_AUTH;
    }
    if isinstance(e, BridgeTimeout) {
        warn("plan: the server timed out");
        return EXIT_FAILURE;
    }
    warn("plan: server error (" + (e.detail or "unknown") + ")");
    return EXIT_FAILURE;
}

def ask_password(given: str) -> str {
    if given {
        return given;
    }
    env = os.environ.get("STUDYPILOT_PASSWORD", "");
    if env {
        return env;
    }
    return getpass.getpass("password: ");
}

def run_auth(cmd: str, server: str, username: str, password: str) -> int {
    user = username or input("username: ").strip();
    if not user {
        warn("plan: a username is required");
        return EXIT_USAGE;
    }
    pw = ask_password(password);
    result = register(server, user, pw) if cmd == "signup" else login(server, user, pw);
    if not result.ok {
        warn("plan: " + result.error);
        return EXIT_AUTH;
    }
    save_session(Session(server=server, username=user, token=result.token));
    print("Signed in to " + server + " as " + bold(user) + ". Try: plan today");
    return EXIT_OK;
}

async def fetch_dashboard -> Dashboard {
    res = await get_dashboard(today=today_iso());
    return res.reports[0];
}

def find(d: Dashboard, num: int) -> TaskView | None {
    for t in d.focus + d.upcoming + d.done_recent {
        if t.num == num {
            return t;
        }
    }
    return None;
}

async def run_toggle(nums: list[int], want_done: bool) -> int {
    d = await fetch_dashboard();
    code = EXIT_OK;
    for num in nums {
        t = find(d, num);
        if t is not None and t.done == want_done {
            print(dim("already " + ("done" if want_done else "open") + ": ") + task_line(t).strip());
            continue;
        }
        res = await toggle_task(num=num, today=today_iso());
        if not res.reports {
            warn("plan: no task #" + str(num) + " (or it was finished more than a week ago)");
            code = EXIT_FAILURE;
            continue;
        }
        print(task_line(res.reports[0]).strip());
    }
    if want_done and code == EXIT_OK {
        s = (await fetch_dashboard()).stats;
        print(dim(str(s.done_today) + " done today") + ("  " + paint("🔥 " + str(s.streak) + "-day streak", "33") if s.streak else ""));
    }
    return code;
}

async def run_edit(inv: argparse.Namespace) -> int {
    d = await fetch_dashboard();
    t = find(d, inv.num);
    if t is None {
        warn("plan: no task #" + str(inv.num));
        return EXIT_FAILURE;
    }
    res = await update_task(
        num=t.num,
        title=inv.title if inv.title is not None else t.title,
        notes=inv.notes if inv.notes is not None else t.notes,
        course=inv.course if inv.course is not None else t.course,
        due=inv.due if inv.due is not None else t.due,
        due_time=inv.time if inv.time is not None else t.due_time,
        priority=inv.priority if inv.priority is not None else t.priority,
        est_minutes=inv.est if inv.est is not None else t.est_minutes,
        today=today_iso()
    );
    if not res.reports {
        warn("plan: could not update #" + str(inv.num));
        return EXIT_FAILURE;
    }
    print("updated " + task_line(res.reports[0]).strip());
    return EXIT_OK;
}

async def run_planner(inv: argparse.Namespace) -> int {
    cmd = inv.command or "today";
    if cmd == "today" {
        print(render_today(await fetch_dashboard()));
    } elif cmd == "week" {
        print(render_week(await fetch_dashboard()));
    } elif cmd == "ls" {
        d = await fetch_dashboard();
        want = inv.course.strip().lstrip("#").upper();
        tasks = [t for t in d.focus + d.upcoming if not want or t.course == want];
        done = [t for t in d.done_recent if not want or t.course == want] if inv.done else [];
        print(render_list(tasks, done));
    } elif cmd == "add" {
        made = await quick_add(text=" ".join(inv.text), today=today_iso());
        if not made.reports {
            warn("plan: nothing to add -- the task needs a title besides tags");
            return EXIT_USAGE;
        }
        print("added " + task_line(made.reports[0]).strip());
    } elif cmd == "done" {
        return await run_toggle(inv.nums, True);
    } elif cmd == "undo" {
        return await run_toggle(inv.nums, False);
    } elif cmd == "rm" {
        code = EXIT_OK;
        for num in inv.nums {
            gone = await delete_task(num=num);
            if gone.reports {
                print("deleted #" + str(num));
            } else {
                warn("plan: no task #" + str(num));
                code = EXIT_FAILURE;
            }
        }
        return code;
    } elif cmd == "edit" {
        return await run_edit(inv);
    } elif cmd == "courses" {
        print(render_courses((await fetch_dashboard()).courses));
    } elif cmd == "course" {
        if inv.action == "add" {
            kept = await add_course(code=inv.code, name=inv.name, color=inv.color);
            if not kept.reports {
                warn("plan: invalid course code");
                return EXIT_USAGE;
            }
            c: CourseView = kept.reports[0];
            print("saved course " + c.code);
        } else {
            dropped = await delete_course(code=inv.code);
            if not dropped.reports or not dropped.reports[0] {
                warn("plan: no course " + inv.code.upper());
                return EXIT_FAILURE;
            }
            print("deleted course " + inv.code.upper() + dim(" (its tasks moved to your inbox)"));
        }
    } elif cmd == "budget" {
        budget = await set_capacity(minutes=inv.minutes);
        print("daily focus budget: " + str(budget.reports[0]) + " minutes");
    }
    return EXIT_OK;
}

async def main(argv: list[str]) -> int {
    parser = build_parser();
    inv = parser.parse_args(argv);
    if inv.no_color {
        set_color(False);
    }
    saved = load_session();
    server = resolve_server(inv.server, saved);
    cmd = inv.command or "today";
    if cmd in ["login", "signup"] {
        return run_auth(cmd, server, inv.username, inv.password);
    }
    if cmd == "logout" {
        clear_session();
        print("Signed out.");
        return EXIT_OK;
    }
    if cmd == "whoami" {
        if not saved.token {
            print("Not signed in. Run: plan login");
            return EXIT_AUTH;
        }
        print(saved.username + " @ " + saved.server);
        return EXIT_OK;
    }
    if not saved.token {
        warn("plan: not signed in. Run `plan login` (or `plan signup`) first.");
        return EXIT_AUTH;
    }
    connect(server, saved.token);
    try {
        return await run_planner(inv);
    } except BridgeError as e {
        return explain(e, server);
    }
}

with entry:__main__ {
    sys.`exit(asyncio.run(main(sys.argv[1:])));
}
