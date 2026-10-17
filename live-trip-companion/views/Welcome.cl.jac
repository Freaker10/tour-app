# views/Welcome.cl.jac
cl import from "@jac/runtime" { useNavigate }
cl import from react { useState }

sv import from ...main { save_prefs }

cl {
    def:pub WelcomePage() -> JsxElement {
        has interests: list = [];
        has pace: str = "balanced";
        has transport: str = "public_bus_and_train";
        nav = useNavigate();

        def toggleInterest(tag: str) -> None {
            if tag in interests {
                interests = [x for x in interests if x != tag];
            } else {
                interests = interests + [tag];
            }
        }

        async def saveAndContinue() -> None {
            prefs = {
                "interests": interests,
                "pace": pace,
                "transport": transport,
                "dietary": "none",
                "accessibility": "none"
            };
            import json;
            root spawn save_prefs(onboarded=True, prefs_json=json.dumps(prefs));
            nav("/");
        }

        tags = ["beaches", "nature", "culture", "adventure", "food", "photography", "relaxation"];

        return <div className="page">
            <h2>Welcome</h2>
            <p className="muted">Set travel preferences for smarter itineraries. You can skip and use the sample trip.</p>
            <label>Interests</label>
            <div className="chip-row">
                {[<button
                    key={tag}
                    type="button"
                    className={"chip" + (" selected" if tag in interests else "")}
                    onClick={lambda t=tag { toggleInterest(t); }}
                >{tag}</button> for tag in tags]}
            </div>
            <label>Pace</label>
            <select value={pace} onChange={lambda e: any { pace = e.target.value; }}>
                <option value="relaxed">Relaxed</option>
                <option value="balanced">Balanced</option>
                <option value="packed">Packed</option>
            </select>
            <label>Preferred transportation</label>
            <select value={transport} onChange={lambda e: any { transport = e.target.value; }}>
                <option value="public_bus_and_train">Public bus & train</option>
                <option value="private_car">Private car</option>
                <option value="mixed">Mixed</option>
            </select>
            <button className="btn btn-primary" onClick={saveAndContinue}>Save & continue</button>
            <button className="btn btn-ghost" onClick={lambda { nav("/"); }}>Skip — use sample trip</button>
        </div>;
    }
}
