import 'dart:io';
import 'dart:async';

String dbFileName = "mock_data.txt";
File dbFile = File(dbFileName);

/// Saves coordinate and updates all clients
addCoordinate(data) async {
  // Saves new coordinate to file
  await dbFile.writeAsString(data + ";", mode: FileMode.append);
  // Send to every client which has a connection to backend
  sockets.forEach((socket) {
    socket.add(data.toString());
  });
}

/// Sends all coordinates to client (socket)
sendAllCoordinates(WebSocket socket) async {
  String fileContent = await dbFile.readAsString();
  List<String> ret = fileContent.split(";");
  ret.removeAt(ret.length - 1);
  // Send every data point as sperate data package
  ret.forEach((singleLatLon) {
    socket.add(singleLatLon);
  });
}

onClose(WebSocket socket) {
  sockets.remove(socket);
}

/// List of all cliens connected
List<WebSocket> sockets = List<WebSocket>();

main() {
  print("Web socket started");
  runZoned(() async {
    HttpServer server = await HttpServer.bind("127.0.0.1", 4040);
    // For loop is called for every connection made from a client
    await for (var request in server) {
      // Upgrades connection to web socket
      WebSocket socket = await WebSocketTransformer.upgrade(request);
      socket.listen(addCoordinate).onDone(() {
        onClose(socket);
      });
      // Add new socket to socket list to be able to call it if new data is comming
      sockets.add(socket);
      // Send all informations from the db so web socket
      sendAllCoordinates(sockets.last);
    }
  }, onError: (e) => print("Error occurred." + e.toString()));
}