"""The planning brain: urgency scoring, the daily plan, week load and stats.

Pure functions over TaskView lists, so every rule here is unit tested
without a server.
"""

import datetime;
import from core.dates { days_left, due_label, shift, short_date }
import from core.views { CourseView, Dashboard, DayLoad, Stats, TaskView }

glob UNESTIMATED_MINUTES: int = 30,
     MIN_CHUNK: int = 25,
     SUGGEST_THRESHOLD: float = 1.0,
     PRIORITY_WEIGHT: dict[int, float] = {1: 1.0, 2: 2.0, 3: 3.5};

def bucket_of(left: int | None) -> str {
    if left is None {
        return "someday";
    }
    if left < 0 {
        return "overdue";
    }
    if left == 0 {
        return "today";
    }
    if left == 1 {
        return "tomorrow";
    }
    if left < 7 {
        return "week";
    }
    return "later";
}

"""How much a task deserves attention today.

Priority sets the weight; the deadline sets the pressure, rising sharply
as the due date approaches and capping once overdue. Big tasks due soon
get a bump so they are started early instead of the night before.
"""
def urgency(priority: int, left: int | None, est_minutes: int, done: bool) -> float {
    if done {
        return 0.0;
    }
    weight = PRIORITY_WEIGHT.get(priority, 2.0);
    pressure = 0.4;
    if left is not None {
        if left < 0 {
            pressure = 6.0 + min(-left, 6) * 0.5;
        } elif left == 0 {
            pressure = 5.0;
        } else {
            pressure = 4.0 / left;
        }
        if est_minutes >= 120 and 0 < left and left <= 4 {
            pressure += est_minutes / 120.0;
        }
    }
    return round(weight * pressure, 2);
}

def cost(t: TaskView) -> int {
    return t.est_minutes if t.est_minutes > 0 else UNESTIMATED_MINUTES;
}

def fill_view(t: TaskView, today: datetime.date) -> TaskView {
    left = days_left(t.due, today);
    t.bucket = bucket_of(left);
    t.due_label = due_label(t.due, t.due_time, today);
    t.urgency = urgency(t.priority, left, t.est_minutes, t.done);
    return t;
}

def due_key(t: TaskView) -> str {
    return (t.due or "9999-12-31") + " " + (t.due_time or "99:99");
}

"""Today's plan: everything overdue or due today, then the most urgent
upcoming work until the daily time budget is spent. A big task that does
not fit is split: the plan books the time that is left and says so."""
def build_focus(open_tasks: list[TaskView], capacity: int) -> list[TaskView] {
    must = [
        t
        for t in open_tasks
        if t.bucket in ["overdue", "today"]
    ];
    must.sort(key=lambda (t: TaskView) { -t.urgency; });
    for t in must {
        t.reason = "Overdue" if t.bucket == "overdue" else "Due today";
        t.plan_minutes = cost(t);
    }
    used = sum([cost(t) for t in must]);
    rest = [
        t
        for t in open_tasks
        if t.bucket not in ["overdue", "today"]
    ];
    rest.sort(key=lambda (t: TaskView) { -t.urgency; });
    picked: list[TaskView] = [];
    for t in rest {
        left = capacity - used;
        if t.urgency < SUGGEST_THRESHOLD or left < MIN_CHUNK {
            continue;
        }
        chunk = min(cost(t), left);
        t.plan_minutes = chunk;
        if chunk < cost(t) {
            t.reason = "Start: " + fmt_span(chunk) + " of " + fmt_span(cost(t)) + ", due " + t.due_label;
        } else {
            t.reason = "Get ahead: due " + t.due_label;
        }
        used += chunk;
        picked.append(t);
    }
    return must + picked;
}

def fmt_span(mins: int) -> str {
    (h, m) = (mins // 60, mins % 60);
    if h and m {
        return str(h) + "h" + str(m) + "m";
    }
    return str(h) + "h" if h else str(m) + "m";
}

def build_week(open_tasks: list[TaskView], today: datetime.date) -> list[DayLoad] {
    days: list[DayLoad] = [];
    for i in range(7) {
        d = shift(today, i);
        iso = d.isoformat();
        due_then = [
            t
            for t in open_tasks
            if t.due == iso
        ];
        days.append(
            DayLoad(
                date=iso,
                label="Today" if i == 0 else short_date(d),
                count=len(due_then),
                minutes=sum([cost(t) for t in due_then]),
                is_today=i == 0
            )
        );
    }
    return days;
}

def streak_of(done_days: set[str], today: datetime.date) -> int {
    day = today;
    if day.isoformat() not in done_days {
        day = shift(today, -1);
    }
    n = 0;
    while day.isoformat() in done_days {
        n += 1;
        day = shift(day, -1);
    }
    return n;
}

def build_stats(tasks: list[TaskView], today: datetime.date) -> Stats {
    iso = today.isoformat();
    week_start = shift(today, -6).isoformat();
    open_tasks = [
        t
        for t in tasks
        if not t.done
    ];
    done_days = {t.done_at[:10] for t in tasks if t.done and t.done_at};
    return Stats(
        open_count=len(open_tasks),
        overdue_count=len([t for t in open_tasks if t.bucket == "overdue"]),
        due_today=len([t for t in open_tasks if t.bucket == "today"]),
        done_today=len([t for t in tasks if t.done and t.done_at[:10] == iso]),
        done_week=len(
            [
                t
                for t in tasks
                if t.done and week_start <= t.done_at[:10] and t.done_at[:10] <= iso
            ]
        ),
        streak=streak_of(done_days, today)
    );
}

def build_courses(courses: list[CourseView], tasks: list[TaskView]) -> list[CourseView] {
    for c in courses {
        mine = [
            t
            for t in tasks
            if t.course == c.code
        ];
        open_mine = [
            t
            for t in mine
            if not t.done and t.due
        ];
        open_mine.sort(key=due_key);
        c.open_count = len([t for t in mine if not t.done]);
        c.done_count = len([t for t in mine if t.done]);
        c.next_due = open_mine[0].due_label if open_mine else "";
    }
    courses.sort(key=lambda (c: CourseView) { c.code; });
    return courses;
}

def build_dashboard(
    tasks: list[TaskView],
    courses: list[CourseView],
    capacity: int,
    today: datetime.date
) -> Dashboard {
    for t in tasks {
        fill_view(t, today);
    }
    open_tasks = [
        t
        for t in tasks
        if not t.done
    ];
    focus = build_focus(open_tasks, capacity);
    in_focus = [t.num for t in focus];
    upcoming = [
        t
        for t in open_tasks
        if t.num not in in_focus
    ];
    upcoming.sort(key=due_key);
    week_start = shift(today, -6).isoformat();
    done_recent = [
        t
        for t in tasks
        if t.done and t.done_at[:10] >= week_start
    ];
    done_recent.sort(key=lambda (t: TaskView) { t.done_at; }, reverse=True);
    return Dashboard(
        today=today.isoformat(),
        today_label=today.strftime("%A, %B ") + str(today.day),
        focus=focus,
        planned_minutes=sum([t.plan_minutes for t in focus]),
        capacity=capacity,
        upcoming=upcoming,
        done_recent=done_recent,
        week=build_week(open_tasks, today),
        courses=build_courses(courses, tasks),
        stats=build_stats(tasks, today)
    );
}
