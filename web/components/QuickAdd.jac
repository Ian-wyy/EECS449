"""The quick-add bar: type a sentence with tags, press Enter."""

import from "lucide-react" { Plus, Sparkles }

glob EXAMPLES: list[str] = ["#EECS449", "!high", "@tmr", "@fri", "@5pm", "~2h", "@+3d"];

def:pub QuickAdd(onAdd: Callable[[str], bool]) -> JsxElement {
    has text: str = "",
        busy: bool = False;

    async def submit {
        if busy or not text.strip() {
            return;
        }
        busy = True;
        ok = await onAdd(text);
        busy = False;
        if ok {
            text = "";
        }
    }

    def addChip(tag: str) {
        text = (text.rstrip() + " " + tag + " ").lstrip();
        el: any = document.getElementById("quick-add");  # jac:ignore[E1053]
        if el {
            el.focus();
        }
    }

    <div>
        <form
            className="quick"
            onSubmit={lambda (e: FormEvent) {
                e.preventDefault();
                submit();
            }}
        >
            <Sparkles size={18} color="var(--accent)"/>
            <input
                id="quick-add"
                autoComplete="off"
                value={text}
                placeholder="Add a task…  e.g. Finish A1 report #EECS449 !high @mon @5pm ~3h"
                onChange={lambda (e: ChangeEvent) { text = e.target.value; }}
            />
            <kbd>/</kbd>
            <button className="btn primary" type="submit" disabled={busy or not text.strip()}>
                <Plus size={16}/>
                Add
            </button>
        </form>
        <div className="chips">
            {for tag in EXAMPLES {
                <button key={tag} className="chip" type="button" onClick={lambda { addChip(tag); }}>
                    {tag}
                </button>
            }}
        </div>
    </div>
}
