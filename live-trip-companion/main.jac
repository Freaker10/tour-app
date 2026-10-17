"""Live Trip Companion — full-stack entry."""

include server/models;
include server/sample_data;
include server/logic;
include server/walkers;

import from components.App { App as ClientApp }

def:pub app -> JsxElement {
    return <ClientApp />;
}
