"""Four numbers that say how the day is going."""

import from "lucide-react" { CalendarCheck, AlertTriangle, CheckCircle2, Flame }
import from core.planner { Stats }

def:pub StatRow(stats: Stats) -> JsxElement {
    <div className="stats">
        <div className="stat">
            <div className="label"><CalendarCheck size={14}/>Due today</div>
            <div className="value">{stats.due_today}</div>
        </div>
        <div className={"stat" + (" hot" if stats.overdue_count else "")}>
            <div className="label"><AlertTriangle size={14}/>Overdue</div>
            <div className="value">{stats.overdue_count}</div>
        </div>
        <div className="stat">
            <div className="label"><CheckCircle2 size={14}/>Done this week</div>
            <div className="value">{stats.done_week}</div>
        </div>
        <div className={"stat" + (" fire" if stats.streak else "")}>
            <div className="label"><Flame size={14}/>Streak</div>
            <div className="value">
                {stats.streak}
                <span className="muted" style={{"fontSize": "14px", "fontWeight": 500}}>
                    {" day" if stats.streak == 1 else " days"}
                </span>
            </div>
        </div>
    </div>
}
