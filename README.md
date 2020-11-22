# FireScript `v1.4.1`

A FiveM resource allowing an admin to create extinguishable fires.

![alt text](https://i.imgur.com/sZQEmP7.png "Example fire #1")

# Instalation

1. Drop the folder `firescript` into your resources folder.
2. Start the script: **a)** in the `server.cfg` file; **b)** through the console

**IMPORTANT NOTE!** For the dispatch to work, you'll have to implement your own dispatch system in a client event `fd:dispatch`.

## Starting a resource through console

1. In a server console, or client console (F8), type in `refresh` and confirm using ENTER
2. Type in `start firescript` and confirm using ENTER

## Starting a resource in `server.cfg`
1. Add this line to your server.cfg
```
start firescript
```
2. Save the file and restart the server.

# Usage

*Tutorial moved to [the wiki](https://github.com/gimicze/firescript/wiki).*

# Known bugs
- when a packet loss occurs, the fire might desynchronize, because the events weren't triggered on your client.

# Credits
- Albo1125 and foregz - I borrowed some particles from their fire scripts. Thanks!

# Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

# License
[GNU GPL 3.0](https://github.com/gimicze/firescript/blob/main/LICENSE)
