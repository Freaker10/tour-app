# views/TripMate.cl.jac
cl import from "@jac/runtime" { Link, useNavigate }

sv import from ...main { tripmate_chat, apply_recovery, get_pending_recovery, add_expense }

cl {
    def:pub TripMatePage() -> JsxElement {
        has messages: list = [
            {"role": "bot", "text": "Hi! I'm TripMate. I use your real trip data — try \"What's my budget?\" or \"Trigger recovery\"."}
        ];
        has input: str = "";
        has actionCard: dict = {};
        has tripId: str = "sample-galle-2day";
        nav = useNavigate();

        async def send() -> None {
            if not input.strip() {
                return;
            }
            text = input;
            messages = messages + [{"role": "user", "text": text}];
            input = "";
            r = root spawn tripmate_chat(trip_id=tripId, message=text);
            if r.reports and r.reports[0].get("ok") {
                reply = r.reports[0]["reply"];
                messages = messages + [{"role": "bot", "text": reply["text"]}];
                if reply.get("action") {
                    actionCard = reply["action"];
                }
            }
        }

        async def acceptAction() -> None {
            if actionCard.get("type") == "open_recovery" {
                nav("/live");
                return;
            }
            if actionCard.get("type") == "open_weather" {
                nav("/weather/" + actionCard.get("trip_id", tripId));
                return;
            }
            if actionCard.get("type") == "proposed_plan" {
                import json;
                root spawn apply_recovery(
                    trip_id=tripId,
                    proposal_json=json.dumps({"ok": True, "revised_plan": actionCard["plan"]}),
                    decision="accept"
                );
                actionCard = {};
                messages = messages + [{"role": "bot", "text": "Changes applied to your saved trip."}];
            }
        }

        return <div className="page">
            <h2>TripMate AI</h2>
            <p className="muted">Conversational assistant wired to app workflows (not a mock chatbot).</p>
            <div style={{"minHeight": "240px"}}>
                {[<div key={str(i)} className={"chat-bubble " + ("chat-user" if m["role"] == "user" else "chat-bot")}>
                    {m["text"]}
                </div> for i, m in enumerate(messages)]}
            </div>
            {actionCard and <div className="card">
                <h3>Proposed action</h3>
                <p className="muted">{actionCard.get("type", "")}</p>
                <button className="btn btn-primary" onClick={acceptAction}>Accept</button>
                <button className="btn btn-ghost" onClick={lambda { actionCard = {}; }}>Reject</button>
            </div>}
            <input
                placeholder="Ask TripMate…"
                value={input}
                onChange={lambda e: any { input = e.target.value; }}
                onKeyDown={lambda e: any { if e.key == "Enter" { send(); } }}
            />
            <button className="btn btn-primary" onClick={send}>Send</button>
            <Link to="/live" className="muted">Live Trip & recovery →</Link>
        </div>;
    }
}
