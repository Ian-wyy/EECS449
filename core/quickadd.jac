"""Quick-add grammar shared by every client.

    Finish A1 writeup #EECS449 !high @mon @5pm ~2h

  #CODE         course (created on first use)
  !high !med !low, !3 !2 !1, !!   priority
  @today @tmr @fri @10/5 @2026-10-05 @+3d @+1w @nextweek   due date
  @5pm @17:00 @noon @eod   due time (implies today when no date given)
  ~2h ~45m ~1h30m ~1.5h    time estimate
Everything else is the title.
"""

import re;
import datetime;
import from core.dates { WEEKDAYS, WEEKDAYS_LONG, shift }

obj Draft {
    has title: str = "",
        course: str = "",
        due: str = "",
        due_time: str = "",
        priority: int = 2,
        est_minutes: int = 0;
}

glob PRIORITY_WORDS: dict[str, int] = {
         "high": 3,
         "hi": 3,
         "h": 3,
         "urgent": 3,
         "3": 3,
         "med": 2,
         "medium": 2,
         "m": 2,
         "normal": 2,
         "2": 2,
         "low": 1,
         "lo": 1,
         "l": 1,
         "1": 1
     };

def parse_date_word(word: str, today: datetime.date) -> str {
    w = word.lower();
    if w in ["today", "tod", "tdy", "tonight"] {
        return today.isoformat();
    }
    if w in ["tomorrow", "tmr", "tmrw", "tom"] {
        return shift(today, 1).isoformat();
    }
    if w in ["nextweek", "nw"] {
        return shift(today, 7).isoformat();
    }
    for i in range(7) {
        if w == WEEKDAYS[i] or w == WEEKDAYS_LONG[i] {
            return shift(today, (i - today.weekday()) % 7).isoformat();
        }
    }
    rel = re.fullmatch(r"\+(\d{1,3})([dw]?)", w);
    if rel {
        n = int(rel.group(1));
        return shift(today, n * 7 if rel.group(2) == "w" else n).isoformat();
    }
    full = re.fullmatch(r"(\d{4})-(\d{1,2})-(\d{1,2})", w);
    if full {
        try {
            return datetime.date(
                int(full.group(1)), int(full.group(2)), int(full.group(3))
            ).isoformat();
        } except ValueError {
            return "";
        }
    }
    md = re.fullmatch(r"(\d{1,2})/(\d{1,2})", w);
    if md {
        try {
            d = datetime.date(today.year, int(md.group(1)), int(md.group(2)));
        } except ValueError {
            return "";
        }
        if (today - d).days > 60 {
            d = datetime.date(today.year + 1, d.month, d.day);
        }
        return d.isoformat();
    }
    return "";
}

def parse_time_word(word: str) -> str {
    w = word.lower();
    if w == "noon" {
        return "12:00";
    }
    if w in ["eod", "midnight"] {
        return "23:59";
    }
    m = re.fullmatch(r"(\d{1,2})(?::(\d{2}))?(am|pm)?", w);
    if m is None {
        return "";
    }
    if m.group(2) is None and m.group(3) is None {
        return "";
    }
    (hh, mm, ap) = (m.group(1), m.group(2), m.group(3));
    h = int(hh);
    mins = int(mm) if mm else 0;
    if ap {
        if h < 1 or h > 12 {
            return "";
        }
        if ap == "pm" and h != 12 {
            h += 12;
        } elif ap == "am" and h == 12 {
            h = 0;
        }
    }
    if h > 23 or mins > 59 {
        return "";
    }
    return f"{h:02d}:{mins:02d}";
}

def parse_duration(word: str) -> int {
    w = word.lower();
    if re.fullmatch(r"\d{1,4}", w) {
        return int(w);
    }
    m = re.fullmatch(r"(?:(\d+(?:\.\d+)?)h)?(?:(\d+)m(?:in)?)?", w);
    if m is None {
        return 0;
    }
    if m.group(1) is None and m.group(2) is None {
        return 0;
    }
    (hh, mm) = (m.group(1), m.group(2));
    hours = float(hh) if hh else 0.0;
    mins = int(mm) if mm else 0;
    return int(round(hours * 60)) + mins;
}

def parse_quick_add(text: str, today: datetime.date) -> Draft {
    draft = Draft();
    words: list[str] = [];
    for tok in text.split() {
        if len(tok) > 1 and tok.startswith("#") {
            draft.course = tok[1:].upper();
            continue;
        }
        if len(tok) > 1 and tok.startswith("!") {
            key = tok[1:].lower();
            if key.strip("!") == "" {
                draft.priority = 3;
                continue;
            }
            if key in PRIORITY_WORDS {
                draft.priority = PRIORITY_WORDS[key];
                continue;
            }
        }
        if len(tok) > 1 and tok.startswith("~") {
            mins = parse_duration(tok[1:]);
            if mins > 0 {
                draft.est_minutes = mins;
                continue;
            }
        }
        if len(tok) > 1 and tok.startswith("@") {
            day = parse_date_word(tok[1:], today);
            if day {
                draft.due = day;
                continue;
            }
            clock = parse_time_word(tok[1:]);
            if clock {
                draft.due_time = clock;
                if not draft.due {
                    draft.due = today.isoformat();
                }
                continue;
            }
        }
        words.append(tok);
    }
    draft.title = " ".join(words).strip();
    return draft;
}
