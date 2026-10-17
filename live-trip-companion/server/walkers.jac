"""Public API walkers for client workflows."""

walker:pub bootstrap {
    has reports: list[dict] = [];

    can seed with Root entry {
        if not [root-->][?:UserPrefs] {
            prefs = UserPrefs(onboarded=False, prefs_json="{}");
            root ++> prefs;
            save(prefs);
        }
        if not [root-->][?:Trip] {
            sample = sample_galle_trip();
            t = Trip(
                trip_id=sample["id"],
                payload_json=json.dumps(sample),
                updated_at=now_iso()
            );
            root ++> t;
            save(t);
        }
        commit();
        report {"ok": True, "sample_trip_id": "sample-galle-2day"};
    }
}

walker:pub get_prefs {
    has reports: list[dict] = [];

    can fetch with Root entry {
        prefs = [root-->][?:UserPrefs];
        if prefs {
            p = prefs[0];
            report {
                "onboarded": p.onboarded,
                "prefs": json.loads(p.prefs_json)
            };
        } else {
            report {"onboarded": False, "prefs": {}};
        }
    }
}

walker:pub save_prefs {
    has onboarded: bool = True;
    has prefs_json: str = "{}";
    has reports: list[dict] = [];

    can write with Root entry {
        nodes = [root-->][?:UserPrefs];
        if nodes {
            p = nodes[0];
        } else {
            p = UserPrefs();
            root ++> p;
        }
        p.onboarded = self.onboarded;
        p.prefs_json = self.prefs_json;
        save(p);
        commit();
        report {"ok": True};
    }
}

walker:pub list_trips {
    has reports: list[list[dict]] = [];
    has items: list[dict] = [];

    can collect with Root entry {
        visit [-->];
    }

    can gather with Trip entry {
        payload = parse_trip(here);
        self.items.append({
            "trip_id": here.trip_id,
            "title": payload.get("title", ""),
            "destination": payload.get("destination", ""),
            "start_date": payload.get("start_date", ""),
            "end_date": payload.get("end_date", ""),
            "is_sample": payload.get("is_sample", False),
            "budget_lkr": payload.get("budget_lkr", 0)
        });
    }

    can done with Root exit {
        report self.items;
    }
}

walker:pub get_trip {
    has trip_id: str;
    has reports: list[dict] = [];

    can fetch with Root entry {
        node = find_trip_node(self.trip_id);
        if not node {
            report {"ok": False, "error": "Trip not found"};
            return;
        }
        payload = parse_trip(node);
        report {
            "ok": True,
            "trip": payload,
            "budget": budget_summary(payload),
            "planned_cost_lkr": sum_planned_cost(payload)
        };
    }
}

walker:pub save_trip {
    has payload_json: str;
    has reports: list[dict] = [];

    can write with Root entry {
        payload = json.loads(self.payload_json);
        tid = payload.get("id") or new_id("trip");
        payload["id"] = tid;
        node = find_trip_node(tid);
        if not node {
            node = Trip(trip_id=tid, payload_json=json.dumps(payload));
            root ++> node;
        } else {
            save_trip_payload(node, payload);
            report {"ok": True, "trip_id": tid};
            return;
        }
        save_trip_payload(node, payload);
        report {"ok": True, "trip_id": tid};
    }
}

walker:pub regenerate_itinerary {
    has trip_id: str;
    has reports: list[dict] = [];

    can regen with Root entry {
        node = find_trip_node(self.trip_id);
        if not node {
            report {"ok": False, "error": "Trip not found"};
            return;
        }
        base = sample_galle_trip();
        base["id"] = self.trip_id;
        base["title"] = parse_trip(node).get("title", base["title"]);
        base["preferences"] = parse_trip(node).get("preferences", base["preferences"]);
        base["budget_lkr"] = parse_trip(node).get("budget_lkr", base["budget_lkr"]);
        save_trip_payload(node, base);
        report {"ok": True, "trip": base};
    }
}

