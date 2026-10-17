# views/Budget.cl.jac
cl import from "@jac/runtime" { Link, useLocation }

sv import from ...main { get_budget_dashboard, add_expense }

cl {
    def:pub BudgetPage() -> JsxElement {
        loc = useLocation();
        has tripId: str = "sample-galle-2day";
        has data: dict = {};
        has amount: int = 1500;
        has merchant: str = "";
        has category: str = "Food and drinks";
        has date: str = "2025-11-15";
        has msg: str = "";

        async def load() -> None {
            r = root spawn get_budget_dashboard(trip_id=tripId);
            if r.reports and r.reports[0].get("ok") {
                data = r.reports[0];
            }
        }

        async can with entry {
            if loc and loc.search {
                # naive parse ?t=id
                q = loc.search;
                if "t=" in q {
                    tripId = q.split("t=")[1].split("&")[0];
                }
            }
            await load();
        }

        async def submitExpense(force: bool = False) -> None {
            import json;
            payload = {
                "amount_lkr": amount,
                "merchant": merchant,
                "category": category,
                "date": date,
                "currency": "LKR",
                "status": "confirmed",
                "force": force
            };
            r = root spawn add_expense(trip_id=tripId, payload_json=json.dumps(payload));
            if r.reports and r.reports[0].get("duplicate") {
                msg = "Possible duplicate — tap again to confirm.";
                return;
            }
            if r.reports and r.reports[0].get("ok") {
                msg = "Expense saved.";
                await load();
            }
        }

        summary = data.get("summary", {});
        spent = summary.get("spent_lkr", 0);
        planned = summary.get("planned_lkr", 1);
        pct = min(100, int(100 * spent / max(planned, 1)));

        return <div className="page">
            <h2>Budget</h2>
            <p className="muted">Trip: {tripId}</p>
            <div className="stat-grid">
                <div className="stat"><span className="muted">Planned</span><strong>LKR {planned:,}</strong></div>
                <div className="stat"><span className="muted">Spent</span><strong>LKR {spent:,}</strong></div>
                <div className="stat"><span className="muted">Remaining</span><strong>LKR {summary.get("remaining_lkr", 0):,}</strong></div>
                <div className="stat"><span className="muted">Projected</span><strong>LKR {summary.get("projected_final_lkr", 0):,}</strong></div>
            </div>
            <div className="progress-bar"><span style={{"width": str(pct) + "%"}} /></div>
            {summary.get("over_budget") and <div className="alert alert-warn">You are over the planned budget.</div>}
            <div className="card">
                <h3>By category</h3>
                {not data.get("by_category") and <p className="muted">No expenses yet.</p>}
                {[<p key={k} className="muted">{k}: LKR {v:,}</p> for k, v in data.get("by_category", {}).items()]}
            </div>
            <h3>Add expense</h3>
            <label>Amount (LKR)</label>
            <input type="number" value={amount} onChange={lambda e: any { amount = int(e.target.value or 0); }} />
            <label>Merchant</label>
            <input value={merchant} onChange={lambda e: any { merchant = e.target.value; }} />
            <label>Category</label>
            <select value={category} onChange={lambda e: any { category = e.target.value; }}>
                <option>Transport</option>
                <option>Accommodation</option>
                <option>Food and drinks</option>
                <option>Activities</option>
                <option>Shopping</option>
                <option>Other</option>
            </select>
            <label>Date</label>
            <input type="date" value={date} onChange={lambda e: any { date = e.target.value; }} />
            <button className="btn btn-primary" onClick={lambda { submitExpense(False); }}>Save expense</button>
            {msg and <p className="muted">{msg}</p>}
            <Link to={"/receipt/" + tripId} className="btn btn-secondary" style={{"display": "flex"}}>Scan receipt</Link>
        </div>;
    }
}
