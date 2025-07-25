// c 2025-07-24
// m 2025-07-25

const string  pluginColor = "\\$EE0";
const string  pluginIcon  = Icons::Star;
Meta::Plugin@ pluginMeta  = Meta::ExecutingPlugin();
const string  pluginTitle = pluginColor + pluginIcon + "\\$G " + pluginMeta.Name;

ReviewType    lastReviewType   = ReviewType::None;
string        serverLogin;
Submission@[] submissionsTotd;
Json::Value   submissionsTotdRaw;
Submission@[] submissionsWeekly;
Json::Value   submissionsWeeklyRaw;
Json::Value   summary;
Token         token;
bool          waitingForServer = false;

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
            wasInReview = false;
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
    const float scale = UI::GetScale();

    UI::BeginTabBar("##tabs");

    if (UI::BeginTabItem(Icons::ListOl + " Summary")) {
        UI::BeginDisabled(false
            or Http::requesting
            or Time::Stamp - Http::lastSummaryGet < 60
            or !token.valid
        );
        if (UI::Button((summary.GetType() == Json::Type::Unknown ? Icons::Download + " Get" : Icons::Refresh + " Refresh") + " Summary")) {
            startnew(Http::GetSummaryAsync);
        }
        UI::EndDisabled();

        if (summary.GetType() == Json::Type::Object) {
            if (UI::TreeNode(pluginColor + "Track of the Day")) {
                if (UI::BeginTable("##table-summary-totd", 2, UI::TableFlags::RowBg)) {
                    UI::PushStyleColor(UI::Col::TableRowBgAlt, vec4(vec3(), 0.5f));
                    UI::TableSetupColumn("Timeframe", UI::TableColumnFlags::WidthFixed, scale * 100.0f);
                    UI::TableSetupColumn("Total",     UI::TableColumnFlags::WidthFixed, scale * 50.0f);
                    UI::TableHeadersRow();

                    UI::TableNextRow();
                    UI::TableNextColumn();
                    UI::Text("24 Hours");
                    UI::TableNextColumn();
                    UI::Text(tostring(int(summary["t"]["1d"])));

                    UI::TableNextRow();
                    UI::TableNextColumn();
                    UI::Text("7 Days");
                    UI::TableNextColumn();
                    UI::Text(tostring(int(summary["t"]["7d"])));

                    UI::TableNextRow();
                    UI::TableNextColumn();
                    UI::Text("30 Days");
                    UI::TableNextColumn();
                    UI::Text(tostring(int(summary["t"]["30d"])));

                    UI::PopStyleColor();
                    UI::EndTable();
                }

                UI::TreePop();
            }

            if (UI::TreeNode(pluginColor + "Weekly Shorts")) {
                if (UI::BeginTable("##table-summary-weekly", 6, UI::TableFlags::RowBg)) {
                    UI::PushStyleColor(UI::Col::TableRowBgAlt, vec4(vec3(), 0.5f));
                    UI::TableSetupColumn("Timeframe", UI::TableColumnFlags::WidthFixed, scale * 100.0f);
                    UI::TableSetupColumn("#1",        UI::TableColumnFlags::WidthFixed, scale * 50.0f);
                    UI::TableSetupColumn("#2",        UI::TableColumnFlags::WidthFixed, scale * 50.0f);
                    UI::TableSetupColumn("#3",        UI::TableColumnFlags::WidthFixed, scale * 50.0f);
                    UI::TableSetupColumn("#4",        UI::TableColumnFlags::WidthFixed, scale * 50.0f);
                    UI::TableSetupColumn("#5",        UI::TableColumnFlags::WidthFixed, scale * 50.0f);
                    UI::TableHeadersRow();

                    UI::TableNextRow();
                    UI::TableNextColumn();
                    UI::Text("24 Hours");
                    UI::TableNextColumn();
                    UI::Text(tostring(int(summary["w"]["1d"][0])));
                    UI::TableNextColumn();
                    UI::Text(tostring(int(summary["w"]["1d"][1])));
                    UI::TableNextColumn();
                    UI::Text(tostring(int(summary["w"]["1d"][2])));
                    UI::TableNextColumn();
                    UI::Text(tostring(int(summary["w"]["1d"][3])));
                    UI::TableNextColumn();
                    UI::Text(tostring(int(summary["w"]["1d"][4])));

                    UI::TableNextRow();
                    UI::TableNextColumn();
                    UI::Text("7 Days");
                    UI::TableNextColumn();
                    UI::Text(tostring(int(summary["w"]["7d"][0])));
                    UI::TableNextColumn();
                    UI::Text(tostring(int(summary["w"]["7d"][1])));
                    UI::TableNextColumn();
                    UI::Text(tostring(int(summary["w"]["7d"][2])));
                    UI::TableNextColumn();
                    UI::Text(tostring(int(summary["w"]["7d"][3])));
                    UI::TableNextColumn();
                    UI::Text(tostring(int(summary["w"]["7d"][4])));

                    UI::TableNextRow();
                    UI::TableNextColumn();
                    UI::Text("30 Days");
                    UI::TableNextColumn();
                    UI::Text(tostring(int(summary["w"]["30d"][0])));
                    UI::TableNextColumn();
                    UI::Text(tostring(int(summary["w"]["30d"][1])));
                    UI::TableNextColumn();
                    UI::Text(tostring(int(summary["w"]["30d"][2])));
                    UI::TableNextColumn();
                    UI::Text(tostring(int(summary["w"]["30d"][3])));
                    UI::TableNextColumn();
                    UI::Text(tostring(int(summary["w"]["30d"][4])));

                    UI::PopStyleColor();
                    UI::EndTable();
                }

                UI::TreePop();
            }
        }

        UI::EndTabItem();
    }

    if (UI::BeginTabItem(Icons::UserO + " My Submissions")) {
        UI::BeginTabBar("##tabs-mine");

        if (UI::BeginTabItem(Icons::Calendar + " Track of the Day")) {
            UI::BeginDisabled(Http::Nadeo::requesting);
            if (UI::Button((submissionsTotd.Length == 0 ? Icons::Download + " Get" : Icons::Refresh + " Refresh") + " Submissions")) {
                startnew(Http::Nadeo::GetMySubmissionsAsync, int(ReviewType::Totd));
            }
            UI::EndDisabled();

            for (uint i = 0; i < submissionsTotd.Length; i++) {
                Submission@ map = submissionsTotd[i];
                if (UI::TreeNode(map.nameStripped + "##" + i)) {
                    ;

                    UI::TreePop();
                }
            }

            UI::EndTabItem();
        }

        if (UI::BeginTabItem(Icons::CalendarO + " Weekly Shorts")) {
            UI::BeginDisabled(Http::Nadeo::requesting);
            if (UI::Button((submissionsWeekly.Length == 0 ? Icons::Download + " Get" : Icons::Refresh + " Refresh") + " Submissions")) {
                startnew(Http::Nadeo::GetMySubmissionsAsync, int(ReviewType::Weekly));
            }
            UI::EndDisabled();

            for (uint i = 0; i < submissionsWeekly.Length; i++) {
                Submission@ map = submissionsWeekly[i];
                if (UI::TreeNode(map.nameStripped + "##" + i)) {
                    ;

                    UI::TreePop();
                }
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

        UI::Separator();

        UI::Text("in review: "        + InMapReview());
        UI::Text("in totd review: "   + InMapReviewTotd());
        UI::Text("in weekly review: " + InMapReviewWeekly());

        if (UI::TreeNode("\\$0FFsummary")) {
            UI::Text(Json::Write(summary, true));
            UI::TreePop();
        }

        if (UI::TreeNode("\\$0FFsubmissions (totd)")) {
            UI::Text(Json::Write(submissionsTotdRaw, true));
            UI::TreePop();
        }

        if (UI::TreeNode("\\$0FFsubmissions (weekly)")) {
            UI::Text(Json::Write(submissionsWeeklyRaw, true));
            UI::TreePop();
        }

        UI::EndTabItem();
    }

    UI::EndTabBar();
}