walker:pub start_live_trip {
    has trip_id: str;
    has use_location: bool = False;
    has reports: list[dict] = [];

    can start with Root entry {
        for s in [root-->][?:LiveSession] {
            s.active = False;
            save(s);
        }
        state = {
            "trip_id": self.trip_id,
            "started_at": now_iso(),
            "paused": False,
            "location_enabled": self.use_location,
            "simulated_clock": "04:30",
            "current_day_index": 0,
            "progress": {"completed_activity_ids": [], "notes": ""},
            "pending_disruption": None
        };
        sess = LiveSession(
            session_id=new_id("live"),
            trip_id=self.trip_id,
            state_json=json.dumps(state),
            active=True
        );
        root ++> sess;
        save(sess);
        commit();
        report {"ok": True, "session": state};
    }
}

walker:pub pause_live_trip {
    has pause: bool = True;
    has reports: list[dict] = [];

    can toggle with Root entry {
        sess = get_active_session();
        if not sess {
            report {"ok": False, "error": "No active live session"};
            return;
        }
        state = json.loads(sess.state_json);
        state["paused"] = self.pause;
        sess.state_json = json.dumps(state);
        save(sess);
        commit();
        report {"ok": True, "session": state};
    }
}

walker:pub end_live_trip {
    has reports: list[dict] = [];

    can stop with Root entry {
        sess = get_active_session();
        if sess {
            sess.active = False;
            save(sess);
            commit();
        }
        report {"ok": True};
    }
}

walker:pub get_live_dashboard {
    has reports: list[dict] = [];

    can fetch with Root entry {
        sess = get_active_session();
        if not sess {
            report {"ok": False, "active": False};
            return;
        }
        state = json.loads(sess.state_json);
        node = find_trip_node(sess.trip_id);
        trip = parse_trip(node) if node else {};
        bud = budget_summary(trip) if trip else {};
        weather = demo_weather_for_trip(trip) if trip else [];
        disruption = detect_budget_disruption(trip) if trip else None;
        next_act = None;
        days = trip.get("days", []);
        if days {
            acts = days[state.get("current_day_index", 0)].get("activities", []);
            if acts {
                next_act = acts[0];
                for a in acts {
                    if a["id"] not in state.get("progress", {}).get("completed_activity_ids", []) {
                        next_act = a;
                        break;
                    }
                }
            }
        }
        report {
            "ok": True,
            "active": True,
            "paused": state.get("paused", False),
            "session": state,
            "trip": {"id": trip.get("id"), "title": trip.get("title")},
            "current_day": days[state.get("current_day_index", 0)] if days else None,
            "next_activity": next_act,
            "budget": bud,
            "weather": weather,
            "budget_alert": disruption
        };
    }
}

walker:pub manual_checkin {
    has note: str = "";
    has activity_id: str = "";
    has reports: list[dict] = [];

    can check with Root entry {
        sess = get_active_session();
        if not sess {
            report {"ok": False, "error": "No active session"};
            return;
        }
        state = json.loads(sess.state_json);
        checkins = state.get("manual_checkins", []);
        checkins.append({
            "at": now_iso(),
            "note": self.note,
            "activity_id": self.activity_id
        });
        state["manual_checkins"] = checkins;
        if self.activity_id {
            prog = state.get("progress", {"completed_activity_ids": []});
            ids = prog.get("completed_activity_ids", []);
            if self.activity_id not in ids {
                ids.append(self.activity_id);
            }
            prog["completed_activity_ids"] = ids;
            state["progress"] = prog;
        }
        sess.state_json = json.dumps(state);
        save(sess);
        commit();
        report {"ok": True, "session": state};
    }
}

