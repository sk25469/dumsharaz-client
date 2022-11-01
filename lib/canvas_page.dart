import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:scribble_demo/model/client_info.dart';
import 'package:scribble_demo/model/client_response.dart';
import 'package:scribble_demo/model/my_offset.dart';
import 'package:scribble_demo/model/server_response.dart';
import 'package:scribble_demo/sketcher.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'model/drawn_line.dart';

class CanvasPage extends StatefulWidget {
  const CanvasPage({super.key});

  @override
  State<CanvasPage> createState() => _CanvasPageState();
}

class _CanvasPageState extends State<CanvasPage> {
  String id = "", joined = "";
  final channel = WebSocketChannel.connect(
    Uri.parse("ws://localhost:5000/ws"),
  );

  late Stream<ServerResponse> readableStream;
  late Stream<List<DrawnLine>> readablePointStream;
  TextEditingController nameTextController = TextEditingController();
  TextEditingController roomIdTextController = TextEditingController();

  final GlobalKey _globalKey = GlobalKey();
  final GlobalKey _globalKey2 = GlobalKey();
  List<DrawnLine> drawnLines = <DrawnLine>[];
  List<DrawnLine> linesFromStream = <DrawnLine>[];
  DrawnLine? line;
  Color selectedColor = Colors.black;
  double selectedWidth = 5.0;

  StreamController<List<DrawnLine>> linesStreamController =
      StreamController<List<DrawnLine>>.broadcast();
  StreamController<DrawnLine> currentLineStreamController =
      StreamController<DrawnLine>.broadcast();

  // response_type can be "connect-new" or "connect"
  String response_type = "", room_type = "", room_id = "";
  ClientInfo? clientInfo;
  List<ClientInfo> group1 = [], group2 = [];
  bool isBuilding = false;

  double excessWidth = 0,
      excessHeight = 0,
      startCanvasWidth = 0,
      endCanvasWidth = 0,
      startCanvasHeight = 0,
      endCanvasHeight = 0,
      canvasWidth = 0,
      canvasHeight = 0,
      groupDetailsWidth = 0;

  // send the name and room details to the server
  void sendNameAndRoomDetails() {
    clientInfo = ClientInfo(
      client_id: id,
      name: nameTextController.text,
      room_id: "",
    );
    channel.sink.add(
      ClientResponse(
        response_type: response_type,
        room_id: roomIdTextController.text,
        client_info: clientInfo!,
        room_type: room_type,
        drawn_points: DrawnLine(
          color: const Color(0x00000000),
          path: [],
          width: 0,
        ),
      ).toJson(),
    );
    setState(() {});
  }

  Future<void> clear() async {
    setState(() {
      drawnLines = [];
      line = null;
    });
  }

  void onPanStart(DragStartDetails details) {
    RenderBox box = context.findRenderObject() as RenderBox;
    Offset point = box.globalToLocal(details.globalPosition);

    line = DrawnLine(
      path: [
        MyOffset(dx: point.dx - excessWidth, dy: point.dy - excessHeight),
      ],
      color: selectedColor,
      width: selectedWidth,
    );
    log(line.toString());
    channel.sink.add(
      ClientResponse(
        response_type: "move",
        room_id: room_id,
        client_info: clientInfo!,
        room_type: room_type,
        drawn_points: line!,
      ).toJson(),
    );
  }

  void onPanUpdate(DragUpdateDetails details) {
    RenderBox box = context.findRenderObject() as RenderBox;
    Offset point = box.globalToLocal(details.globalPosition);

    if (point.dx < startCanvasWidth || point.dx > endCanvasWidth) {
      return;
    }

    if (point.dy < startCanvasHeight || point.dy > endCanvasHeight) {
      return;
    }

    log(details.globalPosition.toString());

    List<MyOffset> path = List.from(line!.path)
      ..add(
        MyOffset(dx: point.dx - excessWidth, dy: point.dy - excessHeight),
      );
    line = DrawnLine(path: path, width: selectedWidth, color: selectedColor);
    currentLineStreamController.add(line!);
    channel.sink.add(
      ClientResponse(
        response_type: "move",
        room_id: room_id,
        client_info: clientInfo!,
        room_type: room_type,
        drawn_points: line!,
      ).toJson(),
    );
  }

