// c 2025-07-27
// m 2025-07-27

void RenderSubmission(Submission@ map) {
    string stars = pluginColor;
    if (map.countTotal == 0) {
        stars += Icons::StarO + Icons::StarO + Icons::StarO + Icons::StarO + Icons::StarO;
    } else {
        stars += Icons::Star;
        if (map.average < 1.5f) {
            stars += Icons::StarO + Icons::StarO + Icons::StarO + Icons::StarO;
        } else if (map.average < 2.0f) {
            stars += Icons::StarHalfO + Icons::StarO + Icons::StarO + Icons::StarO;
        } else if (map.average < 2.5f) {
            stars += Icons::Star + Icons::StarO + Icons::StarO + Icons::StarO;
        } else if (map.average < 3.0f) {
            stars += Icons::Star + Icons::StarHalfO + Icons::StarO + Icons::StarO;
        } else if (map.average < 3.5f) {
            stars += Icons::Star + Icons::Star + Icons::StarO + Icons::StarO;
        } else if (map.average < 4.0f) {
            stars += Icons::Star + Icons::Star + Icons::StarHalfO + Icons::StarO;
        } else if (map.average < 4.5f) {
            stars += Icons::Star + Icons::Star + Icons::Star + Icons::StarO;
        } else if (map.average < 5.0f) {
            stars += Icons::Star + Icons::Star + Icons::Star + Icons::StarHalfO;
        } else {
            stars += Icons::Star + Icons::Star + Icons::Star + Icons::Star;
        }
    }
    UI::AlignTextToFramePadding();
    UI::Text(stars + "\\$G " + Text::Format("%.1f", map.average) + " (" + map.countTotal + ")");

    UI::SameLine();
    if (UI::Button("\\$48F" + Icons::Heartbeat + "\\$G Trackmania.io##")) {
        OpenBrowserURL("https://trackmania.io/#/leaderboard/" + map.mapUid);
    }

    const int max = Math::Max(map.countStarMax, 1);
    const vec2 barSize = vec2(UI::GetContentRegionAvail().x, UI::GetScale() * 15.0f);

    RenderSubmissionProgressBar(vec3(0.47f, 0.79f, 0.63f), map.countStar5, max, barSize);
    RenderSubmissionProgressBar(vec3(0.68f, 0.85f, 0.53f), map.countStar4, max, barSize);
    RenderSubmissionProgressBar(vec3(1.0f, 0.85f, 0.21f),  map.countStar3, max, barSize);
    RenderSubmissionProgressBar(vec3(1.0f, 0.7f, 0.21f),   map.countStar2, max, barSize);
    RenderSubmissionProgressBar(vec3(1.0f, 0.55f, 0.35f),  map.countStar1, max, barSize);
    UI::PopStyleColor(10);

    UI::Text(Time::FormatString("First submission:  %F  %R", map.creationTimestamp));
    UI::Text(Time::FormatString("Latest submission:  %F  %R", map.latestSubmissionTimestamp));
}

void RenderSubmissionProgressBar(const vec3 color, const uint count, const uint max, const vec2 barSize) {
    UI::PushStyleColor(UI::Col::PlotHistogram, vec4(color, 1.0f));
    UI::PushStyleColor(UI::Col::Text, vec4(vec3(count == max ? 0.0f : 1.0f), 1.0f));
    UI::ProgressBar(count > 0 ? Math::Max(float(count) / max, 0.005f) : 0.005f, barSize, count > 0 ? tostring(count) : "");
}

void RenderWindow() {
    UI::BeginTabBar("##tabs");

    if (UI::BeginTabItem(Icons::UserO + " My Submissions")) {
        UI::BeginTabBar("##tabs-mine");

        if (UI::BeginTabItem(Icons::Calendar + " Track of the Day")) {
            if (UI::BeginChild("##child-sub-totd")) {
                UI::BeginDisabled(Http::Nadeo::requesting);
                if (UI::Button((submissionsTotd.Length == 0 ? Icons::Download + " Get" : Icons::Refresh + " Refresh") + " Submissions")) {
                    startnew(Http::Nadeo::GetMySubmissionsAsync, int(ReviewType::Totd));
                }
                UI::EndDisabled();

                for (uint i = 0; i < submissionsTotd.Length; i++) {
                    Submission@ map = submissionsTotd[i];
                    if (UI::TreeNode(map.nameStripped + "##" + i, UI::TreeNodeFlags::Framed)) {
                        RenderSubmission(map);
                        UI::TreePop();
                    }
                }
            }
            UI::EndChild();

            UI::EndTabItem();
        }

        if (UI::BeginTabItem(Icons::CalendarO + " Weekly Shorts")) {
            if (UI::BeginChild("##child-sub-weekly")) {
                UI::BeginDisabled(Http::Nadeo::requesting);
                if (UI::Button((submissionsWeekly.Length == 0 ? Icons::Download + " Get" : Icons::Refresh + " Refresh") + " Submissions")) {
                    startnew(Http::Nadeo::GetMySubmissionsAsync, int(ReviewType::Weekly));
                }
                UI::EndDisabled();

                for (uint i = 0; i < submissionsWeekly.Length; i++) {
                    Submission@ map = submissionsWeekly[i];
                    if (UI::TreeNode(map.nameStripped + "##" + i, UI::TreeNodeFlags::Framed)) {
                        RenderSubmission(map);
                        UI::TreePop();
                    }
                }
            }
            UI::EndChild();

            UI::EndTabItem();
        }

        UI::EndTabBar();
        UI::EndTabItem();
    }

    if (true
        and S_Debug
        and UI::BeginTabItem(Icons::Bug + " Debug")
    ) {
        if (UI::BeginChild("##child-debug")) {
            if (UI::TreeNode("submissions (totd)", UI::TreeNodeFlags::Framed)) {
                UI::Text(Json::Write(submissionsTotdRaw, true));
                UI::TreePop();
            }

            if (UI::TreeNode("submissions (weekly)", UI::TreeNodeFlags::Framed)) {
                UI::Text(Json::Write(submissionsWeeklyRaw, true));
                UI::TreePop();
            }
        }
        UI::EndChild();

        UI::EndTabItem();
    }

    UI::EndTabBar();
}
