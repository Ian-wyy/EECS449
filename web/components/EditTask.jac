"""Edit every field of a task in a modal."""

import from "lucide-react" { Trash2, X }
import from core.planner { CourseView }
import from core.state { TaskEdit }

glob ESTIMATES: list[int] = [0, 15, 30, 60, 90, 120, 180, 240];

def:pub est_label(m: int) -> str {
    if m == 0 {
        return "None";
    }
    if m < 60 {
        return str(m) + "m";
    }
    return str(m / 60) + "h";
}

def:pub EditTask(
    initial: TaskEdit,
    courses: list[CourseView],
    onSave: Callable[[TaskEdit], bool],
    onDelete: Callable[[int], None],
    onClose: Callable[[], None]
) -> JsxElement {
    has title: str = initial.title,
        notes: str = initial.notes,
        course: str = initial.course,
        due: str = initial.due,
        dueTime: str = initial.due_time,
        priority: int = initial.priority,
        est: int = initial.est_minutes,
        saving: bool = False;

    async def save {
        if not title.strip() or saving {
            return;
        }
        saving = True;
        ok = await onSave(
            TaskEdit(
                num=initial.num,
                title=title,
                notes=notes,
                course=course,
                due=due,
                due_time=dueTime if due else "",
                priority=priority,
                est_minutes=est
            )
        );
        saving = False;
        if ok {
            onClose();
        }
    }

    <div className="backdrop" onClick={lambda { onClose(); }}>
        <div className="modal" onClick={lambda (e: MouseEvent) { e.stopPropagation(); }}>
            <div className="section-head">
                <h3>Edit task #{initial.num}</h3>
                <button className="icon-btn" aria-label="Close" onClick={lambda { onClose(); }}>
                    <X size={18}/>
                </button>
            </div>
            <div className="field">
                <label>Title</label>
                <input
                    className="input"
                    value={title}
                    autoFocus={True}
                    onChange={lambda (e: ChangeEvent) { title = e.target.value; }}
                    onKeyDown={lambda (e: KeyboardEvent) { if e.key == "Enter" { save(); } }}
                />
            </div>
            <div className="grid2">
                <div className="field">
                    <label>Course</label>
                    <select
                        className="input"
                        value={course}
                        onChange={lambda (e: ChangeEvent) { course = e.target.value; }}
                    >
                        <option value="">Personal (no course)</option>
                        {for c in courses {
                            <option key={c.code} value={c.code}>{c.code}{(" — " + c.name) if c.name else ""}</option>
                        }}
                    </select>
                </div>
                <div className="field">
                    <label>Priority</label>
                    <div className="seg">
                        {for (p, label) in [(1, "Low"), (2, "Normal"), (3, "High")] {
                            <button
                                key={p}
                                type="button"
                                className={"on" if priority == p else ""}
                                onClick={lambda { priority = p; }}
                            >
                                {label}
                            </button>
                        }}
                    </div>
                </div>
                <div className="field">
                    <label>Due date</label>
                    <input
                        className="input"
                        type="date"
                        value={due}
                        onChange={lambda (e: ChangeEvent) { due = e.target.value; }}
                    />
                </div>
                <div className="field">
                    <label>Due time</label>
                    <input
                        className="input"
                        type="time"
                        value={dueTime}
                        disabled={not due}
                        onChange={lambda (e: ChangeEvent) { dueTime = e.target.value; }}
                    />
                </div>
            </div>
            <div className="field">
                <label>Time estimate</label>
                <div className="seg">
                    {for m in ESTIMATES {
                        <button
                            key={m}
                            type="button"
                            className={"on" if est == m else ""}
                            onClick={lambda { est = m; }}
                        >
                            {est_label(m)}
                        </button>
                    }}
                </div>
            </div>
            <div className="field">
                <label>Notes</label>
                <textarea
                    className="input"
                    rows={3}
                    value={notes}
                    placeholder="Links, sub-steps, anything…"
                    onChange={lambda (e: ChangeEvent) { notes = e.target.value; }}
                />
            </div>
            <div className="modal-foot">
                <button
                    className="btn danger"
                    type="button"
                    onClick={lambda {
                        onDelete(initial.num);
                        onClose();
                    }}
                >
                    <Trash2 size={15}/>
                    Delete
                </button>
                <div style={{"display": "flex", "gap": "8px"}}>
                    <button className="btn" type="button" onClick={lambda { onClose(); }}>Cancel</button>
                    <button
                        className="btn primary"
                        type="button"
                        disabled={saving or not title.strip()}
                        onClick={lambda { save(); }}
                    >
                        {"Saving…" if saving else "Save"}
                    </button>
                </div>
            </div>
        </div>
    </div>
}
