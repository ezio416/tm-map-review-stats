// c 2025-07-25
// m 2025-07-25

namespace Http {
    // const string edevBaseUrl    = "https://e416.dev/api2/tm/map-review";
    const string edevBaseUrl    = "http://10.0.0.178:5000/api2/tm/map-review";
    int64        lastSummaryGet = 0;
    bool         requesting     = false;

    enum ResponseCode {
        OK              = 200,
        BadRequest      = 400,
        Unauthorized    = 401,
        Forbidden       = 403,
        NotFound        = 404,
        Timeout         = 408,
        UpgradeRequired = 426,
        TooManyRequests = 429,
        InternalError   = 500
    }

    void GetSummaryAsync() {
        while (requesting) {
            yield();
        }
        requesting = true;

        trace("getting summary...");

        const uint64 start = Time::Now;
        lastSummaryGet = Time::Stamp;
        Net::HttpRequest@ req = Net::HttpGet(edevBaseUrl);
        while (!req.Finished()) {
            yield();

            if (Time::Now - start > 10000) {
                error("error getting summary: timed out");
                req.Cancel();
                requesting = false;
                return;
            }
        }

        requesting = false;

        const ResponseCode code = ResponseCode(req.ResponseCode());
        switch (code) {
            case ResponseCode::OK:
                break;

            default:
                error(
                    "error getting summary: " + tostring(code)
                    + " | " + req.String().Replace("\n", "\\n")
                );
                return;
        }

        try {
            summary = req.Json();
            trace("got summary: " + Json::Write(summary));
        } catch {
            error(
                "error parsing summary: " + getExceptionInfo()
                + " | " + req.String().Replace("\n", "\\n")
            );
        }
    }

    void GetTokenAsync() {
        if (token.getting) {
            return;
        }
        token.getting = true;

        trace("getting preliminary token...");

        Auth::PluginAuthTask@ tokenTask = Auth::GetToken();
        while (!tokenTask.Finished()) {
            yield();
        }

        if (!tokenTask.IsSuccess()) {
            error("error getting preliminary token: " + tokenTask.Error());
            token.getting = false;
            return;
        }

        trace("got preliminary token, getting main token...");

        while (requesting) {
            yield();
        }
        requesting = true;

        const uint64 start = Time::Now;
        Net::HttpRequest@ req = Net::HttpPost(
            edevBaseUrl + "/auth?token=" + tokenTask.Token(),
            contentType: "application/json"
        );
        while (!req.Finished()) {
            yield();

            if (Time::Now - start > 10000) {
                error("error getting main token: timed out");
                req.Cancel();
                requesting = false;
                token.getting = false;
                return;
            }
        }

        requesting = false;

        const ResponseCode code = ResponseCode(req.ResponseCode());
        switch (code) {
            case ResponseCode::OK:
                break;

            default:
                error(
                    "error getting main token: " + tostring(code)
                    + " | " + req.String().Replace("\n", "\\n")
                );
                token.getting = false;
                return;
        }

        try {
            Json::Value@ json = req.Json();
            token.token = string(json["token"]);
            token.expiry = int64(json["expiry"]);

            if (token.valid) {
                trace("got main token");
            } else {
                error("error getting main token: unknown");
                token.Clear();
            }

        } catch {
            warn("error parsing main token: " + getExceptionInfo());
            token.Clear();
        }

        token.getting = false;
    }

    void SendMapInfoAsync(const uint authorTime, const string&in mapName, const string&in mapUid, const ReviewType type) {
        while (requesting) {
            yield();
        }
        requesting = true;

        Json::Value body = Json::Object();
        body["authorTime"] = authorTime;
        body["mapName"] = Text::StripFormatCodes(mapName).Trim();
        body["mapUid"] = mapUid;
        body["reviewType"] = tostring(type);

        trace("sending map info: " + Json::Write(body) + " ...");

        body["token"] = token.token;

        const uint64 start = Time::Now;
        Net::HttpRequest@ req = Net::HttpPost(edevBaseUrl, Json::Write(body), "application/json");
        while (!req.Finished()) {
            yield();

            if (Time::Now - start > 10000) {
                error("error sending map info: timed out");
                req.Cancel();
                requesting = false;
                return;
            }
        }

        requesting = false;

        const ResponseCode code = ResponseCode(req.ResponseCode());
        switch (code) {
            case ResponseCode::OK:
                trace("sent map info");
                break;

            default:
                error(
                    "error sending map info: " + tostring(code)
                    + " | " + req.String().Replace("\n", "\\n")
                );
                return;
        }
    }

