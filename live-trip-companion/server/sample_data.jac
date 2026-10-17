"""Sample two-day Galle trip and demo provider data."""

import json;

def sample_galle_trip() -> dict {
    return {
        "id": "sample-galle-2day",
        "title": "Two-Day Galle Getaway (Sample)",
        "destination": "Galle, Sri Lanka",
        "destinations": ["Colombo", "Galle", "Unawatuna"],
        "start_date": "2025-11-15",
        "end_date": "2025-11-16",
        "travelers": 2,
        "budget_lkr": 45000,
        "currency": "LKR",
        "is_sample": True,
        "preferences": {
            "interests": ["beaches", "culture", "food", "photography"],
            "transport": "public_bus_and_train",
            "pace": "balanced",
            "dietary": "none",
            "accessibility": "none"
        },
        "status": "saved",
        "planned_spend_lkr": 38200,
        "history": [],
        "days": [
            {
                "day_index": 0,
                "date": "2025-11-15",
                "label": "Day 1 — Colombo to Galle",
                "activities": [
                    {
                        "id": "act-d1-breakfast",
                        "type": "activity",
                        "name": "Colombo breakfast — Barefoot Garden Cafe",
                        "description": "Light Sri Lankan breakfast before early travel.",
                        "destination": "Colombo 03",
                        "start_time": "03:00",
                        "end_time": "03:45",
                        "duration_min": 45,
                        "transport_to_next": "taxi",
                        "travel_time_min": 25,
                        "travel_cost_lkr": 1200,
                        "activity_cost_lkr": 1800,
                        "indoor": True,
                        "weather_sensitive": False,
                        "alternatives": []
                    },
                    {
                        "id": "bus-colombo-galle-001",
                        "type": "transport",
                        "name": "Express bus — Colombo Fort to Galle",
                        "description": "Highway bus via Southern Expressway (demo schedule).",
                        "destination": "Colombo Fort Bus Stand",
                        "start_time": "04:00",
                        "end_time": "07:00",
                        "duration_min": 180,
                        "transport_to_next": "walk",
                        "travel_time_min": 10,
                        "travel_cost_lkr": 850,
                        "activity_cost_lkr": 0,
                        "indoor": False,
                        "weather_sensitive": False,
                        "alternatives": [
                            {
                                "id": "alt-train-001",
                                "label": "Train Colombo → Galle (demo)",
                                "source": "DEMO_TRANSPORT",
                                "depart_time": "05:45",
                                "arrive_time": "09:30",
                                "cost_lkr": 650,
                                "notes": "Scenic coastal route; slower but reliable demo option."
                            },
                            {
                                "id": "alt-private-van-001",
                                "label": "Private van charter (demo estimate)",
                                "source": "DEMO_TRANSPORT",
                                "depart_time": "05:00",
                                "arrive_time": "07:30",
                                "cost_lkr": 8500,
                                "notes": "Not bookable in demo — estimate only."
                            }
                        ]
                    },
                    {
                        "id": "act-d1-fort-walk",
                        "type": "activity",
                        "name": "Galle Fort walking tour",
                        "description": "Explore Dutch fort walls, lighthouse, and street art.",
                        "destination": "Galle Fort",
                        "start_time": "07:30",
                        "end_time": "10:30",
                        "duration_min": 180,
                        "transport_to_next": "tuk_tuk",
                        "travel_time_min": 15,
                        "travel_cost_lkr": 600,
                        "activity_cost_lkr": 0,
                        "indoor": False,
                        "weather_sensitive": True,
                        "alternatives": [
                            {
                                "id": "alt-indoor-museum",
                                "name": "Maritime Archaeology Museum",
                                "description": "Indoor cultural alternative if rain affects the fort walk.",
                                "duration_min": 90,
                                "cost_lkr": 1200,
                                "indoor": True
                            }
                        ]
                    },
                    {
                        "id": "act-d1-lunch",
                        "type": "activity",
                        "name": "Lunch — Fort Printers dining",
                        "description": "Coastal cuisine inside the fort.",
                        "destination": "Galle Fort",
                        "start_time": "12:00",
                        "end_time": "13:15",
                        "duration_min": 75,
                        "transport_to_next": "none",
                        "travel_time_min": 0,
                        "travel_cost_lkr": 0,
                        "activity_cost_lkr": 4200,
                        "indoor": True,
                        "weather_sensitive": False,
                        "alternatives": []
                    }
                ]
            },
            {
                "day_index": 1,
                "date": "2025-11-16",
                "label": "Day 2 — Beaches & return",
                "activities": [
                    {
                        "id": "act-d2-unawatuna",
                        "type": "activity",
                        "name": "Unawatuna beach swim",
                        "description": "Morning swim and photography at the bay.",
                        "destination": "Unawatuna",
                        "start_time": "08:00",
                        "end_time": "10:00",
                        "duration_min": 120,
                        "transport_to_next": "bus",
                        "travel_time_min": 20,
                        "travel_cost_lkr": 400,
                        "activity_cost_lkr": 0,
                        "indoor": False,
                        "weather_sensitive": True,
                        "alternatives": [
                            {
                                "id": "alt-d2-cooking",
                                "name": "Sri Lankan cooking class (indoor)",
                                "description": "Rain-friendly hands-on class near Galle.",
                                "duration_min": 120,
                                "cost_lkr": 5500,
                                "indoor": True
                            }
                        ]
                    },
                    {
                        "id": "act-d2-return-bus",
                        "type": "transport",
                        "name": "Return bus — Galle to Colombo",
                        "description": "Afternoon express bus (demo).",
                        "destination": "Galle Bus Stand",
                        "start_time": "15:00",
                        "end_time": "18:00",
                        "duration_min": 180,
                        "transport_to_next": "none",
                        "travel_time_min": 0,
                        "travel_cost_lkr": 850,
                        "activity_cost_lkr": 0,
                        "indoor": False,
                        "weather_sensitive": False,
                        "alternatives": []
                    }
                ]
            }
        ]
    };
}

def demo_weather_for_trip(trip: dict) -> list {
    return [
        {
            "source": "DEMO_WEATHER",
            "location": "Galle",
            "summary": "Partly cloudy, afternoon showers possible",
            "rain_probability": 65,
            "severe": False,
            "forecast_time": "2025-11-15T11:00:00+05:30",
            "affects_outdoor": True,
            "label": "Simulated forecast — not live conditions"
        },
        {
            "source": "DEMO_WEATHER",
            "location": "Unawatuna",
            "summary": "Heavy rain band expected late morning",
            "rain_probability": 82,
            "severe": True,
            "forecast_time": "2025-11-16T08:30:00+05:30",
            "affects_outdoor": True,
            "label": "Simulated forecast — not live conditions"
        }
    ];
}

def demo_receipt_extraction() -> dict {
    return {
        "source": "DEMO_OCR",
        "merchant": "Barefoot Garden Cafe",
        "date": "2025-11-15",
        "amount_lkr": 1850,
        "currency": "LKR",
        "category": "Food and drinks",
        "items": ["Kottu roti", "Fresh lime"],
        "confidence": 0.72,
        "label": "Demo extraction — confirm before saving"
    };
}
