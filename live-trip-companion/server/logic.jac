"""Deterministic trip, recovery, budget, and weather logic."""

import json;
import uuid;
import datetime;

def now_iso() -> str {
    return datetime.datetime.now(datetime.timezone.utc).isoformat();
}

def new_id(prefix: str) -> str {
    return prefix + "-" + str(uuid.uuid4())[:8];
}

def parse_trip(node: Trip) -> dict {
    return json.loads(node.payload_json);
}

def save_trip_payload(node: Trip, payload: dict) -> None {
    payload["updated_at"] = now_iso();
    node.payload_json = json.dumps(payload);
    node.updated_at = payload["updated_at"];
    save(node);
    commit();
}

def find_trip_node(trip_id: str) -> any {
    for t in [root-->][?:Trip] {
        if t.trip_id == trip_id {
            return t;
        }
    }
    return None;
}

def get_active_session() -> any {
    for s in [root-->][?:LiveSession] {
        if s.active {
            return s;
        }
    }
    return None;
}

def sum_planned_cost(trip: dict) -> int {
    total = 0;
    for day in trip.get("days", []) {
        for act in day.get("activities", []) {
            total += int(act.get("activity_cost_lkr", 0) or 0);
            total += int(act.get("travel_cost_lkr", 0) or 0);
        }
    }
    return total;
}

def sum_confirmed_expenses(trip_id: str) -> int {
    total = 0;
    for e in [root-->][?:Expense] {
        if e.trip_id != trip_id {
            continue;
        }
        p = json.loads(e.payload_json);
        if p.get("status") == "confirmed" {
            total += int(p.get("amount_lkr", 0) or 0);
        }
    }
    return total;
}

def expenses_for_trip(trip_id: str) -> list {
    out = [];
    for e in [root-->][?:Expense] {
        if e.trip_id == trip_id {
            out.append(json.loads(e.payload_json));
        }
    }
    return out;
}

