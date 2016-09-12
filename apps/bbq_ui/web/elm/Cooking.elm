port module Cooking exposing (..)

import Html exposing (..)
import Html.App as App
import Html.Attributes exposing (..)
import Task exposing (..)

type Msg
  =  DrawGraph

type alias Model =
  List (String, Int)

port updateGraph : Model ->  Cmd msg

graphData = [ ("Jan", 10)
  , ("Feb", 20)
  , ("Mar", 4)
  , ("Apr", 4)
  , ("May", 5)
  , ("Jun", 2)
  , ("Jul", 22)
  , ("Aug", 17)
  ]

main =
  App.program { init = init
  , view = view
  , update = update
  , subscriptions = subscriptions
  }

init :  (Model, Cmd Msg)
init =
  (graphData, (simpleCmd DrawGraph))

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
      DrawGraph  ->
        (model, updateGraph model)

view : Model -> Html Msg
view model =
  div [id "elm-div"] [
    canvas  [ id "myChart", width 400, height 200 ] []
  ]

subscriptions : Model -> Sub Msg
subscriptions model = Sub.none

simpleCmd : Msg -> Cmd Msg
simpleCmd msg =
  Task.perform (\x -> msg) (\a -> msg) (succeed msg)
