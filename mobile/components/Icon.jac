"""Icons -- web variant (lucide-react). Keep the keys identical to Icon.native.jac."""

import from "lucide-react" {
    CalendarDays,
    Check,
    ChevronRight,
    Clock,
    Flag,
    GraduationCap,
    ListTodo,
    LogOut,
    Plus,
    RefreshCw,
    Target,
    Trash2,
    User
}

glob LUCIDE = {
    "calendar": CalendarDays,
    "check": Check,
    "chevron": ChevronRight,
    "clock": Clock,
    "flag": Flag,
    "cap": GraduationCap,
    "list": ListTodo,
    "logout": LogOut,
    "plus": Plus,
    "refresh": RefreshCw,
    "target": Target,
    "trash": Trash2,
    "user": User
};

def:pub Icon(name: str, size: int, color: str) -> JsxElement {
    Glyph = LUCIDE[name];
    <Glyph size={size} color={color}/>
}