  void onPanEnd(DragEndDetails details) {
    drawnLines = List.from(drawnLines)..add(line!);

    linesStreamController.add(drawnLines);
  }

  @override
  void initState() {
    readableStream = channel.stream.map((event) {
      String value = event.toString();
      return ServerResponse.fromJson(value);
    }).asBroadcastStream();
    // readablePointStream = channel.stream.map((event) {
    //   String value = event.toString();
    //   return ServerResponse.fromJson(value).drawn_points;
    // }).asBroadcastStream();
    log("converted dynamic to ServerResponse");
    super.initState();
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  Widget buildCurrentPath(BuildContext context, double width, double height) {
    return GestureDetector(
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      child: RepaintBoundary(
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsets.all(4.0),
          color: Colors.transparent,
          alignment: Alignment.topLeft,
          child: StreamBuilder<DrawnLine>(
            stream: currentLineStreamController.stream,
            builder: (context, snapshot) {
              return CustomPaint(
                painter: Sketcher(
                  lines: line == null ? [] : [line!],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget buildCurrentStreamingPoints(BuildContext context, double width, double height) {
    return RepaintBoundary(
      key: _globalKey2,
      child: Container(
        width: width,
        height: height,
        color: Colors.transparent,
        padding: const EdgeInsets.all(4.0),
        alignment: Alignment.topLeft,
        child: StreamBuilder<ServerResponse>(
          stream: readableStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(snapshot.error.toString());
            }
            if (snapshot.hasData) {
              final response = snapshot.data;
              if (response!.response_type == "move") {
                linesFromStream = response.drawn_points;
                if (response.client_info.client_id == id) {
                  isBuilding = true;
                }
              }
            }
            return CustomPaint(
              painter: Sketcher(
                lines: linesFromStream,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildAllPaths(BuildContext context, double width, double height) {
    return RepaintBoundary(
      key: _globalKey,
      child: Container(
        width: width,
        height: height,
        color: Colors.transparent,
        padding: const EdgeInsets.all(4.0),
        alignment: Alignment.topLeft,
        child: StreamBuilder<List<DrawnLine>>(
          stream: linesStreamController.stream,
          builder: (context, snapshot) {
            return CustomPaint(
              painter: Sketcher(
                lines: drawnLines,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildClearButton() {
    return GestureDetector(
      onTap: clear,
      child: const CircleAvatar(
        child: Icon(
          Icons.create,
          size: 20.0,
          color: Colors.white,
        ),
      ),
    );
  }

  AppBar appBar = AppBar(
    title: const Text('Scribble Demo'),
    backgroundColor: Colors.black,
    elevation: 0,
  );

  double getExcessWidth(double width, double groupDetailsWidth) {
    return groupDetailsWidth;
  }

  double getExcessHeight(double height) {
    return 0.15 * height;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height - appBar.preferredSize.height;
    excessWidth = 0.2 * width;
    excessHeight = 0.15 * height;
    startCanvasWidth = 0.2 * width;
    endCanvasWidth = 0.8 * width;
    startCanvasHeight = 0.1 * height;
    endCanvasHeight = 0.98 * height;

    // print(channel.toString());

    return Scaffold(
      appBar: appBar,
      body: room_type.isEmpty
          ? Center(
              child: SizedBox(
                width: width * 0.5,
                height: height * 0.5,
                child: Column(
                  children: [
                    TextField(
                      controller: nameTextController,
                      decoration: const InputDecoration(hintText: 'Enter your name'),
                    ),
                    SizedBox(
                      height: height * 0.2,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () {
                            response_type = "connect-new";
                            room_type = "private";
                            sendNameAndRoomDetails();
                          },
                          child: const Text('Create new private room'),
                        ),
                        TextButton(
                          onPressed: () {
                            response_type = "connect-new";
                            room_type = "public";
                            sendNameAndRoomDetails();
                          },
                          child: const Text('Join Public Room'),
                        ),
                        Row(
                          children: [
                            SizedBox(
                              width: width * 0.1,
                              child: TextField(
                                controller: roomIdTextController,
                                decoration: const InputDecoration(
                                  hintText: 'Enter room id',
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                response_type = "connect";
                                room_type = "private";
                                sendNameAndRoomDetails();
                              },
                              child: const Text('Join a private room with id'),
                            ),
                          ],
                        ),
                      ],
                    )
                  ],
                ),
              ),
            )
          : Column(
              children: [
                StreamBuilder<ServerResponse>(
                  stream: readableStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text(snapshot.error.toString());
                    }
                    if (snapshot.hasData) {
                      final response = snapshot.data;
                      if (response!.response_type == "total") {
                        int len = response.room_info.grp1.length +
                            response.room_info.grp2.length;
                        joined = len.toString();
                        return Text(
                            "New User joined: ${response.client_info.name}\tRoom ID: ${room_type == "private" ? response.room_info.room_id : "PUBLIC_ROOM"}");
                      } else if (response.response_type == "dis") {
                        int len = response.room_info.grp1.length +
                            response.room_info.grp2.length;
                        joined = len.toString();
                        return Text(
                            "User left the room: ${response.client_info.name}\tRoom ID: ${room_type == "private" ? response.room_info.room_id : "PUBLIC_ROOM"}");
                      }
                    }
                    return Text("Clients in room $joined");
                  },
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      width: width * 0.2,
                      height: height * 0.8,
                      child: StreamBuilder<ServerResponse>(
                        stream: readableStream,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Text(snapshot.error.toString());
                          }
                          if (snapshot.hasData) {
                            final response = snapshot.data;
                            group1 = response!.room_info.grp1;
                            group2 = response.room_info.grp2;
                          }
                          return Column(
                            children: [
                              const Text(
                                "Group 1",
                                style: TextStyle(fontSize: 30),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      title: Text(
                                        group1[index].name.toString(),
                                      ),
                                    );
                                  },
                                  itemCount: group1.length,
                                ),
                              ),
                              const Text(
                                "Group 2",
                                style: TextStyle(fontSize: 30),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      title: Text(
                                        group2[index].name.toString(),
                                      ),
                                    );
                                  },
                                  itemCount: group2.length,
                                ),
                              )
                            ],
                          );
                        },
                      ),
                    ),
                    Container(
                      width: width * 0.6,
                      height: height * 0.9,
                      color: const Color.fromARGB(255, 240, 240, 145),
                      child: Stack(
                        children: [
                          if (!isBuilding)
                            Center(
                              child: buildCurrentStreamingPoints(
                                  context, width * 0.6, height * 0.8),
                            ),
                          Center(
                            child: buildAllPaths(context, width * 0.6, height * 0.8),
                          ),
                          Center(
                            child: buildCurrentPath(context, width * 0.6, height * 0.8),
                          ),
                          buildClearButton(),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: width * 0.2,
                      height: height * 0.8,
                      child: StreamBuilder<ServerResponse>(
                        stream: readableStream,
                        builder: (context, snapshot) {
                          print(snapshot.data);
                          if (snapshot.hasError) {
                            log(snapshot.error.toString());
                            return const Text("An error occured");
                          }
                          if (snapshot.hasData) {
                            final responseData = snapshot.data;

                            if (responseData!.response_type == "set") {
                              return Text(
                                  "CurrentClientID: $id\nID: ${responseData.client_info.client_id}\n");
                            }
                          }

                          return const Text("No movement");
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
