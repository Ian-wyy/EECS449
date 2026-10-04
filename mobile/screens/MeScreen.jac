"""Progress per course, the daily budget, and the account."""

import from "@jac/mobui" { View, Text, Pressable, ScrollView }
import from core.planner { Dashboard }
import from core.state { fmt_minutes }
import from ..theme { C, styles }
import from ..components.Icon { Icon }

def:pub MeScreen(
    dash: Dashboard,
    username: str,
    onBudget: Callable[[int], None],
    onLogout: Callable[[], None]
) -> JsxElement {
    s = dash.stats;
    <ScrollView style={styles.body} contentContainerStyle={styles.scroll}>
        <View style={[styles.card, {"padding": 16, "gap": 4}]}>
            <Text style={styles.sectionSub}>Signed in as</Text>
            <Text style={styles.sectionTitle}>@{username}</Text>
            <Text style={styles.metaText}>
                {s.done_week} done this week · {s.open_count} open · {s.streak}-day streak
            </Text>
        </View>
        <View style={[styles.card, {"padding": 16, "gap": 10}]}>
            <Text style={styles.sectionTitle}>Daily focus budget</Text>
            <View style={styles.rowBetween}>
                <Pressable style={[styles.action, {"flexGrow": 0, "paddingHorizontal": 18}]} onPress={lambda { onBudget(dash.capacity - 30); }}>
                    <Text style={styles.actionLabel}>−30m</Text>
                </Pressable>
                <Text style={styles.title}>{fmt_minutes(dash.capacity)}</Text>
                <Pressable style={[styles.action, {"flexGrow": 0, "paddingHorizontal": 18}]} onPress={lambda { onBudget(dash.capacity + 30); }}>
                    <Text style={styles.actionLabel}>+30m</Text>
                </Pressable>
            </View>
            <Text style={styles.metaText}>Today's plan fills up to this much time, most urgent first.</Text>
        </View>
        <Text style={styles.sectionTitle}>Courses</Text>
        <View style={styles.card}>
            {if not dash.courses {
                <View style={styles.empty}>
                    <Text style={styles.emptyText}>Tag a task with #CODE to create a course.</Text>
                </View>
            }}
            {for c in dash.courses {
                total = c.open_count + c.done_count;
                pct = round(100 * c.done_count / total) if total else 0;
                <View key={c.code} style={styles.courseRow}>
                    <View style={styles.rowBetween}>
                        <Text style={[styles.taskTitle, {"color": c.color}]}>{c.code}</Text>
                        <Text style={styles.sectionSub}>{c.done_count}/{total} done</Text>
                    </View>
                    <View style={styles.meterTrack}>
                        <View style={{"height": 8, "width": str(pct) + "%", "backgroundColor": c.color}}/>
                    </View>
                    {if c.next_due {
                        <Text style={styles.metaText}>Next due {c.next_due}</Text>
                    }}
                </View>
            }}
        </View>
        <Pressable style={[styles.action, {"backgroundColor": C.dangerSoft}]} onPress={lambda { onLogout(); }}>
            <Icon name="logout" size={16} color={C.danger}/>
            <Text style={[styles.actionLabel, {"color": C.danger}]}>Sign out</Text>
        </Pressable>
    </ScrollView>
}