walker:pub simulate_missed_bus {
    has reports: list[dict] = [];

    can demo with Root entry {
        sess = get_active_session();
        if not sess {
            report {"ok": False, "error": "Start Live Trip first"};
            return;
        }
        state = json.loads(sess.state_json);
        state["simulated_clock"] = "04:30";
        state["demo_event"] = "missed_bus";
        node = find_trip_node(sess.trip_id);
        trip = parse_trip(node);
        disruption = build_missed_bus_disruption(trip, state);
        state["pending_disruption"] = disruption;
        sess.state_json = json.dumps(state);
        save(sess);
        commit();
        report {"ok": True, "disruption": disruption, "demo": True};
    }
}

walker:pub get_pending_recovery {
    has reports: list[dict] = [];

    can fetch with Root entry {
        sess = get_active_session();
        if not sess {
            report {"ok": False};
            return;
        }
        state = json.loads(sess.state_json);
        report {"ok": True, "proposal": state.get("pending_recovery"), "trip_id": sess.trip_id};
    }
}

walker:pub confirm_disruption {
    has choice: str;
    has reports: list[dict] = [];

    can confirm with Root entry {
        sess = get_active_session();
        if not sess {
            report {"ok": False, "error": "No active session"};
            return;
        }
        node = find_trip_node(sess.trip_id);
        trip = parse_trip(node);
        proposal = build_recovery_for_missed_bus(trip, self.choice);
        state = json.loads(sess.state_json);
        state["pending_recovery"] = proposal;
        sess.state_json = json.dumps(state);
        save(sess);
        commit();
        report {"ok": True, "proposal": proposal};
    }
}

walker:pub apply_recovery {
    has trip_id: str;
    has proposal_json: str;
    has decision: str;
    has reports: list[dict] = [];

    can apply with Root entry {
        proposal = json.loads(self.proposal_json);
        node = find_trip_node(self.trip_id);
        if not node {
            report {"ok": False, "error": "Trip not found"};
            return;
        }
        trip = parse_trip(node);
        if self.decision == "reject" {
            rec = RecoveryRecord(
                record_id=new_id("rec"),
                trip_id=self.trip_id,
                payload_json=json.dumps({"decision": "reject", "proposal": proposal}),
                created_at=now_iso()
            );
            root ++> rec;
            save(rec);
            commit();
            report {"ok": True, "applied": False};
            return;
        }
        if self.decision == "accept" and proposal.get("revised_plan") {
            revised = proposal["revised_plan"];
            hist = trip.get("history", []);
            hist.append({
                "at": now_iso(),
                "type": "recovery_accepted",
                "reason": proposal.get("reason"),
                "demo": proposal.get("demo", False)
            });
            revised["history"] = hist;
            save_trip_payload(node, revised);
            rec = RecoveryRecord(
                record_id=new_id("rec"),
                trip_id=self.trip_id,
                payload_json=json.dumps({"decision": "accept", "proposal": proposal}),
                created_at=now_iso()
            );
            root ++> rec;
            save(rec);
            commit();
            report {"ok": True, "applied": True, "trip": revised};
            return;
        }
        report {"ok": True, "applied": False, "message": "Edit flow keeps original until you accept."};
    }
}

walker:pub get_budget_dashboard {
    has trip_id: str;
    has reports: list[dict] = [];

    can fetch with Root entry {
        node = find_trip_node(self.trip_id);
        if not node {
            report {"ok": False};
            return;
        }
        trip = parse_trip(node);
        exps = expenses_for_trip(self.trip_id);
        by_cat = {};
        for e in exps {
            if e.get("status") != "confirmed" {
                continue;
            }
            cat = e.get("category", "Other");
            by_cat[cat] = by_cat.get(cat, 0) + int(e.get("amount_lkr", 0));
        }
        report {
            "ok": True,
            "summary": budget_summary(trip),
            "expenses": exps,
            "by_category": by_cat,
            "planned_activity_cost_lkr": sum_planned_cost(trip)
        };
    }
}

