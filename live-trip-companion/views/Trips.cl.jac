# views/Trips.cl.jac
cl import from "@jac/runtime" { Link, useParams, useNavigate }

sv import from ...main { list_trips, get_trip, save_trip, start_live_trip }

cl {
    def:pub TripsPage() -> JsxElement {
        has trips: list = [];

        async can with entry {
            r = root spawn list_trips();
            if r.reports and r.reports.length > 0 {
                trips = r.reports[0];
            }
        }

        return <div className="page">
            <h2>My Trips</h2>
            <Link to="/plan" className="btn btn-primary" style={{"display": "flex", "marginBottom": "12px"}}>
                + New trip
            </Link>
            {[<Link key={t["trip_id"]} to={"/trips/" + t["trip_id"]} className="card" style={{"display": "block"}}>
                <h3>{t["title"]} {t.get("is_sample") and <span className="demo-badge">SAMPLE</span>}</h3>
                <p className="muted">{t["destination"]}</p>
                <p className="muted">{t["start_date"]} → {t["end_date"]} · LKR {t["budget_lkr"]:,}</p>
            </Link> for t in trips]}
        </div>;
    }

    def:pub TripDetailPage() -> JsxElement {
        params = useParams();
        tripId = params.id if params else "";
        has trip: dict = {};
        has budget: dict = {};
        has planned: int = 0;
        nav = useNavigate();

        async def load() -> None {
            if not tripId {
                return;
            }
            r = root spawn get_trip(trip_id=tripId);
            if r.reports and r.reports.length > 0 and r.reports[0]["ok"] {
                trip = r.reports[0]["trip"];
                budget = r.reports[0]["budget"];
                planned = r.reports[0]["planned_cost_lkr"];
            }
        }

        async can with entry {
            await load();
        }

        async def persist() -> None {
            import json;
            root spawn save_trip(payload_json=json.dumps(trip));
            await load();
        }

        has locConsent: bool = False;

        async def startTrip() -> None {
            root spawn start_live_trip(trip_id=tripId, use_location=locConsent);
            nav("/live");
        }

        def removeActivity(dayIdx: int, actId: str) -> None {
            days = trip["days"];
            acts = days[dayIdx]["activities"];
            days[dayIdx]["activities"] = [a for a in acts if a["id"] != actId];
            trip = {**trip, "days": days};
            persist();
        }

        return <div className="page">
            {!trip and <p className="muted">Loading…</p>}
            {trip and <>
                <h2>{trip["title"]} {trip.get("is_sample") and <span className="demo-badge">SAMPLE</span>}</h2>
                <p className="muted">{trip["destination"]} · {trip["start_date"]} → {trip["end_date"]}</p>
                <div className="stat-grid">
                    <div className="stat"><span className="muted">Budget</span><strong>LKR {trip["budget_lkr"]:,}</strong></div>
                    <div className="stat"><span className="muted">Planned cost</span><strong>LKR {planned:,}</strong></div>
                </div>
                <div className="card">
                    <h3>Start Live Trip Mode</h3>
                    <p className="muted">
                        Live mode uses your check-ins (and optional GPS only while the session is active)
                        to detect schedule disruptions. You can pause or end tracking anytime.
                    </p>
                    <label>
                        <input type="checkbox" checked={locConsent} onChange={lambda e: any { locConsent = e.target.checked; }} />
                        Enable location during this live session
                    </label>
                </div>
                <button className="btn btn-primary" onClick={startTrip}>Start Trip</button>
                <Link to={"/budget?t=" + tripId} className="btn btn-secondary" style={{"display": "flex"}}>Budget</Link>
                <Link to={"/weather/" + tripId} className="btn btn-ghost" style={{"display": "flex"}}>Weather & alternatives</Link>
                <h3 style={{"marginTop": "20px"}}>Itinerary timeline</h3>
                {[<div key={"d-" + str(day["day_index"])} className="card">
                    <strong>{day["label"]}</strong>
                    <p className="muted">{day["date"]}</p>
                    <div className="timeline">
                        {[<div key={act["id"]} className="timeline-item card" style={{"boxShadow": "none"}}>
                            <strong>{act["name"]}</strong>
                            <p className="muted">{act["start_time"]} – {act["end_time"]} · {act["destination"]}</p>
                            <p className="muted">{act.get("description", "")}</p>
                            <p className="muted">
                                {act.get("indoor") and "Indoor" or "Outdoor"}
                                {act.get("weather_sensitive") and " · Weather sensitive" or ""}
                                · LKR {(act.get("activity_cost_lkr") or 0) + (act.get("travel_cost_lkr") or 0)}
                            </p>
                            <button className="btn btn-ghost" style={{"marginTop": "4px", "padding": "8px"}}
                                onClick={lambda d=day["day_index"], a=act["id"] { removeActivity(d, a); }}>
                                Remove stop
                            </button>
                        </div> for act in day["activities"]]}
                    </div>
                </div> for day in trip.get("days", [])]}
                {trip.get("history") and trip["history"].length > 0 and <div className="card">
                    <h3>Trip history</h3>
                    {[<p key={h.get("at", str(i))} className="muted">{h["type"]} — {h.get("at", "")}</p> for i, h in enumerate(trip["history"])]}
                </div>}
            </>}
        </div>;
    }
}
