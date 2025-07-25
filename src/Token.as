// c 2025-07-25
// m 2025-07-25

class Token {
    int64  expiry  = 0;
    bool   getting = false;
    string token;

    bool get_expired() {
        return Time::Stamp >= expiry;
    }

    bool get_valid() {
        return true
            and token.Length == 36
            and !expired
        ;
    }

    void Clear() {
        token = "";
        expiry = 0;
    }

    void Get() {
        startnew(CoroutineFunc(GetAsync));
    }

    void GetAsync() {
        if (getting) {
            return;
        }
        getting = true;

        trace("getting preliminary token");

        Auth::PluginAuthTask@ tokenTask = Auth::GetToken();
        while (!tokenTask.Finished()) {
            yield();
        }

        if (!tokenTask.IsSuccess()) {
            error("getting preliminary token failed: " + tokenTask.Error());
            getting = false;
            return;
        }

        trace("got preliminary token, getting main token");

        const uint64 start = Time::Now;
        Net::HttpRequest@ req = Net::HttpPost(
            edevBaseUrl + "/auth?token=" + tokenTask.Token(),
            contentType: "application/json"
        );
        while (!req.Finished()) {
            yield();

            if (Time::Now - start > 10000) {
                error("getting main token failed: timed out");
                req.Cancel();
                getting = false;
                return;
            }
        }

        const int code = req.ResponseCode();
        switch (code) {
            case HttpResponse::OK:
                break;

            default:
                error("error getting main token: " + code + ": " + req.String().Replace("\n", "\\n"));
                getting = false;
                return;
        }

        try {
            Json::Value@ json = req.Json();
            token = string(json["token"]);
            expiry = int64(json["expiry"]);

            if (valid) {
                trace("got main token");
            } else {
                error("error getting main token: unknown");
                Clear();
            }

        } catch {
            warn("error parsing main token: " + getExceptionInfo());
            Clear();
        }

        getting = false;
    }

    Json::Value@ ToJson() {
        Json::Value json = Json::Object();
        json["token"] = token;
        json["expiry"] = expiry;
        return json;
    }
}