    namespace Nadeo {
        const string audienceLive = "NadeoLiveServices";
        uint64       lastRequest  = 0;
        bool         requesting   = false;
        const uint64 waitTime     = 1000;

        void GetMySubmissionsAsync(int64 type) {
            const int length = 144;
            const ReviewType Type = ReviewType(type);

            const string baseUrl = NadeoServices::BaseURLLive() + "/api/token/map-review/{type}/submitted-map"
                "?offset={offset}"
                "&length=" + length +
                "&withFeedback=true"
                "&withMapInfo=true"
            ;
            string url;

            switch (Type) {
                case ReviewType::Totd:
                    url = baseUrl.Replace("{type}", "totd");
                    break;
                case ReviewType::Weekly:
                    url = baseUrl.Replace("{type}", "weekly-shorts");
                    break;
                default:
                    return;
            }

            trace("getting my submissions for " + tostring(Type) + "...");

            WaitAsync();
            Net::HttpRequest@ req = NadeoServices::Get(
                audienceLive,
                url.Replace("{offset}", "0")
            );
            req.Start();
            while (!req.Finished()) {
                yield();
            }

            Json::Value ret;

            try {
                ret = req.Json();
            } catch {
                error(
                    "error parsing my submissions for " + tostring(Type) + ": " + getExceptionInfo()
                    + " | " + req.String().Replace("\n", "\\n")
                );
                requesting = false;
                return;
            }

            if (true
                and ret["itemCount"].GetType() == Json::Type::Number
                and int(ret["itemCount"]) == length
            ) {
                Json::Value json;
                int count = length;
                int offset = 0;

                while (true) {
                    offset += length;
                    trace("getting more submissions for " + tostring(Type) + " with offset " + offset + "...");

                    WaitAsync();
                    @req = NadeoServices::Get(
                        audienceLive,
                        url.Replace("{offset}", tostring(offset))
                    );
                    req.Start();
                    while (!req.Finished()) {
                        yield();
                    }

                    try {
                        json = req.Json();
                        for (uint i = 0; i < json["submittedMaps"].Length; i++) {
                            ret["submittedMaps"].Add(json["submittedMaps"][i]);
                        }
                        count += int(json["itemCount"]);
                        if (int(json["itemCount"]) < length) {
                            break;
                        }
                    } catch {
                        error(
                            "error parsing my submissions for " + tostring(Type) + " with offset " + offset + ": "
                            + getExceptionInfo() + " | " + req.String().Replace("\n", "\\n")
                        );
                        requesting = false;
                        return;
                    }
                }

                ret["itemCount"] = count;
            }

            requesting = false;

            try {
                trace("got " + int(ret["itemCount"]) + " submissions for " + tostring(Type));
            } catch { }

            switch (Type) {
                case ReviewType::Totd:
                    submissionsTotd = {};
                    submissionsTotdRaw = ret;
                    break;
                case ReviewType::Weekly:
                    submissionsWeekly = {};
                    submissionsWeeklyRaw = ret;
                    break;
            }

            if (ret["submittedMaps"].GetType() == Json::Type::Array) {
                for (uint i = 0; i < ret["submittedMaps"].Length; i++) {
                    try {
                        auto map = Submission(ret["submittedMaps"][i]);
                        switch (Type) {
                            case ReviewType::Totd:
                                submissionsTotd.InsertLast(map);
                                break;
                            case ReviewType::Weekly:
                                submissionsWeekly.InsertLast(map);
                                break;
                        }
                    } catch {
                        warn("error parsing map: " + getExceptionInfo() + " | " + Json::Write(ret["submittedMaps"][i]));
                    }
                }
            }
        }

        void InitAsync() {
            NadeoServices::AddAudience(audienceLive);
            while (!NadeoServices::IsAuthenticated(audienceLive)) {
                yield();
            }
        }

        void WaitAsync() {
            uint64 now;
            while ((now = Time::Now) - lastRequest < waitTime) {
                yield();
            }
            lastRequest = now;
            requesting = true;
        }
    }
}
