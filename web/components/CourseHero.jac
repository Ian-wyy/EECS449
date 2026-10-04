"""Header card for one course: progress, next deadline, edit and delete."""

import from "lucide-react" { Pencil, Trash2 }
import from core.planner { CourseView }

def:pub CourseHero(
    course: CourseView,
    onEdit: Callable[[CourseView], None],
    onDelete: Callable[[str], None]
) -> JsxElement {
    total = course.open_count + course.done_count;
    done_pct = round(100 * course.done_count / total) if total else 0;
    <div className="course-hero">
        <div className="course-badge" style={{"background": course.color}}>
            {course.code[:4]}
        </div>
        <div className="grow">
            <h2>{course.code}{(" · " + course.name) if course.name else ""}</h2>
            <div className="progress-label">
                {course.done_count} of {total} done
                {(" · next due " + course.next_due) if course.next_due else ""}
            </div>
            <div className="meter" style={{"marginTop": "8px", "marginBottom": "0"}}>
                <div style={{"width": str(done_pct) + "%", "background": course.color}}/>
            </div>
        </div>
        <button className="icon-btn" aria-label="Edit course" onClick={lambda { onEdit(course); }}>
            <Pencil size={17}/>
        </button>
        <button
            className="icon-btn"
            aria-label="Delete course"
            onClick={lambda { onDelete(course.code); }}
        >
            <Trash2 size={17}/>
        </button>
    </div>
}