walker:pub add_expense {
    has trip_id: str;
    has payload_json: str;
    has reports: list[dict] = [];

    can create with Root entry {
        payload = json.loads(self.payload_json);
        payload["expense_id"] = payload.get("expense_id") or new_id("exp");
        payload["status"] = payload.get("status", "confirmed");
        dup = False;
        for e in [root-->][?:Expense] {
            if e.trip_id != self.trip_id {
                continue;
            }
            p = json.loads(e.payload_json);
            if (
                p.get("status") == "confirmed"
                and p.get("amount_lkr") == payload.get("amount_lkr")
                and p.get("merchant") == payload.get("merchant")
                and p.get("date") == payload.get("date")
            ) {
                dup = True;
                break;
            }
        }
        if dup and not payload.get("force") {
            report {"ok": False, "duplicate": True, "message": "Similar receipt already recorded."};
            return;
        }
        exp = Expense(
            expense_id=payload["expense_id"],
            trip_id=self.trip_id,
            payload_json=json.dumps(payload)
        );
        root ++> exp;
        save(exp);
        commit();
        node = find_trip_node(self.trip_id);
        trip = parse_trip(node);
        report {"ok": True, "expense": payload, "budget": budget_summary(trip)};
    }
}

walker:pub extract_receipt {
    has image_name: str = "demo";
    has reports: list[dict] = [];

    can ocr with Root entry {
        data = demo_receipt_extraction();
        data["image_name"] = self.image_name;
        report {"ok": True, "extraction": data, "requires_confirmation": True};
    }
}

walker:pub get_weather {
    has trip_id: str;
    has reports: list[dict] = [];

    can fetch with Root entry {
        node = find_trip_node(self.trip_id);
        trip = parse_trip(node) if node else {};
        forecasts = demo_weather_for_trip(trip);
        reports_local = [];
        for r in [root-->][?:WeatherReport] {
            reports_local.append({
                "area": r.area,
                "category": r.category,
                "created_at": r.created_at,
                "verification": r.verification
            });
        }
        report {
            "ok": True,
            "forecasts": forecasts,
            "community_reports": reports_local,
            "disclaimer": "Community reports are unverified."
        };
    }
}

walker:pub submit_weather_report {
    has area: str;
    has category: str;
    has reports: list[dict] = [];

    can post with Root entry {
        rep = WeatherReport(
            report_id=new_id("wx"),
            area=self.area,
            category=self.category,
            created_at=now_iso(),
            verification="unverified"
        );
        root ++> rep;
        save(rep);
        commit();
        report {"ok": True, "report_id": rep.report_id};
    }
}

walker:pub simulate_weather_disruption {
    has trip_id: str;
    has activity_id: str = "act-d1-fort-walk";
    has reports: list[dict] = [];

    can demo with Root entry {
        node = find_trip_node(self.trip_id);
        trip = parse_trip(node);
        payload = build_weather_disruption(trip, self.activity_id);
        report payload;
    }
}

walker:pub tripmate_chat {
    has trip_id: str = "";
    has message: str;
    has reports: list[dict] = [];

    can chat with Root entry {
        trip = None;
        if self.trip_id {
            node = find_trip_node(self.trip_id);
            if node {
                trip = parse_trip(node);
            }
        }
        intent = tripmate_intent(self.message);
        reply = tripmate_reply(intent, trip, {});
        report {"ok": True, "intent": intent, "reply": reply};
    }
}

walker:pub get_trip_history {
    has trip_id: str;
    has reports: list[dict] = [];

    can fetch with Root entry {
        items = [];
        for rec in [root-->][?:RecoveryRecord] {
            if rec.trip_id == self.trip_id {
                items.append(json.loads(rec.payload_json));
            }
        }
        trip_node = find_trip_node(self.trip_id);
        hist = [];
        if trip_node {
            hist = parse_trip(trip_node).get("history", []);
        }
        report {"recovery_records": items, "itinerary_history": hist};
    }
}
