port module TemperatureTracking exposing (..)

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

-- TimeStamp is a string with the time (h:m:s) a temperature sample was taken
type alias TimeStamp = String

-- Temperature (in ˚F)
type alias Temperature = Float

type alias TemperatureSample = (TimeStamp, Temperature)
type alias TemperatureSamples = List TemperatureSample

-- Phoenix channel identifier usually "topic:subtopic"
type alias PhoenixChannelName = String

type Msg
  =  CreateGraph (TemperatureSamples)
  | JoinChannel (PhoenixChannelName)
  | ReceiveTemperatureData Json.Encode.Value
  | SocketAction (Phoenix.Socket.Msg Msg)
  
type alias ApplicationCommand = Cmd Msg

type alias Model = {
  temperatureData: TemperatureSamples,
  phoenixSocket : Phoenix.Socket.Socket Msg
}

port callCreateGraph : TemperatureSamples -> Cmd msg
port callUpdateGraph : TemperatureSamples -> Cmd msg

createGraph : TemperatureSamples -> Cmd Msg
createGraph samples = Task.perform identity CreateGraph (Task.succeed samples)

main : Program Never
main =
  App.program { init = init
  , view = view
  , update = update
  , subscriptions = subscriptions
  }

init : (Model, ApplicationCommand)
init =
  let
    startingModel = initModel
    initCmd = Cmd.batch [
      createGraph startingModel.temperatureData,
      joinChannel "temperature_data:lobby"
    ]
  in
  (startingModel, initCmd)

initModel : Model
initModel =
  Model [] initPhoenixSocket

initPhoenixSocket : Phoenix.Socket.Socket Msg
initPhoenixSocket =
    Phoenix.Socket.init (Debug.log "Connecting to" "ws://localhost:4000/socket/websocket")
    |> Phoenix.Socket.on "temperature_data" "temperature_data:lobby" ReceiveTemperatureData

update : Msg -> Model -> (Model, ApplicationCommand)
update msg model =
  case msg of
      CreateGraph startingSamples ->
        (model, callCreateGraph model.temperatureData)

      ReceiveTemperatureData raw ->
        case Json.Decode.decodeValue decodeTemperatureSamples raw of
          Ok samples ->
              (model, callUpdateGraph samples)

          Err error ->
              (model, Cmd.none)

      JoinChannel channelName ->
        let
          channel = Phoenix.Channel.init (Debug.log "Joining" channelName) -- "temperature_data:lobby"
          (phoenixSocket, phoenixCommand) = Phoenix.Socket.join channel model.phoenixSocket
        in
          ({ model | phoenixSocket = phoenixSocket }
          , Cmd.map SocketAction phoenixCommand
          )

      SocketAction msg ->
        let
          (phoenixSocket, phoenixCommand) = Phoenix.Socket.update msg model.phoenixSocket
        in (
          { model | phoenixSocket = phoenixSocket }
          , Cmd.map SocketAction phoenixCommand
        )


view : Model -> Html Msg
view model =
  div [id "elm-div"] [
    canvas  [ id "myChart", width 400, height 200 ] []
  ]

subscriptions : Model -> Sub Msg
subscriptions model =
  Phoenix.Socket.listen model.phoenixSocket SocketAction

decodeTemperatureSamples : Json.Decode.Decoder TemperatureSamples
decodeTemperatureSamples =
  Json.Decode.object1 identity
  ("temperatures" := Json.Decode.list decodeSingleTemperatureSample)

decodeSingleTemperatureSample : Json.Decode.Decoder TemperatureSample
decodeSingleTemperatureSample =
    Json.Decode.object2 (,)
      ("time" := Json.Decode.string)
      ("temperature" := Json.Decode.float)

joinChannel channelName =
  Task.perform identity JoinChannel (Task.succeed channelName)
