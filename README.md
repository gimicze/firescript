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

*Tutorial moved to [the wiki](https://github.com/gimicze/firescript/wiki).*

## Known bugs
- when a packet loss occurs, the fire might desynchronize, because the events weren't triggered on your client.

## Credits
- Albo1125 and foregz - I borrowed some particles from their fire scripts. Thanks!

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License
[GNU GPL 3.0](https://github.com/gimicze/firescript/blob/main/LICENSE)
