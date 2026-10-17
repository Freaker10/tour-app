# views/Settings.cl.jac
cl import from "@jac/runtime" { Link }

cl {
    def:pub SettingsPage() -> JsxElement {
        has locationOn: bool = False;
        has notifications: bool = True;

        return <div className="page">
            <h2>Settings</h2>
            <div className="card">
                <h3>Live Trip & location</h3>
                <p className="muted">
                    Location is used only during an active Live Trip session you start explicitly.
                    You can always use manual check-ins instead.
                </p>
                <label>
                    <input type="checkbox" checked={locationOn} onChange={lambda e: any { locationOn = e.target.checked; }} />
                    Enable GPS during Live Trip (requires browser permission)
                </label>
                {!locationOn and <p className="muted">GPS off — manual check-ins enabled.</p>}
            </div>
            <div className="card">
                <h3>Notifications</h3>
                <label>
                    <input type="checkbox" checked={notifications} onChange={lambda e: any { notifications = e.target.checked; }} />
                    Disruption & weather alerts
                </label>
            </div>
            <div className="card">
                <h3>Privacy</h3>
                <p className="muted">Trips and expenses are private to this demo user. Community weather reports never store exact location or identity.</p>
            </div>
            <Link to="/welcome" className="btn btn-secondary" style={{"display": "flex"}}>Edit travel preferences</Link>
            <Link to="/" className="muted">← Home</Link>
        </div>;
    }
}
