# views/Weather.cl.jac
cl import from "@jac/runtime" { useParams, Link, useNavigate }

sv import from ...main {
    get_weather,
    submit_weather_report,
    simulate_weather_disruption,
    apply_recovery
}

cl {
    def:pub WeatherPage() -> JsxElement {
        params = useParams();
        tripId = params.id if params else "sample-galle-2day";
        has wx: dict = {};
        has proposal: dict = {};
        has area: str = "Galle Fort";
        has reportCat: str = "Raining";
        nav = useNavigate();

        async def load() -> None {
            r = root spawn get_weather(trip_id=tripId);
            if r.reports and r.reports[0].get("ok") {
                wx = r.reports[0];
            }
        }

        async can with entry {
            await load();
        }

        async def submitReport() -> None {
            root spawn submit_weather_report(area=area, category=reportCat);
            await load();
        }

        async def simRain() -> None {
            r = root spawn simulate_weather_disruption(trip_id=tripId, activity_id="act-d1-fort-walk");
            if r.reports and r.reports[0].get("ok") {
                proposal = r.reports[0];
            }
        }

        async def acceptAlt() -> None {
            import json;
            if not proposal.get("revised_plan") {
                return;
            }
            root spawn apply_recovery(
                trip_id=tripId,
                proposal_json=json.dumps({
                    "ok": True,
                    "revised_plan": proposal["revised_plan"],
                    "reason": "bad_weather"
                }),
                decision="accept"
            );
            nav("/trips/" + tripId);
        }

        community = wx.get("community_reports", []);

        return <div className="page">
            <h2>Weather intelligence</h2>
            <div className="card">
                <h3>Forecast <span className="demo-badge">DEMO — not live</span></h3>
                {[<div key={f["location"]} style={{"marginBottom": "8px"}}>
                    <strong>{f["location"]}</strong>
                    <p className="muted">{f["summary"]} · {f["rain_probability"]}% rain · {f.get("label", "")}</p>
                </div> for f in wx.get("forecasts", [])]}
            </div>
            <div className="card">
                <h3>Local verification (optional)</h3>
                <p className="muted">{wx.get("disclaimer", "")}</p>
                <label>Area (approximate)</label>
                <input value={area} onChange={lambda e: any { area = e.target.value; }} />
                <label>What are you seeing?</label>
                <select value={reportCat} onChange={lambda e: any { reportCat = e.target.value; }}>
                    <option>Raining</option>
                    <option>Heavy rain</option>
                    <option>No rain</option>
                    <option>Flooding / travel disruption</option>
                </select>
                <button className="btn btn-secondary" onClick={submitReport}>Submit report</button>
                {community.length > 0 and <p className="muted">{community.length} recent report(s). Status: unverified — may agree or conflict with forecast.</p>}
                {community.length == 0 and <p className="muted">No community reports yet — using official/demo forecast only.</p>}
            </div>
            <button className="btn btn-primary" onClick={simRain}>Simulate rainy-day disruption (demo)</button>
            {proposal.get("ok") and <div className="card">
                <h3>{proposal.get("title", "Weather alert")}</h3>
                <p>{proposal.get("message", "")}</p>
                {[<div key={a.get("id", a.get("name", "alt"))} className="card" style={{"boxShadow": "none"}}>
                    <strong>{a.get("name", "Alternative")}</strong>
                    <p className="muted">{a.get("description", "")}</p>
                    <p className="muted">~{a.get("duration_min", 0)} min · LKR {a.get("cost_lkr", 0)}</p>
                </div> for a in proposal.get("alternatives", [])]}
                <button className="btn btn-primary" onClick={acceptAlt}>Accept revised plan</button>
                <button className="btn btn-ghost" onClick={lambda { proposal = {}; }}>Reject</button>
            </div>}
            <Link to={"/trips/" + tripId} className="muted">← Itinerary</Link>
        </div>;
    }
}
