"""A task row for the phone: tap the circle to finish, tap the row for actions."""

import from "@jac/mobui" { View, Text, Pressable }
import from core.planner { TaskView }
import from core.state { fmt_minutes }
import from ..theme { C, styles }
import from .Icon { Icon }

def:pub due_color(t: TaskView) -> str {
    if t.done {
        return C.muted;
    }
    if t.bucket == "overdue" {
        return C.danger;
    }
    return C.warn if t.bucket == "today" else C.muted;
}

def:pub TaskCard(
    task: TaskView,
    first: bool,
    showReason: bool,
    onToggle: Callable[[int], None],
    onOpen: Callable[[TaskView], None]
) -> JsxElement {
    ring = task.color or C.muted;
    <View style={[styles.task, (styles.taskFirst if first else None)]}>
        <Pressable
            accessibilityRole="button"
            accessibilityLabel={"Mark not done" if task.done else "Mark done"}
            hitSlop={10}
            style={[
                styles.check,
                {
                    "borderColor": ring,
                    "backgroundColor": ring if task.done else "transparent"
                }
            ]}
            onPress={lambda { onToggle(task.num); }}
        >
            {if task.done {
                <Icon name="check" size={14} color="#ffffff"/>
            }}
        </Pressable>
        <Pressable style={{"flex": 1}} onPress={lambda { onOpen(task); }}>
            <Text style={[styles.taskTitle, (styles.taskDone if task.done else None)]}>
                {task.title}
            </Text>
            <View style={styles.meta}>
                {if task.course {
                    <Text style={[styles.tag, {"color": task.color, "backgroundColor": task.color + "22"}]}>
                        {task.course}
                    </Text>
                }}
                <Text style={[styles.metaText, {"color": due_color(task), "fontWeight": "600"}]}>
                    {task.due_label}
                </Text>
                {if task.est_minutes {
                    <Text style={styles.metaText}>~{fmt_minutes(task.est_minutes)}</Text>
                }}
                {if task.priority == 3 {
                    <Text style={[styles.metaText, {"color": C.danger, "fontWeight": "800"}]}>High</Text>
                }}
            </View>
            {if showReason and task.reason and not task.done {
                <View style={[styles.meta, {"marginTop": 6}]}>
                    <Text style={styles.reason}>{task.reason}</Text>
                </View>
            }}
        </Pressable>
    </View>
}

def:pub TaskCardList(
    tasks: list[TaskView],
    showReason: bool,
    onToggle: Callable[[int], None],
    onOpen: Callable[[TaskView], None]
) -> JsxElement {
    <View style={styles.card}>
        {for (i, t) in enumerate(tasks) {
            <TaskCard
                key={t.num}
                task={t}
                first={i == 0}
                showReason={showReason}
                onToggle={onToggle}
                onOpen={onOpen}
            />
        }}
    </View>
}

def:pub Empty(title: str, hint: str) -> JsxElement {
    <View style={[styles.card, styles.empty]}>
        <Text style={styles.emptyTitle}>{title}</Text>
        <Text style={styles.emptyText}>{hint}</Text>
    </View>
}
