port module TemperatureTracking exposing (..)

import Html exposing (..)
import Html.App as App
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http exposing (..)
import Json.Encode exposing(..)
import Json.Decode exposing (..)
import Navigation exposing(..)
import Phoenix.Socket
import Phoenix.Channel
import Task exposing (..)

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
  | ToggleBurner
  | BurnerSuccess Response
  | BurnerFailure RawError

type alias Flags = {
  socket : String
}

type alias ApplicationCommand = Cmd Msg

type alias Model = {
  temperatureData: TemperatureSamples,
  phoenixSocket : Phoenix.Socket.Socket Msg
}

port callCreateGraph : TemperatureSamples -> Cmd msg
port callUpdateGraph : TemperatureSamples -> Cmd msg


{-
  Constructs a Task to call out to JavaScript to create the graph
-}
createGraph : TemperatureSamples -> Cmd Msg
createGraph samples = Task.perform identity CreateGraph (Task.succeed samples)

main : Program Flags
main =
  App.programWithFlags { init = init
  , view = view
  , update = update
  , subscriptions = subscriptions
  }

init : Flags -> (Model, ApplicationCommand)
init(flags) =
  let
    startingModel = initModel flags
    initCmd = Cmd.batch [
      createGraph startingModel.temperatureData,
      joinChannel "temperature_data:lobby"
    ]
  in
  (startingModel, initCmd)

initModel : Flags -> Model
initModel flags =
  Model [] (initPhoenixSocket flags)

initPhoenixSocket : Flags -> Phoenix.Socket.Socket Msg
initPhoenixSocket flags =
    Phoenix.Socket.init (Debug.log "ConnectingTo" flags.socket)
    |> Phoenix.Socket.withDebug
    |> Phoenix.Socket.on "temperature_data" "temperature_data:lobby" ReceiveTemperatureData

update : Msg -> Model -> (Model, ApplicationCommand)
update msg model =
  case msg of
      -- Make a call out to JavaScript to create the graph in the canvas
      CreateGraph startingSamples ->
        (model, callCreateGraph model.temperatureData)

      -- receive a new set of temperature samples from the socket
      ReceiveTemperatureData raw ->
        case Json.Decode.decodeValue decodeTemperatureSamples raw of
          Ok samples ->
              (model, callUpdateGraph samples)

          Err error ->
              (model, Cmd.none)

      -- join the named channel on the socket
      JoinChannel channelName ->
        let
          channel = Phoenix.Channel.init channelName -- e.g. "temperature_data:lobby"
          (phoenixSocket, phoenixCommand) = Phoenix.Socket.join channel model.phoenixSocket
        in
          (
            { model | phoenixSocket = phoenixSocket }
            , Cmd.map SocketAction phoenixCommand
          )

      -- handle socket behaviors by updating the socket
      SocketAction msg ->
        let
          (phoenixSocket, phoenixCommand) = Phoenix.Socket.update msg model.phoenixSocket
        in (
          { model | phoenixSocket = phoenixSocket }
          , Cmd.map SocketAction phoenixCommand
        )

      -- call the HTTP API to toggle the burner on or off
      ToggleBurner ->
        ( model, Task.perform BurnerFailure BurnerSuccess toggleBurner )

      -- API call to toggle burner succeeded
      BurnerSuccess response ->
        (model, Cmd.none)

      -- API call to toggle burner failed
      BurnerFailure err ->
        (model, Cmd.none)

view : Model -> Html Msg
view model =
  div [id "elm-div"] [
    canvas [ id "myChart", width 400, height 200 ] [],
    button [ onClick ToggleBurner ] [ text "Burner" ]
  ]

subscriptions : Model -> Sub Msg
subscriptions model =
  Phoenix.Socket.listen model.phoenixSocket SocketAction

-- construct a task that calls out to the API to toggle the burner on or off
toggleBurner : Task RawError Response
toggleBurner =
  let request =
        { verb = "POST"
        , headers = [ ("Content-Type", "application/json")]
        , url = "/api/burner"
        , body = Http.string """{"burner" : "toggle"}"""
        }
  in
    send defaultSettings request

-- JSON Decoder for a set of temperature samples
decodeTemperatureSamples : Json.Decode.Decoder TemperatureSamples
decodeTemperatureSamples =
  Json.Decode.object1 identity
  ("temperatures" := Json.Decode.list decodeSingleTemperatureSample)

-- JSON Decoder for an individual temperature sample
decodeSingleTemperatureSample : Json.Decode.Decoder TemperatureSample
decodeSingleTemperatureSample =
    Json.Decode.object2 (,)
      ("time" := Json.Decode.string)
      ("temperature" := Json.Decode.float)

-- Construct a task to join the given channel
joinChannel : String -> Cmd Msg
joinChannel channelName =
  Task.perform identity JoinChannel (Task.succeed channelName)

-- The burner ressponse should be the empty string
decodeToggleBurnerResponse : Json.Decode.Decoder (Maybe Int)
decodeToggleBurnerResponse = Json.Decode.succeed Nothing