"""One task: check it off, open it to edit, or delete it."""

import from "lucide-react" { Check, Clock, Pencil, Trash2, Flag, AlignLeft }
import from core.planner { TaskView }
import from core.state { fmt_minutes }

def:pub due_class(t: TaskView) -> str {
    if t.done {
        return "";
    }
    if t.bucket == "overdue" {
        return "due-overdue";
    }
    return "due-today" if t.bucket == "today" else "";
}

def:pub reason_class(reason: str) -> str {
    if reason.startswith("Overdue") {
        return "reason bad";
    }
    return "reason warn" if reason.startswith("Due today") else "reason";
}

def:pub TaskRow(
    task: TaskView,
    onToggle: Callable[[int], None],
    onEdit: Callable[[TaskView], None],
    onDelete: Callable[[int], None],
    showReason: bool = False
) -> JsxElement {
    ring = task.color or "var(--muted)";
    <div className={"task" + (" done" if task.done else "")}>
        <button
            className={"check" + (" on" if task.done else "")}
            style={{"--ring": ring}}
            aria-label={"Mark not done" if task.done else "Mark done"}
            onClick={lambda { onToggle(task.num); }}
        >
            {if task.done {
                <Check size={14} strokeWidth={3}/>
            }}
        </button>
        <div className="task-body" onClick={lambda { onEdit(task); }}>
            <div className="task-title">{task.title}</div>
            <div className="meta">
                <span className="muted">#{task.num}</span>
                {if task.course {
                    <span
                        className="course-tag"
                        style={{
                            "background": task.color + "22",
                            "color": task.color
                        }}
                    >
                        {task.course}
                    </span>
                }}
                <span className={due_class(task)}>{task.due_label}</span>
                {if task.est_minutes {
                    <span>
                        <Clock size={13}/>
                        {fmt_minutes(task.est_minutes)}
                    </span>
                }}
                {if task.priority == 3 {
                    <span className="prio-3">
                        <Flag size={13}/>
                        High
                    </span>
                } elif task.priority == 1 {
                    <span className="prio-1">Low</span>
                }}
                {if task.notes {
                    <span title={task.notes}>
                        <AlignLeft size={13}/>
                    </span>
                }}
                {if showReason and task.reason and not task.done {
                    <span className={reason_class(task.reason)}>{task.reason}</span>
                }}
            </div>
        </div>
        <div className="task-actions">
            <button className="icon-btn" aria-label="Edit" onClick={lambda { onEdit(task); }}>
                <Pencil size={16}/>
            </button>
            <button
                className="icon-btn"
                aria-label="Delete"
                onClick={lambda { onDelete(task.num); }}
            >
                <Trash2 size={16}/>
            </button>
        </div>
    </div>
}
