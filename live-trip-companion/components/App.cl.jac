# components/App.cl.jac
cl import from "@jac/runtime" { Router, Routes, Route, Navigate }

cl import from components.Layout { Layout }
cl import from views.Home { HomePage }
cl import from views.Welcome { WelcomePage }
cl import from views.Plan { PlanPage }
cl import from views.Trips { TripsPage, TripDetailPage }
cl import from views.Live { LivePage }
cl import from views.Budget { BudgetPage }
cl import from views.TripMate { TripMatePage }
cl import from views.Settings { SettingsPage }
cl import from views.Recovery { RecoveryPage }
cl import from views.Receipt { ReceiptPage }
cl import from views.Weather { WeatherPage }

sv import from ...main {
    bootstrap,
    get_prefs
}

cl import "../assets/global.css";

cl {
    def:pub App() -> JsxElement {
        has ready: bool = False;

        async can with entry {
            try {
                root spawn bootstrap();
                root spawn get_prefs();
            } except Exception {
                pass;
            }
            ready = True;
        }

        if not ready {
            return <div className="page"><p className="muted">Loading Live Trip Companion…</p></div>;
        }

        return <Router>
            <Routes>
                <Route path="/welcome" element={<WelcomePage />} />
                <Route element={<Layout />}>
                    <Route path="/" element={<HomePage />} />
                    <Route path="/plan" element={<PlanPage />} />
                    <Route path="/trips" element={<TripsPage />} />
                    <Route path="/trips/:id" element={<TripDetailPage />} />
                    <Route path="/live" element={<LivePage />} />
                    <Route path="/budget" element={<BudgetPage />} />
                    <Route path="/tripmate" element={<TripMatePage />} />
                    <Route path="/settings" element={<SettingsPage />} />
                    <Route path="/recovery/:id" element={<RecoveryPage />} />
                    <Route path="/receipt/:id" element={<ReceiptPage />} />
                    <Route path="/weather/:id" element={<WeatherPage />} />
                </Route>
                <Route path="*" element={<Navigate to="/" replace />} />
            </Routes>
        </Router>;
    }
}
