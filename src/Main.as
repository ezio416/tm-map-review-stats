// c 2025-07-24
// m 2025-08-10

const string  pluginColor = "\\$EE0";
const string  pluginIcon  = Icons::Star;
Meta::Plugin@ pluginMeta  = Meta::ExecutingPlugin();
const string  pluginTitle = pluginColor + pluginIcon + "\\$G " + pluginMeta.Name;

const bool    hasEditPermission    = Permissions::OpenAdvancedMapEditor();
const bool    hasPlayPermission    = Permissions::PlayLocalMap();
const bool    hasReviewPermission  = Permissions::AccessServerReview();
bool          joiningMapReview     = false;
uint64        joinMapReviewClicked = 0;
Submission@[] submissionsTotd;
Json::Value   submissionsTotdRaw;
Submission@[] submissionsWeekly;
Json::Value   submissionsWeeklyRaw;

void Main() {
    Http::Nadeo::InitAsync();

    if (S_AutoGetMaps) {
        Http::Nadeo::GetMySubmissionsAsync(int(ReviewType::Totd));
        Http::Nadeo::GetMySubmissionsAsync(int(ReviewType::Weekly));
    }
}

void OnSettingsChanged() {
    if (S_MapsPerRow == 0) {
        S_MapsPerRow = 1;
    }
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
