"""Today: quick add, how the day is going, the plan, and what's next."""

import from "@jac/mobui" { View, Text, Pressable, TextInput, ScrollView, RefreshControl }
import from core.planner { Dashboard, TaskView }
import from core.state { fmt_minutes }
import from ..theme { C, styles }
import from ..components.TaskCard { Empty, TaskCardList }

def:pub TodayScreen(
    dash: Dashboard,
    refreshing: bool,
    onRefresh: Callable[[], None],
    onAdd: Callable[[str], bool],
    onToggle: Callable[[int], None],
    onOpen: Callable[[TaskView], None]
) -> JsxElement {
    has draft: str = "",
        adding: bool = False;

    async def add {
        if adding or not draft.strip() {
            return;
        }
        adding = True;
        ok = await onAdd(draft);
        adding = False;
        if ok {
            draft = "";
        }
    }

    s = dash.stats;
    pct = min(100, round(100 * dash.planned_minutes / max(dash.capacity, 1)));
    <ScrollView
        style={styles.body}
        contentContainerStyle={styles.scroll}
        keyboardShouldPersistTaps="handled"
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={lambda { onRefresh(); }} tintColor={C.accent}/>}
    >
        <View style={styles.quick}>
            <TextInput
                style={styles.quickInput}
                value={draft}
                placeholder="Add a task… #EECS449 @fri ~1h"
                placeholderTextColor={C.muted}
                returnKeyType="done"
                onChangeText={lambda (t: str) { draft = t; }}
                onSubmitEditing={lambda { add(); }}
            />
            <Pressable
                accessibilityRole="button"
                style={[styles.addBtn, ({"opacity": 0.5} if not draft.strip() else None)]}
                disabled={adding or not draft.strip()}
                onPress={lambda { add(); }}
            >
                <Text style={styles.addLabel}>Add</Text>
            </Pressable>
        </View>
        <Text style={styles.hint}>#course  !high  @tmr @fri @5pm  ~2h</Text>
        <View style={styles.stats}>
            <View style={styles.stat}>
                <Text style={styles.statValue}>{s.due_today}</Text>
                <Text style={styles.statLabel}>Due today</Text>
            </View>
            <View style={styles.stat}>
                <Text style={[styles.statValue, ({"color": C.danger} if s.overdue_count else None)]}>{s.overdue_count}</Text>
                <Text style={styles.statLabel}>Overdue</Text>
            </View>
            <View style={styles.stat}>
                <Text style={styles.statValue}>{s.done_today}</Text>
                <Text style={styles.statLabel}>Done today</Text>
            </View>
            <View style={styles.stat}>
                <Text style={[styles.statValue, ({"color": C.warn} if s.streak else None)]}>{s.streak}🔥</Text>
                <Text style={styles.statLabel}>Streak</Text>
            </View>
        </View>
        <View style={styles.rowBetween}>
            <Text style={styles.sectionTitle}>Today's plan</Text>
            <Text style={styles.sectionSub}>
                {fmt_minutes(dash.planned_minutes)} of {fmt_minutes(dash.capacity)}
            </Text>
        </View>
        <View style={styles.meterTrack}>
            <View style={[styles.meterFill, {"width": str(pct) + "%"}]}/>
        </View>
        {if dash.focus {
            <TaskCardList tasks={dash.focus} showReason={True} onToggle={onToggle} onOpen={onOpen}/>
        } else {
            <Empty title="Nothing due today" hint="Add something above, or enjoy the free time."/>
        }}
        {if dash.upcoming {
            <View style={{"gap": 10}}>
                <Text style={styles.sectionTitle}>Coming up</Text>
                <TaskCardList tasks={dash.upcoming[:6]} showReason={False} onToggle={onToggle} onOpen={onOpen}/>
            </View>
        }}
    </ScrollView>
}
