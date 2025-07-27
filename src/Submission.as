// c 2025-07-25
// m 2025-07-27

enum ReviewType {
    Totd,
    Weekly,
    None
}

class Submission {
    string       author;
    uint         authorTime                = 0;
    float        average                   = 0.0f;
    uint         bronzeTime                = 0;
    uint         countStar1                = 0;
    uint         countStar2                = 0;
    uint         countStar3                = 0;
    uint         countStar4                = 0;
    uint         countStar5                = 0;
    uint         countStarMax              = 0;
    uint         countTotal                = 0;
    int64        creationTimestamp         = 0;
    string       downloadUrl;
    uint         feedbackCount             = 0;
    uint         goldTime;
    string[]     labels;
    int64        latestSubmissionTimestamp = 0;
    string       mapId;
    string[]     mapStyles;
    string       mapUid;
    bool         messagingOpen             = false;
    uint         nadeoNote                 = 0;
    string       name;
    string       nameFormatted;
    string       nameStripped;
    uint         nbLaps                    = 0;
    bool         nominated                 = false;
    uint         silverTime                = 0;
    string       stars                     = pluginColor;
    string       submitter;
    UI::Texture@ thumbnail;
    bool         thumbnailGetting;
    bool         thumbnailLoading;
    string       thumbnailPath;
    string       thumbnailUrl;
    ReviewType   type                      = ReviewType::None;
    int64        updateTimestamp           = 0;
    int64        uploadTimestamp           = 0;
    bool         valid                     = false;

    Submission(Json::Value@ json, const ReviewType type) {
        this.type = type;

        creationTimestamp         = int64(json["creationTimestamp"]);
        feedbackCount             = uint(json["feedbackCount"]);
        latestSubmissionTimestamp = int64(json["latestSubmissionTimestamp"]);
        mapUid                    = string(json["mapUid"]);
        thumbnailPath             = IO::FromStorageFolder(mapUid + ".jpg");
        messagingOpen             = bool(json["messagingOpen"]);
        nadeoNote                 = uint(json["nadeoNote"]);
        nominated                 = bool(json["nominated"]);

        Json::Value map = json["map"];
        author          = map["author"];
        authorTime      = uint(map["authorTime"]);
        bronzeTime      = uint(map["bronzeTime"]);
        downloadUrl     = string(map["downloadUrl"]);
        goldTime        = uint(map["goldTime"]);
        mapId           = string(map["mapId"]);
        name            = string(map["name"]);
        nameFormatted   = Text::OpenplanetFormatCodes(name);
        nameStripped    = Text::StripFormatCodes(name);
        nbLaps          = uint(map["nbLaps"]);
        silverTime      = uint(map["silverTime"]);
        submitter       = string(map["submitter"]);
        thumbnailUrl    = string(map["thumbnailUrl"]);
        updateTimestamp = int64(map["updateTimestamp"]);
        uploadTimestamp = int64(map["uploadTimestamp"]);
        valid           = bool(map["valid"]);

        Json::Value noteInfo = json["noteInfo"];
        average      = float(noteInfo["average"]);
        countStar1   = uint(noteInfo["countStar1"]);
        countStar2   = uint(noteInfo["countStar2"]);
        countStar3   = uint(noteInfo["countStar3"]);
        countStar4   = uint(noteInfo["countStar4"]);
        countStar5   = uint(noteInfo["countStar5"]);
        countStarMax = uint(noteInfo["countStarMax"]);
        countTotal   = uint(noteInfo["countTotal"]);

        if (countTotal == 0) {
            stars += Icons::StarO + Icons::StarO + Icons::StarO + Icons::StarO + Icons::StarO;
        } else {
            stars += Icons::Star;
            if (average < 1.5f) {
                stars += Icons::StarO + Icons::StarO + Icons::StarO + Icons::StarO;
            } else if (average < 2.0f) {
                stars += Icons::StarHalfO + Icons::StarO + Icons::StarO + Icons::StarO;
            } else if (average < 2.5f) {
                stars += Icons::Star + Icons::StarO + Icons::StarO + Icons::StarO;
            } else if (average < 3.0f) {
                stars += Icons::Star + Icons::StarHalfO + Icons::StarO + Icons::StarO;
            } else if (average < 3.5f) {
                stars += Icons::Star + Icons::Star + Icons::StarO + Icons::StarO;
            } else if (average < 4.0f) {
                stars += Icons::Star + Icons::Star + Icons::StarHalfO + Icons::StarO;
            } else if (average < 4.5f) {
                stars += Icons::Star + Icons::Star + Icons::Star + Icons::StarO;
            } else if (average < 5.0f) {
                stars += Icons::Star + Icons::Star + Icons::Star + Icons::StarHalfO;
            } else {
                stars += Icons::Star + Icons::Star + Icons::Star + Icons::Star;
            }
        }

        Json::Value labels = json["labels"];
        for (uint i = 0; i < labels.Length; i++) {
            this.labels.InsertLast(string(labels[i]));
        }

        Json::Value mapStyles = json["mapStyles"];
        for (uint i = 0; i < mapStyles.Length; i++) {
            this.mapStyles.InsertLast(string(mapStyles[i]));
        }
    }

    void Edit() {
        startnew(EditMapAsync, downloadUrl);
    }

    void GetThumbnailAsync() {
        if (thumbnailGetting) {
            return;
        }
        thumbnailGetting = true;

        trace("getting thumbnail for '" + nameStripped + "'");

        Net::HttpRequest@ req = Net::HttpGet(thumbnailUrl);
        while (!req.Finished()) {
            yield();
        }

        if (req.ResponseCode() == 200) {
            req.SaveToFile(thumbnailPath);
        } else {
            error("getting thumbnail failed");
            sleep(60000);
        }

        yield();

        thumbnailGetting = false;
    }

