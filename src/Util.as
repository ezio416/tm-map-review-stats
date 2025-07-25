// c 2025-07-25
// m 2025-07-25

enum ReviewType {
    Totd,
    Weekly,
    None
}

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
        Http::SendMapInfoAsync(
            App.RootMap.TMObjective_AuthorTime,
            App.RootMap.MapInfo.NameForUi,
            App.RootMap.EdChallengeId,
            lastReviewType
        );
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
