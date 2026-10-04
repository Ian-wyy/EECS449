"""Icons -- native variant (lucide-react-native). Keep the keys identical to Icon.jac."""

import from "lucide-react-native" {
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
