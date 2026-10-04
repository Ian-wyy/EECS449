"""StudyPilot web app entry (`jac run` serves this; the planner service is colocated)."""

import "./styles.css";
import from .PlannerWeb { PlannerWeb }

def:pub app -> JsxElement {
    <PlannerWeb/>
}
