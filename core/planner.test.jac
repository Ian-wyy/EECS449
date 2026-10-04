glob DAY: str = "2026-10-04";

def dashboard -> Dashboard {
    return (root spawn get_dashboard(today=DAY)).reports[0];
}

test "quick add files coursework under its course and numbers tasks" {
    a = (root spawn quick_add(text="A1 report #eecs449 !high @mon ~2h", today=DAY)).reports[0];
    b = (root spawn quick_add(text="buy groceries @today", today=DAY)).reports[0];
    assert a.num + 1 == b.num;
    assert a.course == "EECS449";
    assert a.due_label == "Tomorrow";
    assert b.course == "";
    courses = [root -->[?:Course]];
    assert len(courses) == 1;
    assert len([courses[0] ->:Holds:->[?:Task]]) == 1;
    dash = dashboard();
    assert len(dash.courses) == 1;
    assert dash.courses[0].open_count == 1;
    assert b.num in [t.num for t in dash.focus];
}

test "empty quick add reports nothing" {
    assert not (root spawn quick_add(text="#eecs449 !high", today=DAY)).reports;
}

test "toggle, update and delete find tasks inside courses" {
    t = (root spawn quick_add(text="lab 3 #eecs370 @fri", today=DAY)).reports[0];
    done = (root spawn toggle_task(num=t.num, today=DAY)).reports[0];
    assert done.done;
    assert done.done_at;
    undone = (root spawn toggle_task(num=t.num, today=DAY)).reports[0];
    assert not undone.done;
    moved = (
        root spawn update_task(
            num=t.num,
            title="lab 3 (prelab)",
            course="",
            due="2026-10-06",
            priority=1,
            est_minutes=45,
            today=DAY
        )
    ).reports[0];
    assert moved.course == "";
    assert moved.title == "lab 3 (prelab)";
    assert moved.est_minutes == 45;
    assert t.num in [x.num for x in dashboard().upcoming + dashboard().focus];
    back = (
        root spawn update_task(num=t.num, title="lab 3", course="EECS370", today=DAY)
    ).reports[0];
    assert back.course == "EECS370";
    assert (root spawn delete_task(num=t.num)).reports == [True];
    all_nums = [x.num for x in dashboard().upcoming + dashboard().focus];
    assert t.num not in all_nums;
}

test "deleting a course keeps its tasks in the inbox" {
    t = (root spawn quick_add(text="essay draft #eng125", today=DAY)).reports[0];
    assert (root spawn delete_course(code="eng125")).reports == [True];
    left = [x for x in dashboard().upcoming if x.num == t.num];
    assert len(left) == 1;
    assert left[0].course == "";
}

test "courses and capacity settings" {
    c = (root spawn add_course(code="math 217", name="Linear Algebra", color="#123456")).reports[0];
    assert c.code == "MATH217";
    assert c.name == "Linear Algebra";
    assert (root spawn set_capacity(minutes=5)).reports == [30];
    assert dashboard().capacity == 30;
}
