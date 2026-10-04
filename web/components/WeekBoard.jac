"""Seven day cards with a workload bar against the daily budget."""

import from core.planner { Dashboard, TaskView }
import from core.state { fmt_minutes }

def:pub load_color(minutes: int, capacity: int) -> str {
    if minutes <= capacity * 0.75 {
        return "var(--ok)";
    }
    return "var(--warn)" if minutes <= capacity else "var(--danger)";
}

def:pub WeekBoard(dash: Dashboard, onEdit: Callable[[TaskView], None]) -> JsxElement {
    open_tasks = dash.focus + dash.upcoming;
    <div className="week">
        {for day in dash.week {
            due = [t for t in open_tasks if t.due == day.date];
            pct = min(100, round(100 * day.minutes / max(dash.capacity, 1)));
            <div key={day.date} className={"day" + (" today" if day.is_today else "")}>
                <div className="day-head">
                    <span>{day.label}</span>
                    <span className="sub">{fmt_minutes(day.minutes) if day.count else ""}</span>
                </div>
                <div className="load">
                    <div
                        style={{
                            "width": str(pct) + "%",
                            "background": load_color(day.minutes, dash.capacity)
                        }}
                    />
                </div>
                {if not due {
                    <div className="muted" style={{"fontSize": "13px"}}>Free</div>
                }}
                {for t in due {
                    <div
                        key={t.num}
                        className="mini"
                        style={{"--ring": t.color or "var(--muted)"}}
                        onClick={lambda { onEdit(t); }}
                    >
                        {t.title}
                        <div className="muted" style={{"fontSize": "12px"}}>
                            {(t.course + " · " if t.course else "") + (fmt_minutes(t.est_minutes) if t.est_minutes else "no estimate")}
                        </div>
                    </div>
                }}
            </div>
        }}
    </div>
}