    void LoadThumbnail() {
        if (thumbnailLoading) {
            return;
        }
        thumbnailLoading = true;

        if (IO::FileExists(thumbnailPath)) {
            IO::File file(thumbnailPath, IO::FileMode::Read);
            @thumbnail = UI::LoadTexture(file.Read(file.Size()));
        } else {
            startnew(CoroutineFunc(GetThumbnailAsync));
        }

        thumbnailLoading = false;
    }

    void Play() {
        startnew(PlayMapAsync, downloadUrl);
    }

    void RenderThumbnail(const vec2 size) {
        if (thumbnail is null) {
            UI::Dummy(size);
            LoadThumbnail();
            return;
        }

        UI::Image(thumbnail, size);
    }

    void RenderTile(const float width) {
        UI::BeginGroup();

        const float scale = UI::GetScale();
        const vec2 pre = UI::GetCursorPos();
        const float halfWidth = width * 0.5f;
        const float midPoint = pre.x + halfWidth;

        RenderThumbnail(vec2(width));

        if (S_Buttons) {
            const vec2 post = UI::GetCursorPos();
            UI::SetCursorPos(pre + vec2(scale * 5.0f));

            UI::PushStyleColor(UI::Col::Button, vec4(vec3(), 0.9f));

            if (UI::Button("\\$8FA" + Icons::Ubisoft + "##" + mapUid)) {
                OpenBrowserURL("https://trackmania.com/player/tracks/track-reviews/"
                    + (type == ReviewType::Totd ? "totd" : "weekly-shorts") + "/" + mapUid);
            }
            UI::SetItemTooltip("Trackmania.com");

            UI::SameLine();
            UI::SetCursorPosX(UI::GetCursorPos().x - scale * 5.0f);
            if (UI::Button("\\$48F" + Icons::Heartbeat + "##" + mapUid)) {
                OpenBrowserURL("https://trackmania.io/#/leaderboard/" + mapUid);
            }
            UI::SetItemTooltip("Trackmania.io");

            if (hasPlayPermission) {
                UI::SetCursorPosX(pre.x + scale * 5.0f);
                if (UI::Button("\\$C0C" + Icons::Play + "##" + mapUid)) {
                    Play();
                }
                UI::SetItemTooltip("Play");
            }

            if (hasEditPermission) {
                UI::SameLine();
                UI::SetCursorPosX(UI::GetCursorPos().x - scale * 5.0f);
                if (UI::Button("\\$C80" + Icons::Pencil + "##" + mapUid)) {
                    Edit();
                }
                UI::SetItemTooltip("Edit");
            }

            UI::PopStyleColor();

            UI::SetCursorPos(post);
        }

        string text = S_ColoredNames ? nameFormatted : nameStripped;
        UI::SetCursorPosX(midPoint - Draw::MeasureString(text).x * 0.5f);
        UI::Text(text);

        text = stars + "\\$G " + Text::Format("%.1f", average) + " (" + countTotal + ")";
        UI::SetCursorPosX(midPoint - Draw::MeasureString(text).x * 0.5f);
        UI::Text(text);

        const int max = Math::Max(countStarMax, 1);
        const vec2 barSize = vec2(width, UI::GetScale() * 15.0f);

        RenderSubmissionProgressBar(vec3(0.47f, 0.79f, 0.63f), countStar5, max, barSize);
        RenderSubmissionProgressBar(vec3(0.68f, 0.85f, 0.53f), countStar4, max, barSize);
        RenderSubmissionProgressBar(vec3(1.0f, 0.85f, 0.21f),  countStar3, max, barSize);
        RenderSubmissionProgressBar(vec3(1.0f, 0.7f, 0.21f),   countStar2, max, barSize);
        RenderSubmissionProgressBar(vec3(1.0f, 0.55f, 0.35f),  countStar1, max, barSize);
        UI::PopStyleColor(10);

        if (S_Timestamps) {
            text = "First submission:";
            UI::SetCursorPosX(midPoint - Draw::MeasureString(text, UI::Font::DefaultBold).x * 0.5f);
            UI::PushFont(UI::Font::DefaultBold);
            UI::Text(text);
            UI::PopFont();

            text = Time::FormatString("%F, %T", creationTimestamp);
            UI::SetCursorPosX(midPoint - Draw::MeasureString(text).x * 0.5f);
            UI::Text(text);

            text = "Latest submission:";
            UI::SetCursorPosX(midPoint - Draw::MeasureString(text, UI::Font::DefaultBold).x * 0.5f);
            UI::PushFont(UI::Font::DefaultBold);
            UI::Text(text);
            UI::PopFont();

            text = Time::FormatString("%F, %T", latestSubmissionTimestamp);
            UI::SetCursorPosX(midPoint - Draw::MeasureString(text).x * 0.5f);
            UI::Text(text);
        }

        UI::EndGroup();
    }
}

void RenderSubmissionProgressBar(const vec3 color, const uint count, const uint max, const vec2 barSize) {
    UI::PushStyleColor(UI::Col::PlotHistogram, vec4(color, 1.0f));
    UI::PushStyleColor(UI::Col::Text, vec4(vec3(count == max ? 0.0f : 1.0f), 1.0f));
    UI::ProgressBar(count > 0 ? Math::Max(float(count) / max, 0.005f) : 0.005f, barSize, count > 0 ? tostring(count) : "");
}
