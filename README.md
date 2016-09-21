# ExBbq

The two applications in the framework are:

	* `bbq_ui` - A Phoneix application that serves a web front end for the controller
	* `temp_monitor` - a Nerves applicaiton that will one day drive the Raspberry Pi 3 hardware interface to the real world. At the moment, it just fakes up a temperature sensor.

The `bbq_ui` is the primary app in the umbrella and it includes `temp_monitor` as a dependency.

To build this application you will have to have Elm and Nerves installed.

	* Elm - https://guide.elm-lang.org/get_started.html
	* Nerves - https://hexdocs.pm/nerves/getting-started.html

Building:

	1. Switch to the bbq_ui app `cd apps/bbq_ui`
	2. Fetch Mix dependencies `mix deps.get`
	3. Fetch Mix dependencies `npm install`
	4. Build the application `mix firmware`

