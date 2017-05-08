module App.Pages exposing (withLocation)

import Http
import Navigation
import Json.Decode as Decode

import Data exposing (UploadId(..), RemoteConfig)
import PageLocation as PL
import App.Model exposing (..)
import Pages.Profile.Model as ProfileModel

pageExtracts: List (Model -> Maybe (Model, Cmd Msg))
pageExtracts =
    [
     findNewSharePage
    ,findIndexPage
    ,findUploadsPage
    ,findDownloadPage
    ,findLoginPage
    ,findAccountEditPage
    ,findProfilePage
    ,findAliasListPage
    ,findAliasUploadPage
    ]

withLocation: Model -> (Model, Cmd Msg)
withLocation model =
    let
        default = (model, Cmd.none)
        -- goLoop list =
        --     case list of
        --         [] -> default
        --         f :: tail ->
        --             case (f model) of
        --                 Just t -> t
        --                 Nothing -> goLoop tail
        all =  List.map (\f -> f model) pageExtracts
        result = List.foldl (Data.maybeOrElse) Nothing all
    in
        Maybe.withDefault default result



httpGetUpload: RemoteConfig -> UploadId -> Cmd Msg
httpGetUpload cfg id =
    let
        url = case id of
                  Uid uid ->
                      cfg.urls.uploads ++ "/" ++ uid
                  Pid pid ->
                      cfg.urls.uploadPublish ++ "/" ++ pid
    in
        Http.get url Data.decodeUploadInfo
            |> Http.send UploadData

httpGetUploads: RemoteConfig -> Cmd Msg
httpGetUploads cfg =
    Http.get cfg.urls.uploads (Decode.list Data.decodeUpload)
        |> Http.send LoadUploadsResult

httpGetAliases: RemoteConfig -> Cmd Msg
httpGetAliases cfg =
    Http.get cfg.urls.aliases (Decode.list Data.decodeAlias)
        |> Http.send LoadAliasesResult

httpGetAlias: RemoteConfig -> String -> Cmd Msg
httpGetAlias cfg id =
    Http.get (cfg.urls.aliases ++"/"++ id) Data.decodeAlias
        |> Http.send LoadAliasResult

findIndexPage: Model -> Maybe (Model, Cmd Msg)
findIndexPage model =
    if model.location.hash == PL.indexPageHref || model.location.hash == "" then
        {model|page = IndexPage} ! [] |> Just
    else
        Nothing

findLoginPage: Model -> Maybe (Model, Cmd Msg)
findLoginPage model =
    if model.location.hash == PL.loginPageHref then
        let
            m = clearModel model
        in
            {m | page = LoginPage} ! [] |> Just
    else
        Nothing


findUploadsPage: Model -> Maybe (Model, Cmd Msg)
findUploadsPage model =
    if model.location.hash == PL.uploadsPageHref then
        {model | page = UploadListPage} ! [httpGetUploads model.serverConfig] |> Just
    else
        Nothing


findDownloadPage: Model -> Maybe (Model, Cmd Msg)
findDownloadPage model =
    let
        location = model.location
        mCmd = Maybe.map (httpGetUpload model.serverConfig) (PL.downloadPageId location.hash)
        f cmd = model ! [cmd]
    in
        Maybe.map f mCmd


findAccountEditPage: Model -> Maybe (Model, Cmd Msg)
findAccountEditPage model =
    if model.location.hash == PL.accountEditPageHref then
        {model | page = AccountEditPage} ! [] |> Just
    else
        Nothing

findNewSharePage: Model -> Maybe (Model, Cmd Msg)
findNewSharePage model =
    if model.location.hash == PL.newSharePageHref then
        {model | page = NewSharePage} ! [] |> Just
    else
        Nothing

findProfilePage: Model -> Maybe (Model, Cmd Msg)
findProfilePage model =
    if model.location.hash == PL.profilePageHref then
        let
            default = model.user |> Maybe.map (ProfileModel.makeModel model.serverConfig.urls)
            pm = Data.maybeOrElse model.profile default
        in
        {model | page = ProfilePage, profile = pm} ! [] |> Just
    else
        Nothing

findAliasListPage: Model -> Maybe (Model, Cmd Msg)
findAliasListPage model =
    if model.location.hash == PL.aliasListPageHref then
        {model | page = AliasListPage} ! [httpGetAliases model.serverConfig] |> Just
    else
        Nothing

findAliasUploadPage: Model -> Maybe (Model, Cmd Msg)
findAliasUploadPage model =
    case PL.aliasUploadPageId model.location.hash of
        Just id ->
            {model | page = AliasUploadPage} ! [httpGetAlias model.serverConfig id] |> Just
        Nothing ->
            Nothing