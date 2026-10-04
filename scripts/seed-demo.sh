#!/usr/bin/env bash
# Fill the signed-in StudyPilot account with a realistic week of coursework.
# Usage (server running via `jac run`):
#   ./plan signup demo --password demo1234     # or: ./plan login demo
#   scripts/seed-demo.sh
# Dates are relative (@tmr, @fri, @+3d ...) so the demo looks right on any day.
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")/.."
p() { ./plan "$@" >/dev/null && echo "  ✔ $*"; }

echo "Courses"
p course add EECS449 --name "Conversational AI" --color "#4f46e5"
p course add EECS482 --name "Operating Systems" --color "#db2777"
p course add MATH217 --name "Linear Algebra" --color "#059669"
p course add STATS250 --name "Intro to Statistics" --color "#ea580c"

echo "Tasks"
p add Assignment 1: personal planner in Jac '#EECS449' '!high' @tmr @11:59pm '~3h'
p add Weekly snippet '#EECS449' @fri @5pm '~30m'
p add Group update slides '#EECS449' @+2d @1pm '~1h'
p add Project 2 threads design doc '#EECS482' '!high' @+3d '~4h'
p add Read OSTEP ch. 26-28 '#EECS482' @+5d '~1h30m'
p add Problem set 5 '#MATH217' @+2d @11:59pm '~2h'
p add Office hours: eigenvectors '#MATH217' @today @3pm '~45m'
p add Lab quiz '#STATS250' @+1d @10am '~20m'
p add Homework 4 '#STATS250' @+6d '~1h30m'
p add Reply to recruiter email @today '~15m'
p add Gym @today @6pm '~1h' '!low'
p add Call home @+1d '!low'
p add Renew bus pass

echo "Some progress"
./plan --no-color ls | grep -E 'Renew bus pass|Reply to recruiter' | grep -oE '#[0-9]+' | tr -d '#' | xargs -r ./plan done >/dev/null && echo "  ✔ checked off two quick tasks"
echo "Done. Try: ./plan today"
