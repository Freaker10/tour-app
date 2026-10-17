# views/Recovery.cl.jac
cl import from "@jac/runtime" { useParams, useNavigate, Link }

sv import from ...main { get_pending_recovery, apply_recovery, get_trip }

cl {
    def:pub ScheduleCompare(original: dict, revised: dict) -> JsxElement {
        oActs = [];
        rActs = [];
        oDays = original.get("days", []);
        rDays = revised.get("days", []);
        if oDays.length > 0 {
            oActs = oDays[0].get("activities", []);
        }
        if rDays.length > 0 {
            rActs = rDays[0].get("activities", []);
        }
        return <>
            <div className="card">
                <strong>Original (Day 1)</strong>
                {[<p key={"o-" + a["id"]} className="muted">{a["start_time"]} — {a["name"]}</p> for a in oActs]}
            </div>
            <div className="card">
                <strong>Revised (Day 1)</strong>
                {[<p key={"r-" + a["id"]} className="muted">{a["start_time"]} — {a["name"]}</p> for a in rActs]}
            </div>
        </>;
    }

    def:pub RecoveryPage() -> JsxElement {
        params = useParams();
        tripId = params.id if params else "";
        has proposal: dict = {};
        has trip: dict = {};
        nav = useNavigate();

        async can with entry {
            pr = root spawn get_pending_recovery();
            if pr.reports and pr.reports[0].get("ok") {
                proposal = pr.reports[0].get("proposal", {});
            }
            g = root spawn get_trip(trip_id=tripId);
            if g.reports and g.reports[0]["ok"] {
                trip = g.reports[0]["trip"];
            }
        }

        async def decide(decision: str) -> None {
            import json;
            r = root spawn apply_recovery(
                trip_id=tripId,
                proposal_json=json.dumps(proposal),
                decision=decision
            );
            if decision == "accept" and r.reports and r.reports[0].get("applied") {
                nav("/trips/" + tripId);
                return;
            }
            if decision == "reject" {
                nav("/live");
                return;
            }
            nav("/trips/" + tripId);
        }

        revised = proposal.get("revised_plan", {}) if proposal else {};
        original = proposal.get("original_plan", trip);

        return <div className="page">
            <h2>Trip Recovery</h2>
            {!proposal.get("ok") and <p className="muted">No pending recovery — simulate a disruption from Live Trip.</p>}
            {proposal.get("ok") and <>
                <div className="alert alert-warn">
                    <strong>{proposal.get("what_happened", "Disruption")}</strong>
                    <span className="demo-badge">DEMO</span>
                    <p>{proposal.get("impact", "")}</p>
                </div>
                {proposal.get("transport_recommendation") and <div className="card">
                    <h3>Recommended transport</h3>
                    <p>{proposal["transport_recommendation"]["label"]}</p>
                    <p className="muted">{proposal["transport_recommendation"].get("notes", "")}</p>
                    <p className="muted">Source: {proposal.get("source_label", "DEMO")}</p>
                </div>}
                <div className="card">
                    <h3>Budget impact</h3>
                    <p className="muted">
                        Extra cost estimate: LKR {proposal.get("cost_delta_lkr", 0):,} ·
                        Remaining after change: LKR {proposal.get("budget_after", {}).get("remaining_lkr", 0):,}
                    </p>
                </div>
                <h3>Schedule comparison</h3>
                <ScheduleCompare original={original} revised={revised} />
                <button className="btn btn-primary" onClick={lambda { decide("accept"); }}>Accept Changes</button>
                <button className="btn btn-secondary" onClick={lambda { decide("edit"); }}>Edit Plan</button>
                <button className="btn btn-ghost" onClick={lambda { decide("reject"); }}>Keep Original</button>
            </>}
            <Link to="/live" className="muted">← Back to Live Trip</Link>
        </div>;
    }
}
