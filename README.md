# SplitStreamr

SplitStreamr is an iOS music streaming application that allows users to the split the data cost of the streaming the media amongst iOS devices on a mesh network. 

## How it works

One device acts as the music Player device and establishes a connection to the server via a web socket while browsing for Node devices. Any number of other devices act as Node devices, joining the mesh network set up by the Player upon invitation. 
As Nodes join the mesh, they also make a connection to the same web socket as the Player. Then, when the Player requests a song to play, the Node.js server begins to distribute chunks of that song file to all devices attached to the web socket, starting with the Player. 

As the Player recieves data chunks it queues them to play. As Nodes receive data chunks they establish data streams with the Player device and stream the data across the mesh network.

Data chunks are queued by an associated chunk number sent along with the data, and are played back by the music player.

Details on the server can be found [here](https://github.com/jamesrisberg/SplitStreamrBackend).
