// c 2025-07-24
// m 2025-07-27

[Setting category="General" name="Enabled"]
bool S_Enabled = true;

[Setting category="General" name="Show/hide with game UI"]
bool S_HideWithGame = true;

[Setting category="General" name="Show/hide with Openplanet UI"]
bool S_HideWithOP = false;

[Setting category="General" name="Maps per row" min=1 max=10]
uint S_MapsPerRow = 3;

[Setting category="General" name="Show buttons per map"]
bool S_Buttons = true;

[Setting category="General" name="Show map names in color"]
bool S_ColoredNames = true;

[Setting category="General" name="Show submission timestamps" description="Shown in local time"]
bool S_Timestamps = true;


[SettingsTab name="Debug" icon="Bug"]
void SettingTab_Debug() {
    UI::BeginTabBar("##tabs-debug");

    if (UI::BeginTabItem("Submissions (totd)")) {
        if (UI::BeginChild("##child-debug-totd")) {
            if (true
                and submissionsTotdRaw.GetType() == Json::Type::Object
                and UI::Button(Icons::Clipboard + " Copy")
            ) {
                IO::SetClipboard(Json::Write(submissionsTotdRaw, true));
                print("json copied to clipboard");
            }
            UI::Text(Json::Write(submissionsTotdRaw, true));
        }
        UI::EndChild();
        UI::EndTabItem();
    }

    if (UI::BeginTabItem("Submissions (weekly)")) {
        if (UI::BeginChild("##child-debug-weekly")) {
            if (true
                and submissionsWeeklyRaw.GetType() == Json::Type::Object
                and UI::Button(Icons::Clipboard + " Copy")
            ) {
                IO::SetClipboard(Json::Write(submissionsWeeklyRaw, true));
                print("json copied to clipboard");
            }
            UI::Text(Json::Write(submissionsWeeklyRaw, true));
        }
        UI::EndChild();
        UI::EndTabItem();
    }

    UI::EndTabBar();
}
