import datetime;
import from core.views { CourseView, TaskView }

glob TODAY: datetime.date = datetime.date(2026, 10, 4);

def task(
    num: int,
    due: str = "",
    priority: int = 2,
    est: int = 0,
    done: bool = False,
    done_at: str = "",
    course: str = ""
) -> TaskView {
    return TaskView(
        num=num,
        title="t" + str(num),
        due=due,
        priority=priority,
        est_minutes=est,
        done=done,
        done_at=done_at,
        course=course
    );
}

test "buckets follow the calendar" {
    assert bucket_of(None) == "someday";
    assert bucket_of(-2) == "overdue";
    assert bucket_of(0) == "today";
    assert bucket_of(1) == "tomorrow";
    assert bucket_of(5) == "week";
    assert bucket_of(10) == "later";
}

test "urgency rises with priority and as the deadline nears" {
    assert urgency(3, 1, 0, False) > urgency(2, 1, 0, False);
    assert urgency(2, 1, 0, False) > urgency(2, 4, 0, False);
    assert urgency(2, 0, 0, False) > urgency(2, 1, 0, False);
    assert urgency(2, -1, 0, False) > urgency(2, 0, 0, False);
    assert urgency(1, None, 0, False) < urgency(1, 6, 0, False);
    assert urgency(3, 1, 0, True) == 0.0;
}

test "big tasks due soon get started early" {
    assert urgency(2, 3, 240, False) > urgency(2, 3, 30, False);
    assert urgency(2, 10, 240, False) == urgency(2, 10, 30, False);
}

test "focus takes everything due, then fills the budget by urgency" {
    tasks = [
        task(1, due="2026-10-02"),
        task(2, due="2026-10-04", est=60),
        task(3, due="2026-10-05", priority=3, est=90),
        task(4, due="2026-10-06", est=200),
        task(5),
        task(6, due="2026-10-30")
    ];
    dash = build_dashboard(tasks, [], 240, TODAY);
    nums = [t.num for t in dash.focus];
    assert nums == [1, 2, 3, 4];
    assert dash.focus[0].reason == "Overdue";
    assert dash.focus[2].reason == "Get ahead: due Tomorrow";
    assert dash.focus[3].plan_minutes == 60;
    assert dash.focus[3].reason == "Start: 1h of 3h20m, due Tue";
    assert dash.planned_minutes == 240;
    assert [t.num for t in dash.upcoming] == [6, 5];
}

test "week load and stats" {
    tasks = [
        task(1, due="2026-10-04", est=60),
        task(2, due="2026-10-04"),
        task(3, due="2026-10-06"),
        task(4, done=True, done_at="2026-10-04T09:00:00"),
        task(5, done=True, done_at="2026-10-03T22:00:00"),
        task(6, done=True, done_at="2026-10-01T10:00:00"),
        task(7, due="2026-09-30")
    ];
    dash = build_dashboard(tasks, [], 240, TODAY);
    assert len(dash.week) == 7;
    assert dash.week[0].is_today;
    assert dash.week[0].count == 2;
    assert dash.week[0].minutes == 90;
    assert dash.week[2].count == 1;
    assert dash.stats.open_count == 4;
    assert dash.stats.overdue_count == 1;
    assert dash.stats.due_today == 2;
    assert dash.stats.done_today == 1;
    assert dash.stats.done_week == 3;
    assert dash.stats.streak == 2;
    assert [t.num for t in dash.done_recent] == [4, 5, 6];
}

test "course progress and next deadline" {
    tasks = [
        task(1, due="2026-10-08", course="EECS449"),
        task(2, due="2026-10-05", course="EECS449"),
        task(3, done=True, done_at="2026-10-03T10:00:00", course="EECS449"),
        task(4, course="MATH217")
    ];
    courses = [CourseView(code="MATH217"), CourseView(code="EECS449")];
    dash = build_dashboard(tasks, courses, 240, TODAY);
    assert [c.code for c in dash.courses] == ["EECS449", "MATH217"];
    eecs = dash.courses[0];
    assert eecs.open_count == 2;
    assert eecs.done_count == 1;
    assert eecs.next_due == "Tomorrow";
    assert dash.courses[1].next_due == "";
}

test "due labels" {
    assert due_label("", "", TODAY) == "No date";
    assert due_label("2026-10-04", "17:00", TODAY) == "Today 5pm";
    assert due_label("2026-10-05", "09:30", TODAY) == "Tomorrow 9:30am";
    assert due_label("2026-10-03", "", TODAY) == "Yesterday";
    assert due_label("2026-10-01", "", TODAY) == "Overdue 3d";
    assert due_label("2026-10-09", "", TODAY) == "Fri";
    assert due_label("2026-10-20", "", TODAY) == "Tue 10/20";
}
