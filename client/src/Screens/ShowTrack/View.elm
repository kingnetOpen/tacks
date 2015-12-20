module Screens.ShowTrack.View where

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Svg
import Svg.Attributes as SvgAttr

import AppTypes exposing (..)
import Models exposing (..)
import Routes exposing (..)

import Screens.ShowTrack.Types exposing (..)
import Screens.ShowTrack.Updates exposing (addr)

import Screens.Utils exposing (..)
import Screens.Layout as Layout

import Game.Render.Tiles as RenderTiles exposing (lazyRenderTiles, tileKindColor)
import Game.Render.Gates exposing (renderOpenGate)
import Game.Render.Players exposing (renderPlayerHull)
import Game.Render.SvgUtils exposing (..)


view : Context -> Screen -> Html
view ctx {liveTrack, courseControl} =
  Layout.layoutWithNav "show-track" ctx
  [ container ""
    [ Maybe.withDefault (text "") (Maybe.map (withLiveTrack courseControl) liveTrack)
    ]
  ]

withLiveTrack : CourseControl -> LiveTrack -> Html
withLiveTrack control {track, meta, players} =
  div []
  [ h1 [] [ text "Sailing track" ]
  , div [ class "track-header" ]
    [ h2 [ class "track-name" ] [ text track.name ]
    , div [ class "track-creator" ] [ text "by ", strong [] [ text <| playerHandle meta.creator ] ]
    , joinButton track
    ]
  , row
    [ div [ class "col-md-8" ] [ courseBlock control track.course ]
    , div [ class "col-md-4 about" ]
      [ h2 [] [ text "About" ]
      , about track meta
      ]
    ]
  , row
    [ div [ class "col-md-5 rankings" ]
      [ h2 [] [ text "Best times" ]
      , rankingsList meta.rankings
      ]
    ]
  ]

joinButton : Track -> Html
joinButton track =
  linkTo (PlayTrack track.id) [ class "btn btn-warning btn-sm btn-join" ]
  [ text "Join" ]

rankingsList : List Ranking -> Html
rankingsList rankings =
  ul [ class "list-unstyled list-rankings" ] (List.map rankingItem rankings)

about : Track -> TrackMeta -> Html
about {course} meta =
  dl'
  [ ( "Laps", [ text <| toString course.laps ] )
  , ( "Distance", [ text <| toString (course.upwind.y - course.downwind.y), np ] )
  , ( "Wind speed", [ text <| toString course.windSpeed, abbr' "kn" "Knots" ] )
  , ( "Gusts interval", [ text <| toString course.gustGenerator.interval, abbr' "s" "Seconds" ] )
  , ( "Gusts radius", aboutGustRadius course.gustGenerator )
  , ( "Gusts effect", aboutGustWind course.gustGenerator )
  ]

aboutGustRadius : GustGenerator -> List Html
aboutGustRadius gen =
  [ text (toString gen.radiusBase ++ " +/- " ++ toString gen.radiusVariation)
  , np
  ]

aboutGustWind : GustGenerator -> List Html
aboutGustWind {speedVariation, originVariation} =
  [ text (toString speedVariation.start ++ ".." ++ toString speedVariation.end)
  , abbr' "Δkn" "Knots variation range"
  , br [] []
  , text (toString originVariation.start ++ ".." ++ toString originVariation.end)
  , abbr' "Δ°" "Degrees variation range"
  ]

courseBlock : CourseControl -> Course -> Html
courseBlock control course =
  div
    [ class "course"
    , onMouseOver addr (SetOverCourse True)
    , onMouseOut addr (SetOverCourse False)
    ]
  [ renderCourse control course ]

renderCourse : CourseControl -> Course -> Html
renderCourse {center, scale} course =
  let
    zoom = 0.5
    w = colWidth 8
    h = 300
    cx = (w / 2 / zoom + fst center)
    cy = (-h / 2 / zoom + snd center)
    scaleTr = "scale(" ++ toString scale ++ ",-" ++ toString scale ++ ")"
  in
    Svg.svg
      [ SvgAttr.width (toString w)
      , SvgAttr.height (toString h)
      ]
      [ Svg.g [ SvgAttr.transform (scaleTr ++ (translate cx cy)) ]
        [ (lazyRenderTiles course.grid)
        , renderOpenGate course.upwind 0
        , renderOpenGate course.downwind 0
        , renderPlayerHull 0 0
        ]
      ]

np : Html
np =
  abbr' "np" "Nautic pixels"

