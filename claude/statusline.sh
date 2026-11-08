#!/bin/sh
# Claude Code status line: model | ctx % | cost | 5h/7d/spend quotas. All fields optional. Colored by severity.
jq -r '
  def c(code; s): "\u001b[\(code)m\(s)\u001b[0m";
  def sev: if . >= 80 then "31" elif . >= 50 then "33" else "32" end;
  def rst: if . == null then "" else c("90"; " (resets " + (. | strflocaltime("%a %H:%M")) + ")") end;
  def lim(l): if .used_percentage == null then empty else c(.used_percentage | sev; "\(l) \(.used_percentage | round)%") + (.resets_at | rst) end;
  [
    (.model.display_name // empty | c("1;36"; .)),
    (.context_window.used_percentage | if . == null then empty else c(. | sev; "ctx \(. | round)%") end),
    (.cost.total_cost_usd | if . == null then empty else c("35"; "$\(. * 100 | round / 100)") end),
    (.rate_limits.five_hour // empty | lim("5h")),
    (.rate_limits.seven_day // empty | lim("7d")),
    (.rate_limits.spend_limit // empty | lim("spend"))
  ] | join(c("90"; " | "))
' 2>/dev/null
