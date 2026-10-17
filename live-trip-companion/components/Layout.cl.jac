# components/Layout.cl.jac
cl import from "@jac/runtime" { Link, useLocation, Outlet }

cl {
    def:pub Layout() -> JsxElement {
        loc = useLocation();
        path = loc.pathname if loc else "/";
        return <div className="app-shell">
            <Outlet />
            <BottomNav activePath={path} />
        </div>;
    }

    def:pub BottomNav(activePath: str) -> JsxElement {
        def isActive(p: str) -> bool {
            if p == "/" {
                return activePath == "/";
            }
            return activePath == p or activePath.find(p) == 0;
        }
        def cls(p: str) -> str {
            return "active" if isActive(p) else "";
        }
        return <nav className="bottom-nav">
            <Link className={cls("/")} to="/">Home</Link>
            <Link className={cls("/trips")} to="/trips">My Trips</Link>
            <Link className={cls("/live")} to="/live">Live Trip</Link>
            <Link className={cls("/budget")} to="/budget">Budget</Link>
            <Link className={cls("/tripmate")} to="/tripmate">TripMate</Link>
        </nav>;
    }
}
