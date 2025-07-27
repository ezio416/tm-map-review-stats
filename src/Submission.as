// c 2025-07-25
// m 2025-07-25

enum ReviewType {
    Totd,
    Weekly,
    None
}

class Submission {
    string   author;
    uint     authorTime                = 0;
    float    average                   = 0.0f;
    uint     bronzeTime                = 0;
    uint     countStar1                = 0;
    uint     countStar2                = 0;
    uint     countStar3                = 0;
    uint     countStar4                = 0;
    uint     countStar5                = 0;
    uint     countStarMax              = 0;
    uint     countTotal                = 0;
    int64    creationTimestamp         = 0;
    string   downloadUrl;
    uint     feedbackCount             = 0;
    uint     goldTime;
    string[] labels;
    int64    latestSubmissionTimestamp = 0;
    string   mapId;
    string[] mapStyles;
    string   mapUid;
    bool     messagingOpen             = false;
    uint     nadeoNote                 = 0;
    string   name;
    string   nameFormatted;
    string   nameStripped;
    uint     nbLaps                    = 0;
    bool     nominated                 = false;
    uint     silverTime                = 0;
    string   submitter;
    string   thumbnailUrl;
    int64    updateTimestamp           = 0;
    int64    uploadTimestamp           = 0;
    bool     valid                     = false;

    Submission(Json::Value@ json) {
        creationTimestamp         = int64(json["creationTimestamp"]);
        feedbackCount             = uint(json["feedbackCount"]);
        latestSubmissionTimestamp = int64(json["latestSubmissionTimestamp"]);
        mapUid                    = string(json["mapUid"]);
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

        Json::Value labels = json["labels"];
        for (uint i = 0; i < labels.Length; i++) {
            this.labels.InsertLast(string(labels[i]));
        }

        Json::Value mapStyles = json["mapStyles"];
        for (uint i = 0; i < mapStyles.Length; i++) {
            this.mapStyles.InsertLast(string(mapStyles[i]));
        }
    }
}
