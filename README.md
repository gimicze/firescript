# FireScript `v1.3`

A FiveM resource allowing an admin to create extinguishable fires. (You can set the admin level and default values in config)

![alt text](https://i.imgur.com/sZQEmP7.png "Example fire #1")

## Installation

Drop the folder `firescript` into your resources folder and start it using the console / add it to the server configuration.

**console**

`refresh` followed by `start firescript`

**server.cfg** 
```
start firescript
```

**IMPORTANT NOTE!** For the dispatch to work, you'll have to implement your own dispatch system in a client event `fd:dispatch`, which passes only one argument: `coords` - vector3(). The event will be triggered only on the sender's client (to be able to get the street name).

## Usage

`/startfire <spread> <chance> <dispatch>` *Starts a fire at the ped's coords*
- spread: 0-∞ (but stay low, for the sake of the server and your machine) - *how many times can the fire spread?*
- chance: 0-100 - *how many chances out of 100 does the fire spread?* (not exactly percentage)
- dispatch: **true** / **false** (default: false) - *should the script trigger dispatch?*

  **Returns:** fireID - *Note that the identifier is required to stop one specific fire.*

`/stopfire <fireID>`
- fireID: `int` - *the fire identifier*

It is also possible to pre-define fires. These I called the registered fires.

`/registerfire <dispatch>` *Registers a new pre-defined fire*
- dispatch: **true** / **false** (default: false) - *should the script trigger dispatch when the fire gets started? (dispatch coords will be set to the coords where this command was triggered)*

  **Returns:** registeredFireID - *Note that the identifier is required to stop one specific whole registered fire.*

`/addflame <spread> <chance>` *Adds a flame to a registered fire*
- spread: 0-∞ (but stay low, for the sake of the server and your machine) - *how many times can the flame spread?*
- chance: 0-100 - *how many chances out of 100 does the flame spread?* (not exactly percentage)

  **Returns:** flameID - *Note that the identifier is required to remove it from the registered fire.*

`/removeflame <registeredFireID> <flameID>` *Removes a flame from a registered fire*
- registeredFireID: `int` - *the registered fire identifier*
- flameID: `int` - *the flame identifier*

`/startregisteredfire <registeredFireID>` *Starts a registered fire*
- registeredFireID: `int` - *the registered fire identifier*

## Known bugs
- when a packet loss occurs, the fire might desynchronize, because the events weren't triggered on your client.

## Credits
- Albo1125 and foregz - I borrowed some particles from their fire scripts. Thanks!

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License
[GNU GPL 3.0](https://github.com/gimicze/firescript/blob/main/LICENSE)
