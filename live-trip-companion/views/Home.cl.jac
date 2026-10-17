# views/Home.cl.jac
cl import from "@jac/runtime" { Link, useNavigate }
cl import from react { useEffect }

sv import from ...main { list_trips, get_trip }

cl {
    def:pub HomePage() -> JsxElement {
        has trips: list = [];
        has sample: dict = {};
        nav = useNavigate();

        async can with entry {
            r = root spawn list_trips();
            if r.reports and r.reports.length > 0 {
                trips = r.reports[0];
            }
            g = root spawn get_trip(trip_id="sample-galle-2day");
            if g.reports and g.reports.length > 0 and g.reports[0]["ok"] {
                sample = g.reports[0]["trip"];
            }
        }

        return <div className="page">
            <div className="hero-photo">
                <div>
                    <h1 style={{"margin": 0, "fontSize": "1.4rem"}}>Live Trip Companion</h1>
                    <p style={{"margin": "4px 0 0", "opacity": 0.9}}>Sri Lanka travel, live.</p>
                </div>
            </div>
            <div className="card">
                <h3>Quick start</h3>
                <p className="muted">Open the sample Galle trip and run the missed-bus demo instantly.</p>
                <Link to="/trips/sample-galle-2day" className="btn btn-primary" style={{"display": "flex"}}>
                    Open sample trip
                </Link>
                <Link to="/plan" className="btn btn-secondary" style={{"display": "flex"}}>
                    Plan a new trip
                </Link>
                <Link to="/welcome" className="btn btn-ghost" style={{"display": "flex"}}>
                    Travel preferences
                </Link>
            </div>
            {sample and sample.get("title") and <div className="card">
                <h3>{sample["title"]} <span className="demo-badge">SAMPLE</span></h3>
                <p className="muted">{sample["destination"]} · LKR {sample["budget_lkr"]:,} budget</p>
                <button className="btn btn-primary" onClick={lambda { nav("/live"); }}>
                    Go to Live Trip
                </button>
            </div>}
            <div className="card">
                <h3>Upcoming trips</h3>
                {trips.length == 0 and <p className="muted">No trips yet — create one in Plan.</p>}
                {[<Link key={t["trip_id"]} to={"/trips/" + t["trip_id"]} className="card" style={{"display": "block", "marginTop": "8px"}}>
                    <strong>{t["title"]}</strong>
                    <p className="muted">{t["start_date"]} → {t["end_date"]}</p>
                </Link> for t in trips]}
            </div>
            <Link to="/settings" className="muted">Trip settings & privacy →</Link>
        </div>;
    }
}
