"""Sign in / sign up on the phone (same accounts as web and CLI)."""

import from "@jac/mobui" { View, Text, Pressable, TextInput, ScrollView, ActivityIndicator }
import from core.state { PlannerState }
import from ..theme { C, styles }
import from ..components.Icon { Icon }

def:pub AuthScreen(model: PlannerState) -> JsxElement {
    <ScrollView style={styles.root} contentContainerStyle={styles.authWrap} keyboardShouldPersistTaps="handled">
        <View style={styles.headerRow}>
            <View style={styles.brandMark}><Icon name="cap" size={20} color="#ffffff"/></View>
            <Text style={styles.title}>StudyPilot</Text>
        </View>
        <Text style={[styles.title, {"marginTop": 12}]}>
            {"Create your planner" if model.signup else "Welcome back"}
        </Text>
        <Text style={styles.subtitle}>Same account on your phone, the web and the terminal.</Text>
        {if model.authError {
            <View style={styles.errorBox}><Text style={styles.errorText}>{model.authError}</Text></View>
        }}
        <TextInput
            style={styles.input}
            value={model.username}
            placeholder="Username"
            placeholderTextColor={C.muted}
            autoCapitalize="none"
            autoCorrect={False}
            onChangeText={model.setUsername}
        />
        <TextInput
            style={styles.input}
            value={model.password}
            placeholder="Password"
            placeholderTextColor={C.muted}
            secureTextEntry={True}
            onChangeText={model.setPassword}
            onSubmitEditing={lambda { model.submit(); }}
        />
        <Pressable
            accessibilityRole="button"
            style={[styles.action, styles.primary, {"flexGrow": 0}]}
            disabled={model.busy}
            onPress={lambda { model.submit(); }}
        >
            {if model.busy {
                <ActivityIndicator size="small" color={C.onAccent}/>
            } else {
                <Text style={styles.primaryLabel}>{"Create account" if model.signup else "Sign in"}</Text>
            }}
        </Pressable>
        <Pressable accessibilityRole="button" onPress={lambda { model.toggleMode(); }}>
            <Text style={[styles.subtitle, {"textAlign": "center"}]}>
                {"Already have an account? " if model.signup else "New here? "}
                <Text style={styles.link}>{"Sign in" if model.signup else "Create an account"}</Text>
            </Text>
        </Pressable>
    </ScrollView>
}
