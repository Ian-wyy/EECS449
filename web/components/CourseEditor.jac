"""Create a course or change its name and color."""

import from "lucide-react" { X }

glob SWATCHES: list[str] = [
         "#4f46e5",
         "#db2777",
         "#059669",
         "#ea580c",
         "#0891b2",
         "#9333ea",
         "#ca8a04",
         "#dc2626"
     ];

def:pub CourseEditor(
    code: str,
    name: str,
    color: str,
    isNew: bool,
    onSave: Callable[[str, str, str], bool],
    onClose: Callable[[], None]
) -> JsxElement {
    has draftCode: str = code,
        draftName: str = name,
        draftColor: str = color or SWATCHES[0],
        saving: bool = False;

    async def save {
        if not draftCode.strip() or saving {
            return;
        }
        saving = True;
        ok = await onSave(draftCode, draftName, draftColor);
        saving = False;
        if ok {
            onClose();
        }
    }

    <div className="backdrop" onClick={lambda { onClose(); }}>
        <div className="modal" onClick={lambda (e: MouseEvent) { e.stopPropagation(); }}>
            <div className="section-head">
                <h3>{"New course" if isNew else "Edit " + code}</h3>
                <button className="icon-btn" aria-label="Close" onClick={lambda { onClose(); }}>
                    <X size={18}/>
                </button>
            </div>
            <div className="grid2">
                <div className="field">
                    <label>Code</label>
                    <input
                        className="input"
                        value={draftCode}
                        disabled={not isNew}
                        placeholder="EECS449"
                        autoFocus={isNew}
                        onChange={lambda (e: ChangeEvent) { draftCode = e.target.value; }}
                    />
                </div>
                <div className="field">
                    <label>Name</label>
                    <input
                        className="input"
                        value={draftName}
                        placeholder="Conversational AI"
                        onChange={lambda (e: ChangeEvent) { draftName = e.target.value; }}
                        onKeyDown={lambda (e: KeyboardEvent) { if e.key == "Enter" { save(); } }}
                    />
                </div>
            </div>
            <div className="field">
                <label>Color</label>
                <div className="swatches">
                    {for c in SWATCHES {
                        <button
                            key={c}
                            type="button"
                            aria-label={c}
                            className={"swatch" + (" on" if c == draftColor else "")}
                            style={{"background": c}}
                            onClick={lambda { draftColor = c; }}
                        />
                    }}
                </div>
            </div>
            <div className="modal-foot">
                <span/>
                <div style={{"display": "flex", "gap": "8px"}}>
                    <button className="btn" type="button" onClick={lambda { onClose(); }}>Cancel</button>
                    <button
                        className="btn primary"
                        type="button"
                        disabled={saving or not draftCode.strip()}
                        onClick={lambda { save(); }}
                    >
                        Save
                    </button>
                </div>
            </div>
        </div>
    </div>
}
