import from core.views { Dashboard, DayLoad, TaskView }
import from cli.render { render_today, render_week, set_color, task_line }
import from cli.session { Session, resolve_server }

test "today is the default command and nums parse as ints" {
    p = build_parser();
    assert p.parse_args([]).command is None;
    assert p.parse_args(["done", "3", "7"]).nums == [3, 7];
    assert p.parse_args(["add", "Read", "#EECS449", "@fri"]).text == ["Read", "#EECS449", "@fri"];
    assert p.parse_args(["--server", "x:9", "today"]).server == "x:9";
}

test "edit only sends the fields given" {
    inv = build_parser().parse_args(["edit", "4", "--due", "", "--priority", "3"]);
    assert inv.num == 4;
    assert inv.due == "";
    assert inv.priority == 3;
    assert inv.title is None;
}

test "server resolution order" {
    saved = Session(server="http://saved:1");
    assert resolve_server("flag:2", saved) == "http://flag:2";
    assert resolve_server("", saved) == "http://saved:1";
    assert resolve_server("", Session()).startswith("http://");
}

test "rendering without color" {
    set_color(False);
    t = TaskView(
        num=12,
        title="Finish A1",
        due_label="Today 5pm",
        bucket="today",
        priority=3,
        est_minutes=90,
        course="EECS449",
        reason="Due today"
    );
    line = task_line(t, show_reason=True);
    assert "#12" in line;
    assert "!!!" in line;
    assert "EECS449" in line;
    assert "~1h30m" in line;
    assert "· Due today" in line;
    d = Dashboard(today_label="Sunday, October 4", focus=[t], planned_minutes=90);
    assert "Today's plan" in render_today(d);
    d.week = [DayLoad(date="2026-10-04", label="Today", count=1, minutes=90, is_today=True)];
    assert "1 due, 1h30m" in render_week(d);
}
