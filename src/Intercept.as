// c 2025-07-25
// m 2025-07-25

namespace Intercept {
    bool active = false;

    bool FuncDestroy(CMwStack&in stack) {
        auto req = cast<CNetScriptHttpRequest>(stack.CurrentNod());

        if (false
            or req is null
            or !req.Url.Contains("/map-review/")
        ) {
            return true;
        }

        if (req.Url.EndsWith("totd/connect")) {
            lastReviewType = ReviewType::Totd;
            startnew(WaitForServerAsync);
        } else if (req.Url.EndsWith("weekly-shorts/connect")) {
            lastReviewType = ReviewType::Weekly;
            startnew(WaitForServerAsync);
        } else {
            warn("unexpected URL: " + req.Url);
            return true;
        }

        try {
            serverLogin = string(Json::Parse(req.Result)["joinLink"]).Replace("#qjoin=", "");
            trace("new server login from request: " + serverLogin);
        } catch {
            warn("failed to parse server login from result");
            serverLogin = "";
        }

        return true;
    }

    void Start() {
        if (!active) {
            Dev::InterceptProc("CNetScriptHttpManager", "Destroy", FuncDestroy);
            active = true;
        }
    }

    void Stop() {
        if (active) {
            Dev::ResetInterceptProc("CNetScriptHttpManager", "Destroy");
            active = false;
        }
    }
}
