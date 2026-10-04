"""StudyPilot mobile app entry (React Native via @jac/mobui). Talks to the same planner service."""

import from .PlannerMobile { PlannerMobile }

def:pub app -> JsxElement {
    <PlannerMobile/>
}
