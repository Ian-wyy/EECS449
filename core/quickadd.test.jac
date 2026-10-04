import datetime;

glob SUNDAY: datetime.date = datetime.date(2026, 10, 4);

test "plain text is just a title" {
    d = parse_quick_add("call mom", SUNDAY);
    assert d.title == "call mom";
    assert d.course == "";
    assert d.due == "";
    assert d.priority == 2;
    assert d.est_minutes == 0;
}

test "every token kind parses out of the title" {
    d = parse_quick_add("Finish A1 writeup #eecs449 !high @mon @5pm ~2h", SUNDAY);
    assert d.title == "Finish A1 writeup";
    assert d.course == "EECS449";
    assert d.priority == 3;
    assert d.due == "2026-10-05";
    assert d.due_time == "17:00";
    assert d.est_minutes == 120;
}

test "relative and absolute dates" {
    assert parse_date_word("today", SUNDAY) == "2026-10-04";
    assert parse_date_word("tmr", SUNDAY) == "2026-10-05";
    assert parse_date_word("sun", SUNDAY) == "2026-10-04";
    assert parse_date_word("Friday", SUNDAY) == "2026-10-09";
    assert parse_date_word("+3d", SUNDAY) == "2026-10-07";
    assert parse_date_word("+2w", SUNDAY) == "2026-10-18";
    assert parse_date_word("10/31", SUNDAY) == "2026-10-31";
    assert parse_date_word("1/15", SUNDAY) == "2027-01-15";
    assert parse_date_word("2026-12-01", SUNDAY) == "2026-12-01";
    assert parse_date_word("2/30", SUNDAY) == "";
    assert parse_date_word("someday", SUNDAY) == "";
}

test "times need a colon or am/pm" {
    assert parse_time_word("5pm") == "17:00";
    assert parse_time_word("9:30am") == "09:30";
    assert parse_time_word("12am") == "00:00";
    assert parse_time_word("23:59") == "23:59";
    assert parse_time_word("noon") == "12:00";
    assert parse_time_word("eod") == "23:59";
    assert parse_time_word("5") == "";
    assert parse_time_word("13pm") == "";
    assert parse_time_word("25:00") == "";
}

test "a time alone means today" {
    d = parse_quick_add("office hours @3pm", SUNDAY);
    assert d.due == "2026-10-04";
    assert d.due_time == "15:00";
}

test "durations" {
    assert parse_duration("45m") == 45;
    assert parse_duration("1.5h") == 90;
    assert parse_duration("1h30m") == 90;
    assert parse_duration("90") == 90;
    assert parse_duration("soon") == 0;
}

test "priority spellings and unknown tokens stay in the title" {
    assert parse_quick_add("x !low", SUNDAY).priority == 1;
    assert parse_quick_add("x !!", SUNDAY).priority == 3;
    assert parse_quick_add("x !2", SUNDAY).priority == 2;
    d = parse_quick_add("email @prof about !maybe ~later", SUNDAY);
    assert d.title == "email @prof about !maybe ~later";
}
