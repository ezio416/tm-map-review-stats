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
        startnew(Http::GetTokenAsync);
    }

    Json::Value@ ToJson() {
        Json::Value json = Json::Object();
        json["token"] = token;
        json["expiry"] = expiry;
        return json;
    }
}
