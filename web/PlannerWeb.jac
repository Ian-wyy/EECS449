"""The StudyPilot web app: one page, five views, two modals."""

import from "@jac/runtime" { __getLocalStorage, __setLocalStorage }
import from "lucide-react" { RefreshCw }
import from core.planner { CourseView, TaskView }
import from core.state { TaskEdit, edit_of, fmt_minutes, usePlanner }
import from .components.AuthView { AuthView }
import from .components.CourseEditor { CourseEditor }
import from .components.CourseHero { CourseHero }
import from .components.EditTask { EditTask }
import from .components.QuickAdd { QuickAdd }
import from .components.Sidebar { Sidebar }
import from .components.StatRow { StatRow }
import from .components.TaskGroups { EmptyState, TaskGroups, TaskList }
import from .components.WeekBoard { WeekBoard }

glob THEME_KEY: str = "studypilot_theme";

def:pub greeting -> str {
    h = new(Date).getHours();  # jac:ignore[E1053]
    if h < 12 {
        return "Good morning";
    }
    return "Good afternoon" if h < 18 else "Good evening";
}

def:pub PlannerWeb -> JsxElement {
    model = usePlanner();
    has view: str = "today",
        editing: TaskEdit | None = None,
        courseOpen: bool = False,
        courseIsNew: bool = True,
        courseCode: str = "",
        courseName: str = "",
        courseColor: str = "",
        dark: bool = False;

    can with entry {
        saved = __getLocalStorage(THEME_KEY);
        media: any = window.matchMedia("(prefers-color-scheme: dark)");  # jac:ignore[E1053]
        prefers: bool = bool(media.matches);
        dark = saved == "dark" or (not saved and prefers);
        document.documentElement.setAttribute("data-theme", "dark" if dark else "light");  # jac:ignore[E1053]
        def onKey(e: KeyboardEvent) {
            tag = e.target.tagName;
            if e.key == "/" and tag != "INPUT" and tag != "TEXTAREA" and tag != "SELECT" {
                e.preventDefault();
                el: any = document.getElementById("quick-add");  # jac:ignore[E1053]
                if el {
                    el.focus();
                }
            }
        }
        document.addEventListener("keydown", onKey);  # jac:ignore[E1053]
    }

    def toggleTheme {
        dark = not dark;
        __setLocalStorage(THEME_KEY, "dark" if dark else "light");
        document.documentElement.setAttribute("data-theme", "dark" if dark else "light");  # jac:ignore[E1053]
    }

    def openTask(t: TaskView) {
        editing = edit_of(t);
    }

    def openCourse(code: str, name: str, color: str, isNew: bool) {
        courseCode = code;
        courseName = name;
        courseColor = color;
        courseIsNew = isNew;
        courseOpen = True;
    }

    async def removeCourse(code: str) {
        if window.confirm("Delete " + code + "? Its tasks move to your personal inbox.") {  # jac:ignore[E1053]
            await model.removeCourse(code);
            view = "today";
        }
    }

    if model.checking {
        return <div className="auth"><div className="muted">Loading…</div></div>;
    }
    if not model.loggedIn {
        return <AuthView model={model}/>;
    }
    dash = model.dash;
    if dash is None {
        return
            <div className="auth">
                <div className="muted">
                    {model.error if model.error else "Loading your plan…"}
                </div>
            </div>;
    }

    course_code = view[7:] if view.startswith("course:") else "";
    course: CourseView | None = None;
    for c in dash.courses {
        if c.code == course_code {
            course = c;
        }
    }
    open_tasks = dash.focus + dash.upcoming;
    pct = min(100, round(100 * dash.planned_minutes / max(dash.capacity, 1)));

    <div className="shell">
        <Sidebar
            dash={dash}
            view={view}
            username={model.username}
            dark={dark}
            onView={lambda (v: str) { view = v; }}
            onNewCourse={lambda { openCourse("", "", "", True); }}
            onBudget={model.setBudget}
            onTheme={toggleTheme}
            onLogout={model.logout}
        />
        <main className="main">
            <div className="topline">
                <div>
                    <h1 className="greet">{greeting()}, {model.username}</h1>
                    <div className="date">{dash.today_label}</div>
                </div>
                <button
                    className="btn"
                    onClick={lambda { model.refresh(); }}
                    disabled={model.refreshing}
                >
                    <RefreshCw size={15}/>
                    {"Syncing…" if model.refreshing else "Sync"}
                </button>
            </div>
            {if model.error {
                <div className="banner">
                    {model.error}
                    <button className="link" onClick={lambda { model.dismiss(); }}>Dismiss</button>
                </div>
            }}
            <QuickAdd onAdd={model.quickAdd}/>
            <StatRow stats={dash.stats}/>

            {if view == "today" {
                <div className="section">
                    <div className="section-head">
                        <h2>Today's plan</h2>
                        <span className="sub">
                            {fmt_minutes(dash.planned_minutes)} planned of {fmt_minutes(dash.capacity)}
                        </span>
                    </div>
                    <div className="meter"><div style={{"width": str(pct) + "%"}}/></div>
                    {if dash.focus {
                        <TaskList
                            tasks={dash.focus}
                            onToggle={model.toggle}
                            onEdit={openTask}
                            onDelete={model.removeTask}
                            showReason={True}
                        />
                    } else {
                        <EmptyState
                            title="Nothing due today"
                            hint="Enjoy it, or get ahead on something below."
                        />
                    }}
                </div>
                if dash.upcoming {
                    <div className="section">
                        <div className="section-head">
                            <h2>Coming up</h2>
                            <button className="link" onClick={lambda { view = "upcoming"; }}>See all</button>
                        </div>
                        <TaskList
                            tasks={dash.upcoming[:5]}
                            onToggle={model.toggle}
                            onEdit={openTask}
                            onDelete={model.removeTask}
                        />
                    </div>
                }
            } elif view == "upcoming" {
                <div className="section">
                    <div className="section-head">
                        <h2>All open tasks</h2>
                        <span className="sub">{len(open_tasks)} open</span>
                    </div>
                    <TaskGroups
                        tasks={open_tasks}
                        onToggle={model.toggle}
                        onEdit={openTask}
                        onDelete={model.removeTask}
                    />
                </div>
            } elif view == "week" {
                <div className="section">
                    <div className="section-head">
                        <h2>Next 7 days</h2>
                        <span className="sub">Bars show workload against your daily budget</span>
                    </div>
                    <WeekBoard dash={dash} onEdit={openTask}/>
                </div>
            } elif view == "done" {
                <div className="section">
                    <div className="section-head">
                        <h2>Completed this week</h2>
                        <span className="sub">{dash.stats.done_today} today</span>
                    </div>
                    {if dash.done_recent {
                        <TaskList
                            tasks={dash.done_recent}
                            onToggle={model.toggle}
                            onEdit={openTask}
                            onDelete={model.removeTask}
                        />
                    } else {
                        <EmptyState title="Nothing finished yet" hint="Check something off and it shows up here."/>
                    }}
                </div>
            } elif course is not None {
                <div>
                    <CourseHero
                        course={course}
                        onEdit={lambda (c: CourseView) { openCourse(c.code, c.name, c.color, False); }}
                        onDelete={removeCourse}
                    />
                    <div className="section">
                        <TaskGroups
                            tasks={[t for t in open_tasks if t.course == course_code]}
                            onToggle={model.toggle}
                            onEdit={openTask}
                            onDelete={model.removeTask}
                        />
                    </div>
                </div>
            } else {
                <EmptyState title="Course not found" hint="Pick a view from the sidebar."/>
            }}
        </main>
        {if editing is not None {
            <EditTask
                key={editing.num}
                initial={editing}
                courses={dash.courses}
                onSave={model.saveTask}
                onDelete={model.removeTask}
                onClose={lambda { editing = None; }}
            />
        }}
        {if courseOpen {
            <CourseEditor
                code={courseCode}
                name={courseName}
                color={courseColor}
                isNew={courseIsNew}
                onSave={model.saveCourse}
                onClose={lambda { courseOpen = False; }}
            />
        }}
        {if model.notice {
            <div className="toast">{model.notice}</div>
        }}
    </div>
}