def budget_summary(trip: dict) -> dict {
    planned = int(trip.get("budget_lkr", 0) or 0);
    spent = sum_confirmed_expenses(trip["id"]);
    remaining = planned - spent;
    days = trip.get("days", []) or [];
    daily = (planned // max(len(days), 1)) if days else planned;
    projected = spent + max(remaining, 0);
    return {
        "planned_lkr": planned,
        "spent_lkr": spent,
        "remaining_lkr": remaining,
        "daily_budget_lkr": daily,
        "projected_final_lkr": projected,
        "over_budget": spent > planned,
        "currency": "LKR"
    };
}

def find_activity(trip: dict, activity_id: str) -> any {
    for day in trip.get("days", []) {
        for act in day.get("activities", []) {
            if act.get("id") == activity_id {
                return {"day": day, "activity": act};
            }
        }
    }
    return None;
}

def time_to_minutes(t: str) -> int {
    parts = t.split(":");
    if len(parts) < 2 {
        return 0;
    }
    return int(parts[0]) * 60 + int(parts[1]);
}

def minutes_to_time(m: int) -> str {
    h = m // 60;
    mi = m % 60;
    return f"{h:02d}:{mi:02d}";
}

def build_missed_bus_disruption(trip: dict, session: dict) -> dict {
    hit = find_activity(trip, "bus-colombo-galle-001");
    if not hit {
        return {"ok": False, "error": "Sample bus leg not found in itinerary."};
    }
    act = hit["activity"];
    sim_time = session.get("simulated_clock", "04:30");
    return {
        "ok": True,
        "type": "missed_transport",
        "demo": True,
        "title": "Potentially missed transport",
        "message": (
            "Your bus was scheduled to leave at 4:00 AM, but your trip progress "
            "suggests you may still be at the bus halt. Did you miss the bus, "
            "or are you still waiting?"
        ),
        "activity_id": act["id"],
        "scheduled_departure": act["start_time"],
        "observed_time": sim_time,
        "choices": [
            "I missed the bus",
            "The bus is delayed",
            "I am still waiting",
            "Update my status"
        ]
    };
}

def build_recovery_for_missed_bus(trip: dict, choice: str) -> dict {
    hit = find_activity(trip, "bus-colombo-galle-001");
    if not hit {
        return {"ok": False, "error": "Bus activity missing."};
    }
    day = hit["day"];
    act = hit["activity"];
    alt = (act.get("alternatives") or [])[0] if act.get("alternatives") else None;
    delay_min = 105;
    if choice == "The bus is delayed" {
        delay_min = 45;
    } elif choice == "I am still waiting" {
        return {
            "ok": True,
            "action": "wait",
            "message": "We'll keep monitoring. No plan change until you confirm a disruption."
        };
    }
    revised = json.loads(json.dumps(trip));
    for d in revised["days"] {
        if d["day_index"] != day["day_index"] {
            continue;
        }
        new_acts = [];
        for a in d["activities"] {
            if a["id"] != act["id"] {
                new_acts.append(a);
                continue;
            }
            replacement = {
                **a,
                "name": alt["label"] if alt else "Alternative transport (demo)",
                "description": (
                    (alt["notes"] if alt else "Demo alternative")
                    + " [DEMO — not verified availability]"
                ),
                "start_time": alt["depart_time"] if alt else "05:45",
                "end_time": alt["arrive_time"] if alt else "09:30",
                "travel_cost_lkr": alt["cost_lkr"] if alt else a["travel_cost_lkr"],
                "recovery_applied": True,
                "original_id": a["id"]
            };
            new_acts.append(replacement);
        }
        shifted = [];
        shift = delay_min;
        for a in new_acts {
            if a.get("id") == "act-d1-fort-walk" {
                st = time_to_minutes(a["start_time"]) + shift;
                en = time_to_minutes(a["end_time"]) + shift;
                a = {**a, "start_time": minutes_to_time(st), "end_time": minutes_to_time(en)};
            }
            shifted.append(a);
        }
        d["activities"] = shifted;
    }
    extra_cost = 0;
    if alt {
        extra_cost = int(alt.get("cost_lkr", 0)) - int(act.get("travel_cost_lkr", 0));
    }
    bud = budget_summary(trip);
    return {
        "ok": True,
        "reason": "missed_transport",
        "demo": True,
        "what_happened": choice,
        "impact": f"Schedule slip ~{delay_min} minutes; fort walk starts later.",
        "transport_recommendation": alt,
        "source_label": "DEMO_TRANSPORT",
        "original_plan": trip,
        "revised_plan": revised,
        "cost_delta_lkr": extra_cost,
        "budget_before": bud,
        "budget_after": {
            **bud,
            "projected_final_lkr": bud["projected_final_lkr"] + extra_cost
        },
        "changed_activity_ids": ["bus-colombo-galle-001", "act-d1-fort-walk"]
    };
}

def build_weather_disruption(trip: dict, activity_id: str) -> dict {
    hit = find_activity(trip, activity_id);
    if not hit {
        return {"ok": False, "error": "Activity not found."};
    }
    act = hit["activity"];
    alts = act.get("alternatives") or [];
    return {
        "ok": True,
        "demo": True,
        "type": "bad_weather",
        "title": "Weather may affect outdoor activity",
        "message": (
            "Heavy rain may affect your planned outdoor visit. "
            "I found alternatives that fit your remaining time and budget."
        ),
        "activity_id": activity_id,
        "forecast_source": "DEMO_WEATHER",
        "alternatives": alts,
        "revised_plan": apply_weather_swap(trip, activity_id, alts[0] if alts else None)
    };
}

def apply_weather_swap(trip: dict, activity_id: str, alt: any) -> dict {
    if not alt {
        return trip;
    }
    revised = json.loads(json.dumps(trip));
    for day in revised["days"] {
        acts = [];
        for a in day["activities"] {
            if a["id"] != activity_id {
                acts.append(a);
                continue;
            }
            acts.append({
                "id": a["id"],
                "type": "activity",
                "name": alt.get("name", "Indoor alternative"),
                "description": alt.get("description", "") + " [Weather swap — demo]",
                "destination": a["destination"],
                "start_time": a["start_time"],
                "end_time": minutes_to_time(time_to_minutes(a["start_time"]) + int(alt.get("duration_min", 90))),
                "duration_min": int(alt.get("duration_min", 90)),
                "transport_to_next": a.get("transport_to_next", "none"),
                "travel_time_min": a.get("travel_time_min", 0),
                "travel_cost_lkr": a.get("travel_cost_lkr", 0),
                "activity_cost_lkr": int(alt.get("cost_lkr", 0)),
                "indoor": True,
                "weather_sensitive": False,
                "alternatives": a.get("alternatives", []),
                "weather_recovery": True
            });
        }
        day["activities"] = acts;
    }
    return revised;
}

def detect_budget_disruption(trip: dict) -> any {
    bud = budget_summary(trip);
    if bud["spent_lkr"] > bud["planned_lkr"] {
        return {
            "type": "budget_exceeded",
            "message": (
                f"You have spent LKR {bud['spent_lkr']:,} of your LKR {bud['planned_lkr']:,} "
                f"planned budget. Remaining: LKR {bud['remaining_lkr']:,}. "
                "Would you like lower-cost options for remaining activities?"
            ),
            "budget": bud
        };
    }
    if bud["spent_lkr"] >= int(bud["planned_lkr"] * 0.85) {
        return {
            "type": "budget_trend",
            "message": (
                f"Spending is at {int(100 * bud['spent_lkr'] / max(bud['planned_lkr'], 1))}% "
                "of plan — consider adjusting remaining activities."
            ),
            "budget": bud
        };
    }
    return None;
}

def tripmate_intent(message: str) -> str {
    m = message.lower();
    if "recover" in m or "missed" in m or "bus" in m {
        return "recovery";
    }
    if "budget" in m or "spent" in m or "expense" in m {
        return "budget";
    }
    if "weather" in m or "rain" in m {
        return "weather";
    }
    if "summary" in m or "remaining" in m {
        return "summary";
    }
    if "change" in m or "modify" in m or "swap" in m {
        return "modify";
    }
    return "general";
}

def tripmate_reply(
    intent: str,
    trip: any,
    extra: dict
) -> dict {
    if not trip {
        return {
            "text": "Open a trip or create one from Plan — I'll use your real itinerary data.",
            "action": None
        };
    }
    bud = budget_summary(trip);
    if intent == "budget" {
        return {
            "text": (
                f"Budget: LKR {bud['spent_lkr']:,} spent of LKR {bud['planned_lkr']:,} planned. "
                f"Remaining LKR {bud['remaining_lkr']:,}."
            ),
            "action": None
        };
    }
    if intent == "summary" {
        days_left = len(trip.get("days", []));
        return {
            "text": (
                f"{trip['title']}: {days_left} day(s) in plan. "
                f"Remaining budget LKR {bud['remaining_lkr']:,}."
            ),
            "action": None
        };
    }
    if intent == "recovery" {
        return {
            "text": "I can run the recovery workflow for a confirmed disruption.",
            "action": {
                "type": "open_recovery",
                "trip_id": trip["id"]
            }
        };
    }
    if intent == "weather" {
        return {
            "text": "Review weather alternatives for outdoor activities?",
            "action": {
                "type": "open_weather",
                "trip_id": trip["id"],
                "activity_id": "act-d1-fort-walk"
            }
        };
    }
    if intent == "modify" and extra.get("proposed_plan") {
        return {
            "text": "Here's a proposed change — accept, edit, or reject.",
            "action": {
                "type": "proposed_plan",
                "plan": extra["proposed_plan"]
            }
        };
    }
    return {
        "text": (
            "I'm TripMate. Ask about your itinerary, budget, weather, or say "
            "'trigger recovery' after a disruption."
        ),
        "action": None
    };
}
