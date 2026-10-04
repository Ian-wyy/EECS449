"""StudyPilot backend: the `planner` service app.

Every signed-in user owns a private graph hanging off their root:

    root --> Settings
    root --> Course --Holds--> Task      (coursework)
    root --> Task                        (personal inbox)

All walkers are `:protect`, so each one runs against the caller's own
root. The web, mobile and CLI apps import these walkers with plain
imports; the compiler turns each import into a typed bridge.
"""

import from core.dates { now_iso, today_or }
import from core.plan { build_dashboard, fill_view }
import from core.quickadd { Draft, parse_quick_add }
import from core.views { CourseView, Dashboard, DayLoad, Stats, TaskView }

glob PALETTE: list[str] = [
         "#4f46e5",
         "#db2777",
         "#059669",
         "#ea580c",
         "#0891b2",
         "#9333ea",
         "#ca8a04",
         "#dc2626"
     ],
     MIN_CAPACITY: int = 30,
     MAX_CAPACITY: int = 960;

node Settings {
    has next_num: int = 1,
        daily_minutes: int = 240;
}

node Course {
    has code: str,
        name: str = "",
        color: str = "#4f46e5",
        created_at: str = "";
}

node Task {
    has num: int,
        title: str,
        notes: str = "",
        due: str = "",
        due_time: str = "",
        priority: int = 2,
        est_minutes: int = 0,
        done: bool = False,
        done_at: str = "",
        created_at: str = "";
}

edge Holds: Course --> Task {}

def ensure_settings(r: Root) -> Settings {
    found = [r -->[?:Settings]];
    if found {
        return found[0];
    }
    return r ++> Settings();
}

def clean_code(code: str) -> str {
    return code.strip().lstrip("#").upper().replace(" ", "");
}

def find_course(r: Root, code: str) -> Course | None {
    want = clean_code(code);
    for c in [r -->[?:Course]] {
        if c.code == want {
            return c;
        }
    }
    return None;
}

def ensure_course(r: Root, code: str) -> Course {
    existing = find_course(r, code);
    if existing is not None {
        return existing;
    }
    count = len([r -->[?:Course]]);
    return r ++> Course(
        code=clean_code(code),
        color=PALETTE[count % len(PALETTE)],
        created_at=now_iso()
    );
}

def course_of(t: Task) -> Course | None {
    parents = [t <-:Holds:<-];
    return parents[0] if parents else None;
}

def view_of(t: Task) -> TaskView {
    c = course_of(t);
    return TaskView(
        num=t.num,
        title=t.title,
        notes=t.notes,
        due=t.due,
        due_time=t.due_time,
        priority=t.priority,
        est_minutes=t.est_minutes,
        done=t.done,
        done_at=t.done_at,
        created_at=t.created_at,
        course=c.code if c is not None else "",
        color=c.color if c is not None else ""
    );
}

def course_view(c: Course) -> CourseView {
    return CourseView(code=c.code, name=c.name, color=c.color);
}

def clamp_priority(p: int) -> int {
    return max(1, min(3, p));
}

def create_task(r: Root, draft: Draft, notes: str = "") -> Task {
    settings = ensure_settings(r);
    task = Task(
        num=settings.next_num,
        title=draft.title.strip(),
        notes=notes,
        due=draft.due,
        due_time=draft.due_time,
        priority=clamp_priority(draft.priority),
        est_minutes=max(0, draft.est_minutes),
        created_at=now_iso()
    );
    settings.next_num += 1;
    if draft.course {
        c = ensure_course(r, draft.course);
        c +>:Holds():+> task;
    } else {
        r ++> task;
    }
    return task;
}

"""Re-home a task under another course (or the inbox) without losing it."""
def move_task(r: Root, t: Task, code: str) {
    want = clean_code(code);
    prev = course_of(t);
    have = prev.code if prev is not None else "";
    if want == have {
        return;
    }
    if want {
        target = ensure_course(r, want);
        target +>:Holds():+> t;
    } else {
        r ++> t;
    }
    if prev is not None {
        for e in [edge prev ->:Holds:-> t] {
            del e;
        }
    } else {
        for e in [edge r --> t] {
            del e;
        }
    }
}

