// c 2025-07-24
// m 2025-07-25

const string  pluginColor = "\\$EE0";
const string  pluginIcon  = Icons::Star;
Meta::Plugin@ pluginMeta  = Meta::ExecutingPlugin();
const string  pluginTitle = pluginColor + pluginIcon + "\\$G " + pluginMeta.Name;

ReviewType  lastReviewType   = ReviewType::None;
string      serverLogin;
Json::Value submissionsTotd;
Json::Value submissionsWeekly;
Json::Value summary;
Token       token;
bool        waitingForServer = false;

void Main() {
    OnEnabled();

    yield(2);  // not exactly sure why I need to yield for 2 frames
    while (token.getting) {
        yield();
    }

    if (!token.valid) {
        const string msg = "failed to get token, plugin is now inactive";
        error(msg);
        UI::ShowNotification(pluginTitle, msg, vec4(0.8f, 0.2f, 0.0f, 0.8f));
        return;
    }

    Http::Nadeo::InitAsync();

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
    UI::BeginTabBar("##tabs");

    if (UI::BeginTabItem(Icons::ListOl + " Summary")) {
        UI::BeginDisabled(false
            or Http::requesting
            or Time::Stamp - Http::lastSummaryGet < 60
        );
        if (UI::Button((summary.GetType() == Json::Type::Unknown ? Icons::Download + " Get" : Icons::Refresh + " Refresh") + " Summary")) {
            startnew(Http::GetSummaryAsync);
        }
        UI::EndDisabled();

        if (summary.GetType() == Json::Type::Object) {
            UI::Text(Json::Write(summary, true));
        }

        UI::EndTabItem();
    }

    if (UI::BeginTabItem(Icons::UserO + " My Submissions")) {
        UI::BeginTabBar("##tabs-mine");

        if (UI::BeginTabItem(Icons::Calendar + " Track of the Day")) {
            if (UI::Button((submissionsTotd.GetType() == Json::Type::Unknown ? Icons::Download + " Get" : Icons::Refresh + " Refresh") + " Submissions")) {
                startnew(Http::Nadeo::GetMySubmissionsAsync, int(ReviewType::Totd));
            }

            if (submissionsTotd.GetType() == Json::Type::Object) {
                UI::Text(Json::Write(submissionsTotd, true));
            }

            UI::EndTabItem();
        }

        if (UI::BeginTabItem(Icons::CalendarO + " Weekly Shorts")) {
            if (UI::Button((submissionsWeekly.GetType() == Json::Type::Unknown ? Icons::Download + " Get" : Icons::Refresh + " Refresh") + " Submissions")) {
                startnew(Http::Nadeo::GetMySubmissionsAsync, int(ReviewType::Weekly));
            }

            if (submissionsWeekly.GetType() == Json::Type::Object) {
                UI::Text(Json::Write(submissionsWeekly, true));
            }

            UI::EndTabItem();
        }

        UI::EndTabBar();
        UI::EndTabItem();
    }

    if (true
        and S_Debug
        and UI::BeginTabItem(Icons::Bug + " Debug")
    ) {
        UI::Text("last review type: " + tostring(lastReviewType));
        UI::Text("server login: "     + serverLogin);
        UI::Text("token valid: "      + token.valid);
        UI::Text("waiting: "          + waitingForServer);

        UI::Text("in review: "        + InMapReview());
        UI::Text("in totd review: "   + InMapReviewTotd());
        UI::Text("in weekly review: " + InMapReviewWeekly());

        UI::Text("summary: " + Json::Write(summary, true));

        UI::EndTabItem();
    }

    UI::EndTabBar();
}
