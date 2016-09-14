port module Cooking exposing (..)

import Html exposing (..)
import Html.App as App
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Json.Encode exposing(..)
import Json.Decode exposing (..)
import Task exposing (..)
import Phoenix.Socket
import Phoenix.Channel
import Phoenix.Push


type alias TimeStamp = String
type alias Temperature = Float

type alias TemperatureSample = (TimeStamp, Temperature)
type alias TemperatureSamples =
  List TemperatureSample

type AppMessage
  =  FinishInitialization
  | UpdateGraph (TemperatureSamples)
  | SocketAction (Phoenix.Socket.Msg AppMessage)
  | JoinChannel
  | ReceiveTemperatureData Json.Encode.Value

type alias Model = {
  temperatureData: TemperatureSamples,
  phoenixSocket : Phoenix.Socket.Socket AppMessage
}

port createGraph : TemperatureSamples -> Cmd msg
port updateGraph : TemperatureSamples -> Cmd msg

graphData = []

main : Program Never
main =
  App.program { init = init
  , view = view
  , update = update
  , subscriptions = subscriptions
  }

init : (Model, Cmd AppMessage)
init =
  (initModel, buildCmd FinishInitialization)

initModel : Model
initModel =
  Model graphData initPhoenixSocket

initPhoenixSocket : Phoenix.Socket.Socket AppMessage
initPhoenixSocket =
    Phoenix.Socket.init (Debug.log "Connecting to" "ws://localhost:4000/socket/websocket")
    |> Phoenix.Socket.withDebug
    |> Phoenix.Socket.on "temperature_data" "temperature_data:lobby" ReceiveTemperatureData

update : AppMessage -> Model -> (Model, Cmd AppMessage)
update msg model =
  case msg of
      FinishInitialization ->
        let
          (channel_model, phoenixCommand) = update JoinChannel model
        in
          (channel_model, Cmd.batch [phoenixCommand, createGraph model.temperatureData])

      UpdateGraph newSamples ->
        (model, Cmd.none)

      ReceiveTemperatureData raw ->
        case Json.Decode.decodeValue decodeTemperatureSamples raw of
          Ok samples ->
              (model, updateGraph samples)

          Err error ->
              (model, Cmd.none)

      SocketAction msg ->
        let
          (phoenixSocket, phoenixCommand) = Phoenix.Socket.update msg model.phoenixSocket
        in (
          { model | phoenixSocket = phoenixSocket }
          , Cmd.map SocketAction phoenixCommand
        )

      JoinChannel ->
        let
          channel = Phoenix.Channel.init (Debug.log "joining" "temperature_data:lobby")
          (phoenixSocket, phoenixCommand) = Phoenix.Socket.join channel model.phoenixSocket
        in
          ({ model | phoenixSocket = phoenixSocket }
          , Cmd.map SocketAction phoenixCommand
          )

view : Model -> Html AppMessage
view model =
  div [id "elm-div"] [
    canvas  [ id "myChart", width 400, height 200 ] []
  ]

subscriptions : Model -> Sub AppMessage
subscriptions model =
  Phoenix.Socket.listen model.phoenixSocket SocketAction

buildCmd : AppMessage -> Cmd AppMessage
buildCmd msg =
  Task.perform identity identity (Task.succeed msg)

decodeTemperatureSamples : Json.Decode.Decoder TemperatureSamples
decodeTemperatureSamples =
  Json.Decode.object1 identity
  ("temperatures" := Json.Decode.list decodeSingleTemperatureSample)

decodeSingleTemperatureSample : Json.Decode.Decoder TemperatureSample
decodeSingleTemperatureSample =
    Json.Decode.object2 (,)
      ("time" := Json.Decode.string)
      ("temperature" := Json.Decode.float)