"""Everything a client needs in one round trip."""
walker:protect get_dashboard {
    has today: str = "",
        tasks: list[TaskView] = [],
        courses: list[CourseView] = [],
        capacity: int = 240,
        reports: list[Dashboard] = [];

    can start with Root entry {
        self.capacity = ensure_settings(here).daily_minutes;
        visit [-->];
    }

    can on_course with Course entry {
        self.courses.append(course_view(here));
        visit [->:Holds:->];
    }

    can on_task with Task entry {
        self.tasks.append(view_of(here));
    }

    can finish with Root exit {
        report build_dashboard(
            self.tasks, self.courses, self.capacity, today_or(self.today)
        );
    }
}

walker:protect quick_add {
    has text: str = "",
        today: str = "",
        reports: list[TaskView] = [];

    can run with Root entry {
        day = today_or(self.today);
        draft = parse_quick_add(self.text, day);
        if not draft.title {
            return;
        }
        report fill_view(view_of(create_task(here, draft)), day);
    }
}

walker:protect add_task {
    has title: str = "",
        notes: str = "",
        course: str = "",
        due: str = "",
        due_time: str = "",
        priority: int = 2,
        est_minutes: int = 0,
        today: str = "",
        reports: list[TaskView] = [];

    can run with Root entry {
        if not self.title.strip() {
            return;
        }
        draft = Draft(
            title=self.title,
            course=self.course,
            due=self.due,
            due_time=self.due_time,
            priority=self.priority,
            est_minutes=self.est_minutes
        );
        report fill_view(
            view_of(create_task(here, draft, self.notes.strip())),
            today_or(self.today)
        );
    }
}

def all_tasks(r: Root) -> list[Task] {
    found: list[Task] = [r -->[?:Task]];
    for c in [r -->[?:Course]] {
        found.extend([c ->:Holds:->[?:Task]]);
    }
    return found;
}

def task_by_num(r: Root, num: int) -> Task | None {
    for t in all_tasks(r) {
        if t.num == num {
            return t;
        }
    }
    return None;
}

walker:protect toggle_task {
    has num: int = 0,
        today: str = "",
        reports: list[TaskView] = [];

    can find with Root entry {
        t = task_by_num(here, self.num);
        if t is not None {
            visit t;
        }
    }

    can act with Task entry {
        here.done = not here.done;
        here.done_at = now_iso() if here.done else "";
        report fill_view(view_of(here), today_or(self.today));
    }
}

walker:protect update_task {
    has num: int = 0,
        today: str = "",
        title: str = "",
        notes: str = "",
        course: str = "",
        due: str = "",
        due_time: str = "",
        priority: int = 2,
        est_minutes: int = 0,
        reports: list[TaskView] = [];

    can find with Root entry {
        t = task_by_num(here, self.num);
        if t is not None {
            visit t;
        }
    }

    can act with Task entry {
        if self.title.strip() {
            here.title = self.title.strip();
        }
        here.notes = self.notes.strip();
        here.due = self.due;
        here.due_time = self.due_time;
        here.priority = clamp_priority(self.priority);
        here.est_minutes = max(0, self.est_minutes);
        move_task(root, here, self.course);
        report fill_view(view_of(here), today_or(self.today));
    }
}

walker:protect delete_task {
    has num: int = 0,
        reports: list[bool] = [];

    can find with Root entry {
        t = task_by_num(here, self.num);
        if t is not None {
            visit t;
        }
    }

    can act with Task entry {
        del here;
        report True;
    }
}

walker:protect add_course {
    has code: str = "",
        name: str = "",
        color: str = "",
        reports: list[CourseView] = [];

    can run with Root entry {
        if not clean_code(self.code) {
            return;
        }
        c = ensure_course(here, self.code);
        if self.name.strip() {
            c.name = self.name.strip();
        }
        if self.color.strip() {
            c.color = self.color.strip();
        }
        report course_view(c);
    }
}

"""Delete a course; its tasks fall back to the personal inbox."""
walker:protect delete_course {
    has code: str = "",
        reports: list[bool] = [];

    can run with Root entry {
        c = find_course(here, self.code);
        if c is None {
            report False;
            return;
        }
        for t in [c ->:Holds:->[?:Task]] {
            here ++> t;
        }
        del c;
        report True;
    }
}

walker:protect set_capacity {
    has minutes: int = 240,
        reports: list[int] = [];

    can run with Root entry {
        s = ensure_settings(here);
        s.daily_minutes = max(MIN_CAPACITY, min(MAX_CAPACITY, self.minutes));
        report s.daily_minutes;
    }
}
