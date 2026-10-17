# views/Receipt.cl.jac
cl import from "@jac/runtime" { useParams, Link, useNavigate }

sv import from ...main { extract_receipt, add_expense }

cl {
    def:pub ReceiptPage() -> JsxElement {
        params = useParams();
        tripId = params.id if params else "sample-galle-2day";
        has extraction: dict = {};
        has confirmed: bool = False;
        has msg: str = "";
        nav = useNavigate();

        async def runOcr() -> None {
            r = root spawn extract_receipt(image_name="upload-demo.jpg");
            if r.reports and r.reports[0].get("ok") {
                extraction = r.reports[0]["extraction"];
            }
        }

        async def saveConfirmed() -> None {
            if not extraction {
                return;
            }
            import json;
            payload = {
                "amount_lkr": extraction.get("amount_lkr", 0),
                "merchant": extraction.get("merchant", ""),
                "category": extraction.get("category", "Other"),
                "date": extraction.get("date", ""),
                "currency": "LKR",
                "status": "confirmed",
                "source": extraction.get("source", "DEMO_OCR")
            };
            r = root spawn add_expense(trip_id=tripId, payload_json=json.dumps(payload));
            if r.reports and r.reports[0].get("ok") {
                msg = "Expense confirmed and saved.";
                confirmed = True;
            }
        }

        return <div className="page">
            <h2>Receipt</h2>
            <p className="muted">Upload or capture a receipt — extraction requires your confirmation.</p>
            <input type="file" accept="image/*" capture="environment" onChange={lambda e: any { runOcr(); }} />
            <button className="btn btn-secondary" onClick={runOcr}>Use demo receipt scan</button>
            {extraction and <>
                <div className="card">
                    <h3>Extracted data <span className="demo-badge">{extraction.get("source", "DEMO")}</span></h3>
                    <p className="muted">{extraction.get("label", "")}</p>
                    <label>Merchant</label>
                    <input value={extraction.get("merchant", "")} onChange={lambda e: any { extraction = {**extraction, "merchant": e.target.value}; }} />
                    <label>Amount (LKR)</label>
                    <input type="number" value={extraction.get("amount_lkr", 0)} onChange={lambda e: any { extraction = {**extraction, "amount_lkr": int(e.target.value or 0)}; }} />
                    <label>Category</label>
                    <input value={extraction.get("category", "")} onChange={lambda e: any { extraction = {**extraction, "category": e.target.value}; }} />
                    <label>Date</label>
                    <input type="date" value={extraction.get("date", "")} onChange={lambda e: any { extraction = {**extraction, "date": e.target.value}; }} />
                </div>
                <button className="btn btn-primary" onClick={saveConfirmed} disabled={confirmed}>Confirm & save</button>
            </>}
            {msg and <p className="muted">{msg}</p>}
            <Link to={"/budget?t=" + tripId} className="muted">← Budget dashboard</Link>
        </div>;
    }
}
