// c 2025-07-27
// m 2025-07-27

void EditMapAsync(const string&in url) {
    if (!hasEditPermission) {
        warn("can't edit map: player doesn't have permission");
        return;
    }

    if (url.Length == 0) {
        warn("can't edit map: url is blank");
        return;
    }

    trace("editing map from url: " + url);

    ReturnToMainMenu();

    WaitReadyAsync();
    cast<CTrackMania>(GetApp()).ManiaTitleControlScriptAPI.EditMap(url, "", "");
    WaitReadyAsync();
}

void JoinMapReviewAsync(int64 type) {
    if (!hasReviewPermission) {
        return;
    }

    joiningMapReview = true;

    const string joinLink = Http::Nadeo::GetReviewJoinLinkAsync(ReviewType(type));
    if (joinLink.Length > 0) {
        ReturnToMainMenu();

        cast<CTrackMania>(GetApp()).ManiaPlanetScriptAPI.OpenLink(
            joinLink,
            CGameManiaPlanetScriptAPI::ELinkType::ManialinkBrowser
        );
    }

    joiningMapReview = false;
}

void PlayMapAsync(const string&in url) {
    if (!hasPlayPermission) {
        warn("can't play map: player doesn't have permission");
        return;
    }

    if (url.Length == 0) {
        warn("can't play map: url is blank");
        return;
    }

    trace("playing map from url: " + url);

    ReturnToMainMenu();

    WaitReadyAsync();
    cast<CTrackMania>(GetApp()).ManiaTitleControlScriptAPI.PlayMap(url, "TrackMania/TM_PlayMap_Local", "");
    WaitReadyAsync();
}

void ReturnToMainMenu() {
    auto App = cast<CTrackMania>(GetApp());

    if (App.Network.PlaygroundClientScriptAPI.IsInGameMenuDisplayed) {
        App.Network.PlaygroundInterfaceScriptHandler.CloseInGameMenu(
            CGameScriptHandlerPlaygroundInterface::EInGameMenuResult::Quit
        );
    }

    App.BackToMainMenu();
}

void WaitReadyAsync() {
    auto App = cast<CTrackMania>(GetApp());
    while (!App.ManiaTitleControlScriptAPI.IsReady) {
        yield();
    }
}
