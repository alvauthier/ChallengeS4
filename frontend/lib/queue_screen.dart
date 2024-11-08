import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:weezemaster/core/services/websocket_service.dart';
import 'package:weezemaster/translation.dart';

class QueueScreen extends StatefulWidget {
  final int initialPosition;
  final  WebSocketService webSocketService;

  const QueueScreen({
    Key? key,
    required this.initialPosition,
    required this.webSocketService,
  }) : super(key: key);

  @override
  _QueueScreenState createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  bool _isChecked = false;
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: widget.webSocketService.stream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final data = jsonDecode(snapshot.data as String);
          if (data['isFirstMessage'] == false && data['status'] == 'access_granted') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.pushReplacementNamed('concert', pathParameters: {'id': data['concertId']});
            });
            // return Container();
          } else {
            final position = data['position'];
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60.0),
                  child: Text(
                    'Weezemaster',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'ReadexProBold',
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 50.0),
                        child: Text(
                          translate(context)!.queue_info,
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'ReadexPro',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                        child: Text(
                          translate(context)!.queue_warning,
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'ReadexPro',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 40.0),
                        child: Text(
                          '${translate(context)!.queue_position} $position',
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'ReadexPro',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const CircularProgressIndicator(),
                      const SizedBox(height: 90),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isChecked = !_isChecked;
                          });
                        },
                        child: Row(
                          children: [
                            Checkbox(
                              value: _isChecked,
                              onChanged: (bool? value) {
                                setState(() {
                                  _isChecked = value ?? false;
                                });
                              },
                            ),
                            Expanded(
                              child: Text(
                                translate(context)!.queue_checkbox,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'ReadexPro',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isChecked
                          ? () {
                              Navigator.of(context).popUntil((route) => route.isFirst);
                            }
                          : null,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          backgroundColor: Colors.deepOrange,
                        ),
                        child: Text(
                          translate(context)!.back_home,
                          style: const TextStyle(
                            fontFamily: 'ReadexPro',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
        }

        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60.0),
              child: Text(
                'Weezemaster',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'ReadexProBold',
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 50.0),
                    child: Text(
                      translate(context)!.queue_info,
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'ReadexPro',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                    child: Text(
                      translate(context)!.queue_warning,
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'ReadexPro',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 40.0),
                    child: Text(
                      '${translate(context)!.queue_position} ${widget.initialPosition}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'ReadexPro',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 90),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isChecked = !_isChecked;
                      });
                    },
                    child: Row(
                      children: [
                        Checkbox(
                          value: _isChecked,
                          onChanged: (bool? value) {
                            setState(() {
                              _isChecked = value ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child: Text(
                            translate(context)!.queue_checkbox,
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'ReadexPro',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isChecked
                      ? () {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        }
                      : null,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      backgroundColor: Colors.deepOrange,
                    ),
                    child: Text(
                      translate(context)!.back_home,
                      style: const TextStyle(
                        fontFamily: 'ReadexPro',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
