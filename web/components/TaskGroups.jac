"""Tasks grouped by when they are due."""

import from core.planner { TaskView }
import from .TaskRow { TaskRow }

glob ORDER: list[str] = ["overdue", "today", "tomorrow", "week", "later", "someday"],
     TITLES: dict[str, str] = {
         "overdue": "Overdue",
         "today": "Today",
         "tomorrow": "Tomorrow",
         "week": "This week",
         "later": "Later",
         "someday": "No date"
     };

def:pub EmptyState(title: str, hint: str) -> JsxElement {
    <div className="list">
        <div className="empty">
            <strong>{title}</strong>
            {hint}
        </div>
    </div>
}

def:pub TaskList(
    tasks: list[TaskView],
    onToggle: Callable[[int], None],
    onEdit: Callable[[TaskView], None],
    onDelete: Callable[[int], None],
    showReason: bool = False
) -> JsxElement {
    <div className="list">
        {for t in tasks {
            <TaskRow
                key={t.num}
                task={t}
                onToggle={onToggle}
                onEdit={onEdit}
                onDelete={onDelete}
                showReason={showReason}
            />
        }}
    </div>
}

def:pub TaskGroups(
    tasks: list[TaskView],
    onToggle: Callable[[int], None],
    onEdit: Callable[[TaskView], None],
    onDelete: Callable[[int], None]
) -> JsxElement {
    if not tasks {
        return <EmptyState title="All clear" hint="Nothing open here. Add a task above."/>;
    }
    <div>
        {for b in ORDER {
            group = [t for t in tasks if t.bucket == b];
            if group {
                <div key={b}>
                    <div className={"group-title" + (" overdue" if b == "overdue" else "")}>
                        {TITLES[b]} · {len(group)}
                    </div>
                    <TaskList tasks={group} onToggle={onToggle} onEdit={onEdit} onDelete={onDelete}/>
                </div>
            }
        }}
    </div>
}
