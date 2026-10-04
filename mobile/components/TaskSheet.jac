"""Bottom sheet with the quick actions you want on a phone."""

import from "@jac/mobui" { View, Text, Pressable, Modal }
import from core.planner { TaskView }
import from core.state { TaskEdit, edit_of, fmt_minutes, local_day }
import from ..theme { C, styles }
import from .Icon { Icon }

def:pub moved(t: TaskView, offset: int) -> TaskEdit {
    e = edit_of(t);
    e.due = local_day(offset);
    return e;
}

def:pub with_priority(t: TaskView, p: int) -> TaskEdit {
    e = edit_of(t);
    e.priority = p;
    return e;
}

def:pub TaskSheet(
    task: TaskView,
    onClose: Callable[[], None],
    onToggle: Callable[[int], None],
    onSave: Callable[[TaskEdit], bool],
    onDelete: Callable[[int], None]
) -> JsxElement {
    def act(fn: Callable[[], None]) {
        fn();
        onClose();
    }

    <Modal visible={True} transparent={True} animationType="slide" onRequestClose={onClose}>
        <Pressable style={styles.sheetBackdrop} onPress={lambda { onClose(); }}>
            <Pressable style={styles.sheet} onPress={lambda {}}>
                <Text style={styles.sectionSub}>#{task.num}{(" · " + task.course) if task.course else ""}</Text>
                <Text style={styles.sheetTitle}>{task.title}</Text>
                <Text style={styles.metaText}>
                    Due {task.due_label}
                    {(" · ~" + fmt_minutes(task.est_minutes)) if task.est_minutes else ""}
                    {(" · " + task.reason) if task.reason and not task.done else ""}
                </Text>
                {if task.notes {
                    <Text style={[styles.metaText, {"color": C.text}]}>{task.notes}</Text>
                }}
                <Pressable
                    style={[styles.action, styles.primary]}
                    onPress={lambda { act(lambda { onToggle(task.num); }); }}
                >
                    <Icon name="check" size={16} color={C.onAccent}/>
                    <Text style={styles.primaryLabel}>{"Mark not done" if task.done else "Mark done"}</Text>
                </Pressable>
                <View style={styles.actionRow}>
                    <Pressable style={styles.action} onPress={lambda { act(lambda { onSave(moved(task, 0)); }); }}>
                        <Text style={styles.actionLabel}>Today</Text>
                    </Pressable>
                    <Pressable style={styles.action} onPress={lambda { act(lambda { onSave(moved(task, 1)); }); }}>
                        <Text style={styles.actionLabel}>Tomorrow</Text>
                    </Pressable>
                    <Pressable style={styles.action} onPress={lambda { act(lambda { onSave(moved(task, 7)); }); }}>
                        <Text style={styles.actionLabel}>Next week</Text>
                    </Pressable>
                </View>
                <View style={styles.actionRow}>
                    {for (p, label) in [(1, "Low"), (2, "Normal"), (3, "High")] {
                        <Pressable
                            key={p}
                            style={[styles.action, ({"backgroundColor": C.accentSoft} if task.priority == p else None)]}
                            onPress={lambda { act(lambda { onSave(with_priority(task, p)); }); }}
                        >
                            <Text style={[styles.actionLabel, ({"color": C.accent} if task.priority == p else None)]}>
                                {label}
                            </Text>
                        </Pressable>
                    }}
                </View>
                <Pressable
                    style={[styles.action, {"backgroundColor": C.dangerSoft}]}
                    onPress={lambda { act(lambda { onDelete(task.num); }); }}
                >
                    <Icon name="trash" size={16} color={C.danger}/>
                    <Text style={[styles.actionLabel, {"color": C.danger}]}>Delete</Text>
                </Pressable>
            </Pressable>
        </Pressable>
    </Modal>
}
