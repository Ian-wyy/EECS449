"""Design tokens and styles for the StudyPilot phone app (same palette as the web app)."""

import from "@jac/mobui" { StyleSheet }

obj Palette {
    has bg: str = "#f6f7fb",
        surface: str = "#ffffff",
        surface2: str = "#f1f3f9",
        border: str = "#e4e7f0",
        text: str = "#171a24",
        muted: str = "#6b7286",
        accent: str = "#4f46e5",
        accentSoft: str = "#eef0ff",
        onAccent: str = "#ffffff",
        danger: str = "#dc2626",
        dangerSoft: str = "#fdecec",
        warn: str = "#c2410c",
        warnSoft: str = "#fff1e6",
        ok: str = "#059669";
}

glob:pub C: Palette = Palette();

glob:pub styles = StyleSheet.create(
         {
             root: {flex: 1, backgroundColor: C.bg},
             header: {
                 paddingTop: 18,
                 paddingHorizontal: 18,
                 paddingBottom: 10,
                 backgroundColor: C.bg
             },
             headerRow: {flexDirection: "row", alignItems: "center", gap: 10},
             brandMark: {
                 width: 34,
                 height: 34,
                 borderRadius: 10,
                 backgroundColor: C.accent,
                 alignItems: "center",
                 justifyContent: "center"
             },
             title: {fontSize: 22, fontWeight: "800", color: C.text},
             subtitle: {fontSize: 13, color: C.muted, marginTop: 2},
             body: {flex: 1},
             scroll: {padding: 16, paddingBottom: 32, gap: 14},
             card: {
                 backgroundColor: C.surface,
                 borderRadius: 16,
                 borderWidth: 1,
                 borderColor: C.border,
                 overflow: "hidden"
             },
             sectionTitle: {fontSize: 16, fontWeight: "800", color: C.text},
             sectionSub: {fontSize: 12, color: C.muted},
             rowBetween: {
                 flexDirection: "row",
                 alignItems: "center",
                 justifyContent: "space-between"
             },
             quick: {
                 flexDirection: "row",
                 alignItems: "center",
                 gap: 8,
                 backgroundColor: C.surface,
                 borderRadius: 14,
                 borderWidth: 1,
                 borderColor: C.border,
                 paddingLeft: 14,
                 paddingRight: 6,
                 paddingVertical: 6
             },
             quickInput: {flex: 1, fontSize: 15, color: C.text, paddingVertical: 8},
             addBtn: {
                 backgroundColor: C.accent,
                 borderRadius: 10,
                 paddingHorizontal: 14,
                 paddingVertical: 9
             },
             addLabel: {color: C.onAccent, fontWeight: "700"},
             hint: {fontSize: 12, color: C.muted, marginTop: -6},
             stats: {flexDirection: "row", gap: 8},
             stat: {
                 flex: 1,
                 backgroundColor: C.surface,
                 borderRadius: 14,
                 borderWidth: 1,
                 borderColor: C.border,
                 paddingVertical: 10,
                 alignItems: "center"
             },
             statValue: {fontSize: 20, fontWeight: "800", color: C.text},
             statLabel: {fontSize: 11, color: C.muted, marginTop: 2},
             meterTrack: {height: 8, borderRadius: 99, backgroundColor: C.surface2, overflow: "hidden"},
             meterFill: {height: 8, borderRadius: 99, backgroundColor: C.accent},
             task: {
                 flexDirection: "row",
                 alignItems: "flex-start",
                 gap: 12,
                 paddingVertical: 12,
                 paddingHorizontal: 14,
                 borderTopWidth: 1,
                 borderTopColor: C.border
             },
             taskFirst: {borderTopWidth: 0},
             check: {
                 width: 24,
                 height: 24,
                 borderRadius: 12,
                 borderWidth: 2,
                 alignItems: "center",
                 justifyContent: "center",
                 marginTop: 1
             },
             taskTitle: {fontSize: 15, fontWeight: "600", color: C.text},
             taskDone: {color: C.muted, textDecorationLine: "line-through"},
             meta: {flexDirection: "row", flexWrap: "wrap", alignItems: "center", gap: 8, marginTop: 4},
             metaText: {fontSize: 12.5, color: C.muted},
             tag: {
                 fontSize: 11.5,
                 fontWeight: "700",
                 paddingHorizontal: 8,
                 paddingVertical: 2,
                 borderRadius: 99,
                 overflow: "hidden"
             },
             reason: {
                 fontSize: 11.5,
                 fontWeight: "700",
                 paddingHorizontal: 8,
                 paddingVertical: 2,
                 borderRadius: 99,
                 overflow: "hidden",
                 color: C.accent,
                 backgroundColor: C.accentSoft
             },
             empty: {padding: 24, alignItems: "center", gap: 4},
             emptyTitle: {fontSize: 15, fontWeight: "700", color: C.text},
             emptyText: {fontSize: 13, color: C.muted, textAlign: "center"},
             dayHead: {
                 flexDirection: "row",
                 alignItems: "center",
                 justifyContent: "space-between",
                 paddingHorizontal: 14,
                 paddingTop: 12,
                 paddingBottom: 8
             },
             dayLabel: {fontSize: 14, fontWeight: "800", color: C.text},
             tabBar: {
                 flexDirection: "row",
                 borderTopWidth: 1,
                 borderTopColor: C.border,
                 backgroundColor: C.surface,
                 paddingBottom: 6
             },
             tab: {flex: 1, alignItems: "center", paddingVertical: 8, gap: 2},
             tabLabel: {fontSize: 11, fontWeight: "600"},
             banner: {
                 marginHorizontal: 16,
                 marginBottom: 6,
                 padding: 10,
                 borderRadius: 12,
                 backgroundColor: C.dangerSoft
             },
             bannerText: {color: C.danger, fontSize: 13, fontWeight: "600"},
             toast: {
                 position: "absolute",
                 left: 16,
                 right: 16,
                 bottom: 74,
                 backgroundColor: C.text,
                 borderRadius: 12,
                 paddingVertical: 10,
                 paddingHorizontal: 14
             },
             toastText: {color: C.bg, fontWeight: "700", textAlign: "center"},
             sheetBackdrop: {flex: 1, backgroundColor: "rgba(10,12,20,0.45)", justifyContent: "flex-end"},
             sheet: {
                 backgroundColor: C.surface,
                 borderTopLeftRadius: 22,
                 borderTopRightRadius: 22,
                 padding: 20,
                 gap: 12
             },
             sheetTitle: {fontSize: 18, fontWeight: "800", color: C.text},
             actionRow: {flexDirection: "row", gap: 8, flexWrap: "wrap"},
             action: {
                 flexGrow: 1,
                 flexDirection: "row",
                 alignItems: "center",
                 justifyContent: "center",
                 gap: 6,
                 paddingVertical: 11,
                 paddingHorizontal: 12,
                 borderRadius: 12,
                 backgroundColor: C.surface2
             },
             actionLabel: {fontWeight: "700", color: C.text},
             primary: {backgroundColor: C.accent},
             primaryLabel: {color: C.onAccent, fontWeight: "700"},
             authWrap: {flexGrow: 1, justifyContent: "center", padding: 24, gap: 12},
             input: {
                 fontSize: 15,
                 color: C.text,
                 backgroundColor: C.surface,
                 borderWidth: 1,
                 borderColor: C.border,
                 borderRadius: 12,
                 paddingVertical: 12,
                 paddingHorizontal: 14
             },
             errorBox: {padding: 10, borderRadius: 10, backgroundColor: C.dangerSoft},
             errorText: {color: C.danger, fontSize: 13, fontWeight: "600"},
             link: {color: C.accent, fontWeight: "700"},
             courseRow: {paddingVertical: 12, paddingHorizontal: 14, gap: 6, borderTopWidth: 1, borderTopColor: C.border}
         }
     );
