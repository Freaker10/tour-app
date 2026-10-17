# views/Plan.cl.jac
cl import from "@jac/runtime" { useNavigate }

sv import from ...main { save_trip, regenerate_itinerary }

cl {
    def:pub PlanPage() -> JsxElement {
        has destination: str = "Galle, Sri Lanka";
        has startDate: str = "2025-12-01";
        has endDate: str = "2025-12-03";
        has travelers: int = 2;
        has budget: int = 50000;
        has pace: str = "balanced";
        has status: str = "";
        nav = useNavigate();

        async def createTrip() -> None {
            import json;
            payload = {
                "id": "",
                "title": "Trip to " + destination,
                "destination": destination,
                "start_date": startDate,
                "end_date": endDate,
                "travelers": travelers,
                "budget_lkr": budget,
                "currency": "LKR",
                "is_sample": False,
                "preferences": {"pace": pace, "interests": ["culture", "food"], "transport": "public_bus_and_train"},
                "status": "saved",
                "days": [],
                "history": []
            };
            r = root spawn save_trip(payload_json=json.dumps(payload));
            if r.reports and r.reports.length > 0 {
                tid = r.reports[0]["trip_id"];
                root spawn regenerate_itinerary(trip_id=tid);
                nav("/trips/" + tid);
            }
        }

        return <div className="page">
            <h2>AI Trip Planning</h2>
            <p className="muted">TripMate uses your inputs to build a structured itinerary (demo regenerates from the Galle template).</p>
            <label>Destination</label>
            <input value={destination} onChange={lambda e: any { destination = e.target.value; }} />
            <label>Start date</label>
            <input type="date" value={startDate} onChange={lambda e: any { startDate = e.target.value; }} />
            <label>End date</label>
            <input type="date" value={endDate} onChange={lambda e: any { endDate = e.target.value; }} />
            <label>Travellers</label>
            <input type="number" value={travelers} onChange={lambda e: any { travelers = int(e.target.value or 2); }} />
            <label>Total budget (LKR)</label>
            <input type="number" value={budget} onChange={lambda e: any { budget = int(e.target.value or 0); }} />
            <label>Travel pace</label>
            <select value={pace} onChange={lambda e: any { pace = e.target.value; }}>
                <option value="relaxed">Relaxed</option>
                <option value="balanced">Balanced</option>
                <option value="packed">Packed</option>
            </select>
            <button className="btn btn-primary" onClick={createTrip}>Generate & save itinerary</button>
            {status and <p className="muted">{status}</p>}
        </div>;
    }
}
