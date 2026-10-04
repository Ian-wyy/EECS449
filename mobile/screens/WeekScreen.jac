"""The next seven days, each with its workload against the daily budget."""

import from "@jac/mobui" { View, Text, ScrollView, RefreshControl }
import from core.planner { Dashboard, TaskView }
import from core.state { fmt_minutes }
import from ..theme { C, styles }
import from ..components.TaskCard { TaskCard }

def:pub WeekScreen(
    dash: Dashboard,
    refreshing: bool,
    onRefresh: Callable[[], None],
    onToggle: Callable[[int], None],
    onOpen: Callable[[TaskView], None]
) -> JsxElement {
    open_tasks = dash.focus + dash.upcoming;
    no_date = [t for t in open_tasks if not t.due];
    <ScrollView
        style={styles.body}
        contentContainerStyle={styles.scroll}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={lambda { onRefresh(); }} tintColor={C.accent}/>}
    >
        {for day in dash.week {
            due = [t for t in open_tasks if t.due == day.date];
            pct = min(100, round(100 * day.minutes / max(dash.capacity, 1)));
            bar = C.ok if day.minutes <= dash.capacity * 0.75 else (C.warn if day.minutes <= dash.capacity else C.danger);
            <View key={day.date} style={[styles.card, ({"borderColor": C.accent} if day.is_today else None)]}>
                <View style={styles.dayHead}>
                    <Text style={styles.dayLabel}>{day.label}</Text>
                    <Text style={styles.sectionSub}>
                        {(str(day.count) + " due · " + fmt_minutes(day.minutes)) if day.count else "Free"}
                    </Text>
                </View>
                <View style={[styles.meterTrack, {"marginHorizontal": 14, "marginBottom": 8, "height": 6}]}>
                    <View style={{"height": 6, "width": str(pct) + "%", "backgroundColor": bar}}/>
                </View>
                {for (i, t) in enumerate(due) {
                    <TaskCard key={t.num} task={t} first={False} showReason={False} onToggle={onToggle} onOpen={onOpen}/>
                }}
            </View>
        }}
        {if no_date {
            <View style={styles.card}>
                <View style={styles.dayHead}>
                    <Text style={styles.dayLabel}>No date</Text>
                    <Text style={styles.sectionSub}>{len(no_date)}</Text>
                </View>
                {for t in no_date {
                    <TaskCard key={t.num} task={t} first={False} showReason={False} onToggle={onToggle} onOpen={onOpen}/>
                }}
            </View>
        }}
    </ScrollView>
}
