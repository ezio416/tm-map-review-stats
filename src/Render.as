// c 2025-07-27
// m 2025-07-27

void RenderSubmissionTab(const string&in name, Submission@[]@ maps, const ReviewType type) {
    if (UI::BeginTabItem(name)) {
        if (UI::BeginChild("##child-" + name)) {
            UI::BeginDisabled(Http::Nadeo::requesting);
            if (UI::Button((maps.Length == 0 ? Icons::Download + " Get" : Icons::Refresh + " Refresh") + " Submissions")) {
                startnew(Http::Nadeo::GetMySubmissionsAsync, int(type));
            }
            UI::EndDisabled();

            UI::SameLine();
            if (UI::Button(Icons::Ubisoft + " Trackmania.com")) {
                OpenBrowserURL("https://trackmania.com/player/tracks/track-reviews/"
                    + (type == ReviewType::Totd ? "totd" : "weekly-shorts"));
            }

            if (hasReviewPermission) {
                UI::SameLine();
                UI::BeginDisabled(joiningMapReview);
                if (UI::Button(Icons::Server + " Join Map Review")) {
                    startnew(JoinMapReviewAsync, int(type));
                }
                UI::EndDisabled();
            }

            const float sameLineWidth = UI::GetScale() * 10.0f;
            const float width = UI::GetContentRegionAvail().x - sameLineWidth * S_MapsPerRow;

            for (uint i = 0; i < maps.Length; i++) {
                if (true
                    and i > 0
                    and i % S_MapsPerRow > 0
                ) {
                    UI::SameLine();
                }

                maps[i].RenderTile(width / S_MapsPerRow);
            }
        }
        UI::EndChild();

        UI::EndTabItem();
    }
}

void RenderWindow() {
    UI::BeginTabBar("##tabs");

    RenderSubmissionTab(Icons::Calendar + " Track of the Day", submissionsTotd, ReviewType::Totd);
    RenderSubmissionTab(Icons::CalendarO + " Weekly Shorts", submissionsWeekly, ReviewType::Weekly);

    UI::EndTabBar();
}
