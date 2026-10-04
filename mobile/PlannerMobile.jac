"""StudyPilot on the phone: Today, Week and Me tabs over the shared usePlanner hook."""

import from "@jac/mobui" { View, Text, Pressable, ActivityIndicator, StatusBar, useWindowDimensions }
import from core.planner { TaskView }
import from core.state { usePlanner }
import from .theme { C, styles }
import from .components.Icon { Icon }
import from .components.TaskSheet { TaskSheet }
import from .screens.AuthScreen { AuthScreen }
import from .screens.MeScreen { MeScreen }
import from .screens.TodayScreen { TodayScreen }
import from .screens.WeekScreen { WeekScreen }

glob TABS: list[tuple[str, str, str]] = [
         ("today", "Today", "target"),
         ("week", "Week", "calendar"),
         ("me", "Me", "user")
     ];

def:pub PlannerMobile -> JsxElement {
    model = usePlanner();
    viewport = useWindowDimensions();
    has tab: str = "today",
        open: TaskView | None = None;

    if model.checking {
        return
            <View style={[styles.root, {"alignItems": "center", "justifyContent": "center"}]}>
                <ActivityIndicator size="large" color={C.accent}/>
            </View>;
    }
    if not model.loggedIn {
        return <AuthScreen model={model}/>;
    }
    dash = model.dash;
    if dash is None {
        return
            <View style={[styles.root, {"alignItems": "center", "justifyContent": "center", "padding": 24}]}>
                {if model.error {
                    <Text style={styles.errorText}>{model.error}</Text>
                } else {
                    <ActivityIndicator size="large" color={C.accent}/>
                }}
            </View>;
    }

    <View style={[styles.root, {"height": viewport.height}]}>
        <StatusBar barStyle="dark-content" backgroundColor={C.bg}/>
        <View style={styles.header}>
            <View style={styles.rowBetween}>
                <View style={styles.headerRow}>
                    <View style={styles.brandMark}><Icon name="cap" size={20} color="#ffffff"/></View>
                    <View>
                        <Text style={styles.title}>StudyPilot</Text>
                        <Text style={styles.subtitle}>{dash.today_label}</Text>
                    </View>
                </View>
                <Pressable accessibilityLabel="Sync" hitSlop={10} onPress={lambda { model.refresh(); }}>
                    <Icon name="refresh" size={20} color={C.muted}/>
                </Pressable>
            </View>
        </View>
        {if model.error {
            <Pressable style={styles.banner} onPress={lambda { model.dismiss(); }}>
                <Text style={styles.bannerText}>{model.error}</Text>
            </Pressable>
        }}
        <View style={styles.body}>
            {if tab == "today" {
                <TodayScreen
                    dash={dash}
                    refreshing={model.refreshing}
                    onRefresh={model.refresh}
                    onAdd={model.quickAdd}
                    onToggle={model.toggle}
                    onOpen={lambda (t: TaskView) { open = t; }}
                />
            } elif tab == "week" {
                <WeekScreen
                    dash={dash}
                    refreshing={model.refreshing}
                    onRefresh={model.refresh}
                    onToggle={model.toggle}
                    onOpen={lambda (t: TaskView) { open = t; }}
                />
            } else {
                <MeScreen dash={dash} username={model.username} onBudget={model.setBudget} onLogout={model.logout}/>
            }}
        </View>
        {if model.notice {
            <View style={styles.toast} pointerEvents="none">
                <Text style={styles.toastText}>{model.notice}</Text>
            </View>
        }}
        <View style={styles.tabBar}>
            {for (key, label, icon) in TABS {
                <Pressable key={key} accessibilityRole="button" style={styles.tab} onPress={lambda { tab = key; }}>
                    <Icon name={icon} size={20} color={C.accent if tab == key else C.muted}/>
                    <Text style={[styles.tabLabel, {"color": C.accent if tab == key else C.muted}]}>{label}</Text>
                </Pressable>
            }}
        </View>
        {if open is not None {
            <TaskSheet
                task={open}
                onClose={lambda { open = None; }}
                onToggle={model.toggle}
                onSave={model.saveTask}
                onDelete={model.removeTask}
            />
        }}
    </View>
}
