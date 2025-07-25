// c 2025-07-24
// m 2025-07-25

const string  pluginColor = "\\$F0A";
const string  pluginIcon  = Icons::Code;
Meta::Plugin@ pluginMeta  = Meta::ExecutingPlugin();
const string  pluginTitle = pluginColor + pluginIcon + "\\$G " + pluginMeta.Name;

// const string edevBaseUrl      = "https://e416.dev/api2/tm/map-review";
const string edevBaseUrl      = "http://10.0.0.178:5000/api2/tm/map-review";
ReviewType   lastReviewType   = ReviewType::None;
string       serverLogin;
Token        token;
bool         waitingForServer = false;

enum HttpResponse {
    OK              = 200,
    BadRequest      = 400,
    Unauthorized    = 401,
    Forbidden       = 403,
    NotFound        = 404,
    Timeout         = 408,
    UpgradeRequired = 426,
    InternalError   = 500
}

enum ReviewType {
    Totd,
    Weekly,
    None
}

void Main() {
    OnEnabled();

    yield(2);  // not exactly sure why I need to yield for 2 frames
    while (token.getting) {
        yield();
    }

    if (!token.valid) {
        error("failed to get token, plugin is now inactive");
        return;
    }

    bool inReview, wasInReview = false;

    while (true) {
        sleep(1000);

        if (!S_Enabled) {
            inReview = false;
            continue;
        }

        inReview = InMapReview();
        if (wasInReview != inReview) {
            wasInReview = inReview;

            if (inReview) {
                trace("joined map review (" + tostring(lastReviewType) + ")");
                startnew(OnJoinReviewAsync);
            } else {
                trace("left map review (" + tostring(lastReviewType) + ")");
            }
        }
    }
}

void OnDestroyed() {
    lastReviewType = ReviewType::None;
    serverLogin = "";
    token.Clear();
    waitingForServer = false;
    Intercept::Stop();
}

void OnDisabled() {
    OnDestroyed();
}

void OnEnabled() {
    token.Get();
    Intercept::Start();
}

void Render() {
    if (false
        or !S_Enabled
        or (true
            and S_HideWithGame
            and !UI::IsGameUIVisible()
        )
        or (true
            and S_HideWithOP
            and !UI::IsOverlayShown()
        )
    ) {
        return;
    }

    if (UI::Begin(pluginTitle + "###main-" + pluginMeta.ID, S_Enabled, UI::WindowFlags::None)) {
        RenderWindow();
    }
    UI::End();
}

void RenderMenu() {
    if (UI::MenuItem(pluginTitle, "", S_Enabled)) {
        S_Enabled = !S_Enabled;
    }
}

void RenderWindow() {
    UI::Text("last review type: " + tostring(lastReviewType));
    UI::Text("server login: "     + serverLogin);
    UI::Text("token valid: "      + token.valid);
    UI::Text("waiting: "          + waitingForServer);

    UI::Text("in review: "        + InMapReview());
    UI::Text("in totd review: "   + InMapReviewTotd());
    UI::Text("in weekly review: " + InMapReviewWeekly());
}

// Json::Value@ GetAsync() {
//     Net::HttpRequest@ req = Net::HttpGet(edevBaseUrl);
//     while (!req.Finished()) {
//         yield();
//     }

//     try {
//         return req.Json();
//     } catch {
//         warn("error parsing GET: " + getExceptionInfo());
//         return Json::Value();
//     }
// }

bool InMapReview() {
    auto App = cast<CTrackMania>(GetApp());
    auto Network = cast<CTrackManiaNetwork>(App.Network);
    auto ServerInfo = cast<CTrackManiaNetworkServerInfo>(Network.ServerInfo);

    const bool ret = true
        and cast<CSmArenaClient>(App.CurrentPlayground) !is null
        and App.PlaygroundScript is null
        and App.RootMap !is null
        and ServerInfo.CurGameModeStr == "TM_TimeAttack_Online"
        and ServerInfo.ServerName == "Map Test"  // could be spoofed
    ;

    if (true
        and ret
        and waitingForServer
        and ServerInfo.ServerLogin == serverLogin
    ) {
        waitingForServer = false;
    }

    return ret;
}

bool InMapReviewTotd() {
    return true
        and InMapReview()
        and lastReviewType == ReviewType::Totd
    ;
}

bool InMapReviewWeekly() {
    return true
        and InMapReview()
        and lastReviewType == ReviewType::Weekly
    ;
}

void OnJoinReviewAsync() {
    auto App = cast<CTrackMania>(GetApp());

    if (true
        and App.RootMap !is null
        and App.RootMap.MapInfo !is null
    ) {
        SendMapInfoAsync(
            App.RootMap.TMObjective_AuthorTime,
            App.RootMap.MapInfo.NameForUi,
            App.RootMap.EdChallengeId,
            lastReviewType
        );
    }
}

void SendMapInfoAsync(const uint authorTime, const string&in mapName, const string&in mapUid, const ReviewType type) {
    Json::Value body = Json::Object();
    body["authorTime"] = authorTime;
    body["mapName"] = Text::StripFormatCodes(mapName).Trim();
    body["mapUid"] = mapUid;
    body["reviewType"] = tostring(type);

    trace("sending map info: " + Json::Write(body));

    body["token"] = token.token;

    Net::HttpRequest@ req = Net::HttpPost(edevBaseUrl, Json::Write(body), "application/json");
    while (!req.Finished()) {
        yield();
    }

    const int code = req.ResponseCode();
    switch (code) {
        case HttpResponse::OK:
            trace("sent map info");
            break;

        default:
            warn("error sending map info: " + code + ": " + req.String().Replace("\n", "\\n"));
            return;
    }
}

void WaitForServerAsync() {
    if (waitingForServer) {
        return;
    }
    waitingForServer = true;

    const uint64 maxWait   = 15000;
    const uint64 sleepTime = 4800;
    const uint64 start     = Time::Now;

    while (true) {
        trace("waiting for server...");

        InMapReview();

        if (!waitingForServer) {
            break;
        }

        if (Time::Now - start > maxWait) {
            warn("didn't join server after " + maxWait + "ms");
            lastReviewType = ReviewType::None;
            waitingForServer = false;
            break;
        }

        sleep(sleepTime);
    }
}
