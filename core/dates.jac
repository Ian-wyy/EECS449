"""Calendar helpers. Dates travel as ISO strings (YYYY-MM-DD), times as HH:MM."""

import datetime;

glob WEEKDAYS: list[str] = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"],
     WEEKDAYS_LONG: list[str] = [
         "monday",
         "tuesday",
         "wednesday",
         "thursday",
         "friday",
         "saturday",
         "sunday"
     ],
     WEEKDAY_NAMES: list[str] = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

def parse_day(text: str) -> datetime.date | None {
    if not text {
        return None;
    }
    try {
        return datetime.date.fromisoformat(text);
    } except ValueError {
        return None;
    }
}

"""The client's idea of today, falling back to the server clock."""
def today_or(text: str) -> datetime.date {
    d = parse_day(text);
    return d if d is not None else datetime.date.today();
}

def now_iso -> str {
    return datetime.datetime.now().replace(microsecond=0).isoformat();
}

def shift(d: datetime.date, days: int) -> datetime.date {
    return d + datetime.timedelta(days=days);
}

"""Days from `today` until `due`; None when the task has no date."""
def days_left(due: str, today: datetime.date) -> int | None {
    d = parse_day(due);
    if d is None {
        return None;
    }
    return (d - today).days;
}

def short_date(d: datetime.date) -> str {
    return WEEKDAY_NAMES[d.weekday()] + " " + str(d.month) + "/" + str(d.day);
}

"""17:00 -> 5pm, 09:30 -> 9:30am."""
def fmt_time(hhmm: str) -> str {
    if not hhmm or ":" not in hhmm {
        return "";
    }
    parts = hhmm.split(":");
    h = int(parts[0]);
    m = int(parts[1]);
    suffix = "am" if h < 12 else "pm";
    h12 = h % 12;
    if h12 == 0 {
        h12 = 12;
    }
    return str(h12) + (":" + parts[1] if m else "") + suffix;
}

def due_label(due: str, due_time: str, today: datetime.date) -> str {
    d = parse_day(due);
    if d is None {
        return "No date";
    }
    left = (d - today).days;
    label = "";
    if left < -1 {
        label = "Overdue " + str(-left) + "d";
    } elif left == -1 {
        label = "Yesterday";
    } elif left == 0 {
        label = "Today";
    } elif left == 1 {
        label = "Tomorrow";
    } elif left < 7 {
        label = WEEKDAY_NAMES[d.weekday()];
    } else {
        label = short_date(d);
    }
    t = fmt_time(due_time);
    return label + (" " + t if t else "");
}
