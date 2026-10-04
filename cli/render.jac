"""Terminal rendering. Colors switch off for pipes and under NO_COLOR."""

import os;
import sys;
import from core.views { CourseView, Dashboard, DayLoad, TaskView }

glob USE_COLOR: list[bool] = [sys.stdout.isatty() and not os.environ.get("NO_COLOR")],
     RESET: str = "\x1b[0m",
     BUCKET_TITLES: dict[str, str] = {
         "overdue": "Overdue",
         "today": "Today",
         "tomorrow": "Tomorrow",
         "week": "This week",
         "later": "Later",
         "someday": "No date"
     },
     BUCKET_ORDER: list[str] = ["overdue", "today", "tomorrow", "week", "later", "someday"];

def set_color(on: bool) {
    USE_COLOR[0] = on;
}

def paint(text: str, code: str) -> str {
    return "\x1b[" + code + "m" + text + RESET if USE_COLOR[0] and text else text;
}

def bold(text: str) -> str {
    return paint(text, "1");
}

def dim(text: str) -> str {
    return paint(text, "2");
}

def hex_paint(text: str, color: str) -> str {
    if not color.startswith("#") or len(color) != 7 {
        return paint(text, "36");
    }
    try {
        (r, g, b) = (int(color[1:3], 16), int(color[3:5], 16), int(color[5:7], 16));
    } except ValueError {
        return paint(text, "36");
    }
    return paint(text, "1;38;2;" + str(r) + ";" + str(g) + ";" + str(b));
}

def fmt_minutes(mins: int) -> str {
    if mins <= 0 {
        return "";
    }
    (h, m) = (mins // 60, mins % 60);
    if h and m {
        return str(h) + "h" + str(m) + "m";
    }
    return str(h) + "h" if h else str(m) + "m";
}

def priority_mark(p: int) -> str {
    if p >= 3 {
        return paint("!!!", "1;31");
    }
    if p <= 1 {
        return dim("low");
    }
    return "   ";
}

def due_mark(t: TaskView) -> str {
    if t.done {
        return dim(t.due_label);
    }
    if t.bucket == "overdue" {
        return paint(t.due_label, "1;31");
    }
    if t.bucket == "today" {
        return paint(t.due_label, "1;33");
    }
    if t.bucket == "someday" {
        return dim(t.due_label);
    }
    return t.due_label;
}

def pad(text: str, width: int) -> str {
    return text + " " * max(0, width - len(text));
}

def task_line(t: TaskView, show_reason: bool = False) -> str {
    box = paint("✔", "32") if t.done else "○";
    num = dim(pad("#" + str(t.num), 5));
    title = dim(t.title) if t.done else t.title;
    parts = [num + box + " " + priority_mark(t.priority) + " " + title];
    if t.course {
        parts.append(hex_paint(t.course, t.color));
    }
    parts.append(due_mark(t));
    if t.est_minutes {
        parts.append(dim("~" + fmt_minutes(t.est_minutes)));
    }
    line = "  " + "  ".join(parts);
    if show_reason and t.reason {
        line += "  " + dim("· " + t.reason);
    }
    return line;
}

def header(d: Dashboard) -> list[str] {
    s = d.stats;
    budget = fmt_minutes(d.planned_minutes) or "0m";
    lines = [
        bold("StudyPilot") + dim("  ·  ") + d.today_label + dim("  ·  ")
            + budget + " planned of " + fmt_minutes(d.capacity)
    ];
    bits = [str(s.done_today) + " done today", str(s.done_week) + " this week"];
    if s.streak {
        bits.append(paint("🔥 " + str(s.streak) + "-day streak", "33"));
    }
    if s.overdue_count {
        bits.append(paint(str(s.overdue_count) + " overdue", "31"));
    }
    lines.append(dim("  ") + dim(" · ").join(bits));
    return lines;
}

def render_today(d: Dashboard) -> str {
    lines = header(d);
    lines.append("");
    lines.append(bold("Today's plan"));
    if not d.focus {
        lines.append(
            dim("  Nothing due. Add something: plan add \"Read ch. 4 #EECS449 @fri ~1h\"")
        );
    }
    for t in d.focus {
        lines.append(task_line(t, show_reason=True));
    }
    nxt = d.upcoming[:5];
    if nxt {
        lines.append("");
        lines.append(bold("Coming up") + dim("  (plan ls for everything)"));
        for t in nxt {
            lines.append(task_line(t));
        }
    }
    return "\n".join(lines);
}

def render_list(tasks: list[TaskView], show_done: list[TaskView]) -> str {
    lines: list[str] = [];
    for b in BUCKET_ORDER {
        group = [
            t
            for t in tasks
            if t.bucket == b
        ];
        if not group {
            continue;
        }
        lines.append(bold(BUCKET_TITLES[b]) + dim(" (" + str(len(group)) + ")"));
        for t in group {
            lines.append(task_line(t));
        }
    }
    if show_done {
        lines.append(bold("Done this week") + dim(" (" + str(len(show_done)) + ")"));
        for t in show_done {
            lines.append(task_line(t));
        }
    }
    if not lines {
        return dim("No tasks here.");
    }
    return "\n".join(lines);
}

def load_bar(day: DayLoad, capacity: int) -> str {
    width = 20;
    filled = min(width, round(width * day.minutes / max(capacity, 1)));
    color = "32" if day.minutes <= capacity * 0.75 else ("33" if day.minutes <= capacity else "31");
    return paint("█" * filled, color) + dim("·" * (width - filled));
}

def render_week(d: Dashboard) -> str {
    lines = [bold("Next 7 days") + dim("  (bar = workload vs your daily budget)")];
    open_tasks = d.focus + d.upcoming;
    for day in d.week {
        label = pad(day.label, 10);
        summary = str(day.count) + " due" + (", " + fmt_minutes(day.minutes) if day.count else "");
        lines.append(
            "  " + (bold(label) if day.is_today else label) + " " + load_bar(day, d.capacity)
                + "  " + dim(summary)
        );
        for t in open_tasks {
            if t.due == day.date {
                lines.append("      " + task_line(t).strip());
            }
        }
    }
    return "\n".join(lines);
}

def render_courses(courses: list[CourseView]) -> str {
    if not courses {
        return dim("No courses yet. Tag a task with #CODE or: plan course add EECS449");
    }
    lines = [bold("Courses")];
    for c in courses {
        total = c.open_count + c.done_count;
        pct = round(100 * c.done_count / total) if total else 0;
        bar_w = 12;
        filled = round(bar_w * pct / 100);
        bar = hex_paint("█" * filled, c.color) + dim("·" * (bar_w - filled));
        nxt = "  next: " + c.next_due if c.next_due else "";
        lines.append(
            "  " + hex_paint(pad(c.code, 10), c.color) + " " + bar + " "
                + pad(str(pct) + "%", 5) + dim(
                str(c.open_count) + " open, " + str(c.done_count) + " done" + nxt
            ) + ("  " + dim(c.name) if c.name else "")
        );
    }
    return "\n".join(lines);
}
