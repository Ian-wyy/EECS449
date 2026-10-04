"""Navigation: views, courses, the daily budget, theme and sign-out."""

import from "lucide-react" {
    CalendarDays,
    CheckCircle2,
    GraduationCap,
    ListTodo,
    LogOut,
    Minus,
    Moon,
    Plus,
    Sun,
    Target
}
import from core.planner { Dashboard }
import from core.state { fmt_minutes }

def:pub Brand -> JsxElement {
    <div className="brand">
        <div className="brand-mark"><GraduationCap size={20}/></div>
        StudyPilot
    </div>
}

def:pub Sidebar(
    dash: Dashboard,
    view: str,
    username: str,
    dark: bool,
    onView: Callable[[str], None],
    onNewCourse: Callable[[], None],
    onBudget: Callable[[int], None],
    onTheme: Callable[[], None],
    onLogout: Callable[[], None]
) -> JsxElement {
    open_count = len(dash.focus) + len(dash.upcoming);
    items = [
        ("today", "Today", len(dash.focus)),
        ("upcoming", "All tasks", open_count),
        ("week", "Next 7 days", 0),
        ("done", "Completed", len(dash.done_recent))
    ];
    <aside className="sidebar">
        <Brand/>
        <nav className="nav">
            {for (key, label, count) in items {
                <button
                    key={key}
                    className={"nav-item" + (" active" if view == key else "")}
                    onClick={lambda { onView(key); }}
                >
                    {if key == "today" {
                        <Target size={17}/>
                    } elif key == "upcoming" {
                        <ListTodo size={17}/>
                    } elif key == "week" {
                        <CalendarDays size={17}/>
                    } else {
                        <CheckCircle2 size={17}/>
                    }}
                    {label}
                    {if count {
                        <span
                            className={"count" + (" hot" if key == "today" and dash.stats.overdue_count else "")}
                        >
                            {count}
                        </span>
                    }}
                </button>
            }}
        </nav>
        <nav className="nav">
            <div className="nav-title">
                Courses
                <button className="icon-btn" aria-label="New course" onClick={lambda { onNewCourse(); }}>
                    <Plus size={15}/>
                </button>
            </div>
            {if not dash.courses {
                <div className="muted" style={{"fontSize": "13px", "padding": "0 10px"}}>
                    Tag a task with #CODE to create one.
                </div>
            }}
            {for c in dash.courses {
                <button
                    key={c.code}
                    className={"nav-item" + (" active" if view == "course:" + c.code else "")}
                    onClick={lambda { onView("course:" + c.code); }}
                >
                    <span className="dot" style={{"background": c.color}}/>
                    {c.code}
                    {if c.open_count {
                        <span className="count">{c.open_count}</span>
                    }}
                </button>
            }}
        </nav>
        <div className="budget">
            <div className="muted">Daily focus budget</div>
            <div className="budget-row">
                <button
                    className="icon-btn"
                    aria-label="Less time"
                    onClick={lambda { onBudget(dash.capacity - 30); }}
                >
                    <Minus size={16}/>
                </button>
                <strong>{fmt_minutes(dash.capacity)}</strong>
                <button
                    className="icon-btn"
                    aria-label="More time"
                    onClick={lambda { onBudget(dash.capacity + 30); }}
                >
                    <Plus size={16}/>
                </button>
            </div>
        </div>
        <div className="side-foot">
            <span>@{username}</span>
            <span>
                <button className="icon-btn" aria-label="Toggle theme" onClick={lambda { onTheme(); }}>
                    {if dark {
                        <Sun size={16}/>
                    } else {
                        <Moon size={16}/>
                    }}
                </button>
                <button className="icon-btn" aria-label="Sign out" onClick={lambda { onLogout(); }}>
                    <LogOut size={16}/>
                </button>
            </span>
        </div>
    </aside>
}
