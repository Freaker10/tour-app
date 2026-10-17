# views/Live.cl.jac
cl import from "@jac/runtime" { Link, useNavigate }

sv import from ...main {
    get_live_dashboard,
    simulate_missed_bus,
    confirm_disruption,
    pause_live_trip,
    end_live_trip,
    manual_checkin,
    start_live_trip
}

cl {
    def:pub LivePage() -> JsxElement {
        has dash: dict = {};
        has disruption: dict = {};
        has error: str = "";
        nav = useNavigate();

        async def refresh() -> None {
            r = root spawn get_live_dashboard();
            if r.reports and r.reports.length > 0 {
                dash = r.reports[0];
            }
        }

        async can with entry {
            await refresh();
        }

        async def ensureLive() -> None {
            if dash.get("ok") {
                return;
            }
            root spawn start_live_trip(trip_id="sample-galle-2day", use_location=False);
            await refresh();
        }

        async def simBus() -> None {
            await ensureLive();
            r = root spawn simulate_missed_bus();
            if r.reports and r.reports[0].get("ok") {
                disruption = r.reports[0]["disruption"];
            } else {
                error = r.reports[0].get("error", "Could not simulate") if r.reports else "Error";
            }
        }

        async def onChoice(choice: str) -> None {
            if choice == "Update my status" {
                root spawn manual_checkin(note="Status updated by traveller", activity_id="");
                await refresh();
                return;
            }
            r = root spawn confirm_disruption(choice=choice);
            if r.reports and r.reports[0].get("ok") {
                prop = r.reports[0]["proposal"];
                if prop.get("action") == "wait" {
                    disruption = {};
                    error = prop.get("message", "");
                    return;
                }
                session = dash.get("session", {});
                tid = session.get("trip_id", "sample-galle-2day");
                nav("/recovery/" + tid);
            }
        }

        async def togglePause() -> None {
            paused = dash.get("paused", False);
            root spawn pause_live_trip(pause=not paused);
            await refresh();
        }

        async def endTrip() -> None {
            root spawn end_live_trip();
            await refresh();
        }

        session = dash.get("session", {}) if dash else {};
        active = dash.get("active", False);

        return <div className="page">
            <h2>Live Trip</h2>
            {!active and <div className="alert alert-info">
                <p>Live Trip Mode is off. Start from a saved trip or use the sample below.</p>
                <button className="btn btn-primary" onClick={ensureLive}>Start sample Galle trip</button>
            </div>}
            {active and <>
                <div className="card">
                    <h3>{dash.get("trip", {}).get("title", "Active trip")} <span className="demo-badge">LIVE</span></h3>
                    <p className="muted">
                        Day: {dash.get("current_day", {}).get("label", "—")}
                        {dash.get("paused") and " · Paused" or ""}
                    </p>
                    {not session.get("location_enabled") and <p className="muted">GPS off — using manual check-ins.</p>}
                </div>
                <div className="card">
                    <h3>Next up</h3>
                    {dash.get("next_activity") and <>
                        <strong>{dash["next_activity"]["name"]}</strong>
                        <p className="muted">{dash["next_activity"]["start_time"]} · {dash["next_activity"]["destination"]}</p>
                    </> or <p className="muted">No upcoming activity.</p>}
                </div>
                <div className="stat-grid">
                    <div className="stat">
                        <span className="muted">Remaining budget</span>
                        <strong>LKR {dash.get("budget", {}).get("remaining_lkr", 0):,}</strong>
                    </div>
                    <div className="stat">
                        <span className="muted">Simulated clock</span>
                        <strong>{session.get("simulated_clock", "—")}</strong>
                    </div>
                </div>
                {dash.get("weather") and <div className="card">
                    <h3>Weather <span className="demo-badge">DEMO</span></h3>
                    {[<p key={w["location"]} className="muted">{w["location"]}: {w["summary"]} ({w["rain_probability"]}% rain)</p> for w in dash["weather"]]}
                </div>}
                {dash.get("budget_alert") and <div className="alert alert-warn">{dash["budget_alert"]["message"]}</div>}
                <button className="btn btn-primary" onClick={simBus}>Simulate missed bus (demo)</button>
                <button className="btn btn-secondary" onClick={lambda { root spawn manual_checkin(note="Checked in manually", activity_id=dash.get("next_activity", {}).get("id", "")); refresh(); }}>
                    Manual check-in
                </button>
                <button className="btn btn-ghost" onClick={togglePause}>{dash.get("paused") and "Resume" or "Pause Trip"}</button>
                <button className="btn btn-danger" onClick={endTrip}>End Trip</button>
            </>}
            {disruption and disruption.get("ok") and <div className="card">
                <h3>{disruption["title"]} <span className="demo-badge">SIMULATED</span></h3>
                <p>{disruption["message"]}</p>
                <p className="muted">Scheduled: {disruption.get("scheduled_departure")} · Observed: {disruption.get("observed_time")}</p>
                {[<button key={c} className="btn btn-secondary" onClick={lambda ch=c { onChoice(ch); }}>{c}</button> for c in disruption.get("choices", [])]}
            </div>}
            {error and <p className="muted">{error}</p>}
            <Link to="/tripmate" className="muted">Ask TripMate →</Link>
        </div>;
    }
}
