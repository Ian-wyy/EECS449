"""Wire types shared by the server, web, mobile and CLI.

These are plain objs with no anchors, so every app compiles the same
contract: a server change shows up as a type error in each client.
"""

obj TaskView {
    has num: int = 0,
        title: str = "",
        notes: str = "",
        due: str = "",
        due_time: str = "",
        due_label: str = "",
        bucket: str = "someday",
        priority: int = 2,
        est_minutes: int = 0,
        done: bool = False,
        done_at: str = "",
        created_at: str = "",
        course: str = "",
        color: str = "",
        urgency: float = 0.0,
        plan_minutes: int = 0,
        reason: str = "";
}

obj CourseView {
    has code: str = "",
        name: str = "",
        color: str = "",
        open_count: int = 0,
        done_count: int = 0,
        next_due: str = "";
}

obj DayLoad {
    has date: str = "",
        label: str = "",
        count: int = 0,
        minutes: int = 0,
        is_today: bool = False;
}

obj Stats {
    has open_count: int = 0,
        overdue_count: int = 0,
        due_today: int = 0,
        done_today: int = 0,
        done_week: int = 0,
        streak: int = 0;
}

obj Dashboard {
    has today: str = "",
        today_label: str = "",
        focus: list[TaskView] = [],
        planned_minutes: int = 0,
        capacity: int = 240,
        upcoming: list[TaskView] = [],
        done_recent: list[TaskView] = [],
        week: list[DayLoad] = [],
        courses: list[CourseView] = [],
        stats: Stats = Stats();
}
