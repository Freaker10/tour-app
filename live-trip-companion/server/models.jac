"""Graph nodes for Live Trip Companion."""

node UserPrefs {
    has user_id: str = "demo-user";
    has onboarded: bool = False;
    has prefs_json: str = "{}";
}

node Trip {
    has trip_id: str;
    has owner_id: str = "demo-user";
    has payload_json: str;
    has updated_at: str = "";
}

node LiveSession {
    has session_id: str;
    has trip_id: str;
    has owner_id: str = "demo-user";
    has state_json: str;
    has active: bool = False;
}

node Expense {
    has expense_id: str;
    has trip_id: str;
    has owner_id: str = "demo-user";
    has payload_json: str;
}

node WeatherReport {
    has report_id: str;
    has area: str;
    has category: str;
    has created_at: str;
    has verification: str = "unverified";
}

node RecoveryRecord {
    has record_id: str;
    has trip_id: str;
    has payload_json: str;
    has created_at: str;
}
