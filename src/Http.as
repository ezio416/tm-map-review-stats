// c 2025-07-25
// m 2025-08-10

namespace Http {
    namespace Nadeo {
        const string audienceLive = "NadeoLiveServices";
        uint64       lastRequest  = 0;
        bool         requesting   = false;
        const uint64 waitTime     = 1000;

        string GetReviewJoinLinkAsync(const ReviewType type) {
            string url = NadeoServices::BaseURLLive() + "/api/token/map-review";

            switch (type) {
                case ReviewType::Totd:
                    url += "/totd/connect";
                    break;

                case ReviewType::Weekly:
                    url += "/weekly-shorts/connect";
                    break;

                default:
                    warn("invalid review type: " + tostring(type));
                    return "";
            }

            WaitAsync();
            Net::HttpRequest@ req = NadeoServices::Get(audienceLive, url);
            req.Start();
            while (!req.Finished()) {
                yield();
            }

            const int code = req.ResponseCode();
            if (code != 200) {
                warn("failed to get join link: " + code + " | " + req.String().Replace("\n", "\\n"));
                return "";
            }

            try {
                return string(req.Json()["joinLink"]);
            } catch {
                warn("failed to parse join link: " + getExceptionInfo() + " | " + req.String().Replace("\n", "\\n"));
                return "";
            }
        }

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
                        auto map = Submission(ret["submittedMaps"][i], Type);
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
            const uint64 now = Time::Now;
            if (now - lastRequest < waitTime) {
                sleep(lastRequest + waitTime - now);
            }
            lastRequest = Time::Now;
            requesting = true;
        }
    }
}
