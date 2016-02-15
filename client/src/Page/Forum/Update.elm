module Page.Forum.Update where

import Task exposing (Task, succeed, andThen)
import Signal
import Effects exposing (Effects, Never, none, map)
import Response exposing (..)
import Json.Decode as Json
import Json.Encode as JsEncode

import Model exposing (..)
import Model.Shared exposing (..)
import Page.Forum.Model exposing (..)
import Page.Forum.Decoders exposing (..)
import Page.Forum.Route exposing (..)
import Page.Forum.NewPost.Update as NewPost
import Page.Forum.NewTopic.Update as NewTopic
import ServerApi exposing (getJson, postJson)
import Update.Utils as Utils


addr : Signal.Address Action
addr =
  Utils.pageAddr ForumAction


mount : Route -> (Model, Effects Action)
mount route =
  case route of
    Index ->
      taskRes initial listTopics
    ShowTopic id ->
      taskRes initial (showTopic id)


update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of

    RefreshList ->
      taskRes model listTopics

    ListResult result ->
      let
        topics = Result.withDefault [] result
      in
        res { model | topics = topics } none

    ShowResult result ->
      case result of
        Ok topic ->
          res { model | currentTopic = Just topic } none
        Err _ ->
          -- TODO
          res model none

    ShowNewTopic ->
      let
        newTopic = { title = "", content = "" }
      in
        res { model | newTopic = Just newTopic } none

    HideNewTopic ->
      res { model | newTopic = Nothing } none

    NewTopicAction a ->
      case model.newTopic of
        Just newTopic ->
          NewTopic.update a newTopic
            |> mapModel (\t -> { model | newTopic = Just t })
            |> mapEffects NewTopicAction
        Nothing ->
          res model none

    NewPostAction a ->
      case model.newPost of
        Just newPost ->
          NewPost.update a newPost
            |> mapModel (\p -> { model | newPost = Just p })
            |> mapEffects NewPostAction
        Nothing ->
          res model none

    NoOp ->
      res model none



listTopics : Task Never Action
listTopics =
  getJson (Json.list topicWithUserDecoder) "/api/forum/topics"
    |> Task.map ListResult


showTopic : Id -> Task Never Action
showTopic id =
  getJson topicWithPostsDecoder ("/api/forum/topics/" ++ id)
    |> Task.map ShowResult

