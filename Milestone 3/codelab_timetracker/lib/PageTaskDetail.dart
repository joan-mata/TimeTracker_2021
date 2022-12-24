import 'package:flutter/material.dart';
import 'package:codelab_timetracker/tree.dart' as Tree hide getTree;
// to avoid collision with an Interval class in another library
import 'package:codelab_timetracker/requests.dart';
import 'dart:async';

class PageTaskDetail extends StatefulWidget {
  final int id; // final because StatefulWidget is immutable
  PageTaskDetail(this.id);

  @override
  _PageTaskDetailState createState() => _PageTaskDetailState();
}

class _PageTaskDetailState extends State<PageTaskDetail> {
  late int id;
  late Future<Tree.Tree> futureTree;

  late Timer _timer;
  static const int periodeRefresh = 2;
// better a multiple of periode in TimeTracker, 2 seconds

  @override
  void initState() {
    super.initState();
    id = widget.id;
    futureTree = getTree(id);
    _activateTimer();
  }

  @override
  Widget build(BuildContext context) {

    return FutureBuilder<Tree.Tree>(
      future: futureTree,
      // this makes the tree of children, when available, go into snapshot.data
      builder: (context, snapshot) {
        // anonymous function
        if (snapshot.hasData) {
          int numChildren = snapshot.data!.root.children.length;
          Tree.Task task = snapshot.data!.root as Tree.Task;
          return DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: AppBar(
                bottom: const TabBar(
                  tabs: [
                    Tab(
                        text: 'Main',
                        icon: Icon(Icons.play_circle_outline),
                    ),
                    Tab(
                        text: 'Information',
                        icon: Icon(Icons.info_outline),
                    ),
                    Tab(
                        text: 'Intervals',
                        icon: Icon(Icons.watch_later_outlined),
                    ),
                  ],
                ),
                title: Text(snapshot.data!.root.name),
                actions: <Widget>[
                  IconButton(icon: Icon(Icons.home),
                      onPressed: () {
                        while(Navigator.of(context).canPop()) {
                          print("pop");
                          Navigator.of(context).pop();
                        }
                        /* this works also:
                      Navigator.popUntil(context, ModalRoute.withName('/'));
                      */
                        PageTaskDetail(0);
                      }),
                ],
              ),
              body: TabBarView(
                children: [
                  //MAIN
                  Container(
                    padding: const EdgeInsets.all(10),
                    child: Column( //Main colum
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container( //Task Duration
                          padding: const EdgeInsets.all(30),
                          child:
                            Column(
                                children: [
                                  const Text('Time worked on current task'),
                                  const Divider(),
                                  Text(Duration(seconds: task.duration).toString().split('.').first,
                                      style: const TextStyle(
                                      fontSize: 30.0,
                                    ),
                                  ),
                                ]
                            )
                        ),

                        (() {
                           if (task.active && task.children.isNotEmpty){
                             return(
                                 Container( //Interval Duration
                                     padding: const EdgeInsets.all(30),
                                     child:
                                     Column(
                                       children: [
                                         Text('Time worked on current interval'),
                                         Divider(),
                                         Text(Duration(seconds: task.children.last.duration).toString().split('.').first,
                                           style: const TextStyle(
                                             fontSize: 30.0,
                                           ),
                                         ),
                                       ],
                                     )
                                 )
                             );
                           }
                           else if (task.children.isEmpty){
                             return(const Text('Task not started yet',
                               style: TextStyle(
                                fontWeight: FontWeight.bold,
                               ),
                             )
                             );
                           }
                           else{
                             return(const Text(''));
                          }
                        } ()),
                      ],
                    )
                  ),

                  //INFO
                  Container(
                      padding: const EdgeInsets.all(5),
                      child: Column( //Main colum
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children:
                          (() {
                            if (task.children.isNotEmpty && task.initialDate!=null){
                              return(
                              [
                                Container( //initial date
                                    padding: const EdgeInsets.all(30),
                                    child:
                                    Column(
                                      children: [
                                          Text('Initial date'),
                                        Divider(),
                                        Text(task.initialDate.toString().split('.')[0],
                                          style: const TextStyle(
                                            fontSize: 20.0,
                                          ),
                                        ),
                                      ],
                                    )
                                ),
                                Container( //initial date
                                    padding: const EdgeInsets.all(30),
                                    child:
                                    Column(
                                      children: [
                                        Text('Final date'),
                                        Divider(),
                                        Text(task.finalDate.toString().split('.')[0],
                                          style: const TextStyle(
                                            fontSize: 20.0,
                                          ),
                                        ),
                                      ],
                                    )
                                ),
                              ]
                              );
                            }
                            else{
                              return([
                                Container( //initial date
                                  padding: const EdgeInsets.all(30),
                                  child:
                                  Column(
                                    children: const [
                                      Text('Task not started yet',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    ],
                                  )
                                )
                              ]);
                            }
                          } ()),
                      )
                  ),
                  //INTERVALS
                  (() {
                  if(numChildren>0) {
                    return(ListView.separated(
                      // it's like ListView.builder() but better because it includes a separator between items
                      padding: const EdgeInsets.all(16.0),
                      itemCount: numChildren,
                      itemBuilder: (BuildContext context, int index) =>
                          _buildRow(snapshot.data!.root.children[index], index),
                      separatorBuilder: (BuildContext context, int index) =>
                      const Divider(),
                    ));
                  }
                  else {
                    return(const Center(
                      child: Text(
                        'Task not started yet.',
                        style: TextStyle(fontSize: 24),
                      ),
                    ));
                  }
                  // your code here
                }()),
                ],
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  Tree.Task task = snapshot.data!.root as Tree.Task;
                  if (task.active) {
                    stop(task.id);
                    _refresh(); // to show immediately that task has started
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Task stopped'))
                    );
                  } else {
                    start(task.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Task  started'))
                    );
                    _refresh(); // to show immediately that task has stopped
                  }
                },

                tooltip: 'Play'
                ,
                child: (() {
                  if (task.active && task.children.isNotEmpty) {
                    return(const Icon(Icons.pause));
                  } else {
                    return(const Icon(Icons.play_arrow));
                  }} ()),
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Text("${snapshot.error}");
        }
        // By default, show a progress indicator
        return Container(
            height: MediaQuery.of(context).size.height,
            color: Colors.white,
            child: Center(
              child: CircularProgressIndicator(),
            ));
      },
    );
  }


  Widget _buildRow(Tree.Interval interval, int index) {
    String strDuration = Duration(seconds: interval.duration)
        .toString()
        .split('.')
        .first;
    String strInitialDate = interval.initialDate.toString().split('.')[0];
    // this removes the microseconds part
    String strFinalDate = interval.finalDate.toString().split('.')[0];
    return ListTile(
      title: Text('From: ${strInitialDate}'),
      subtitle: Text('To: ${strFinalDate}'),
      trailing: Text('$strDuration'),
    );
  }

  void _refresh() async {
    futureTree = getTree(id); // to be used in build()
    setState(() {});
  }

  void _activateTimer() {
    _timer = Timer.periodic(Duration(seconds: periodeRefresh), (Timer t) {
      futureTree = getTree(id);
      setState(() {});
    });
  }

  @override
  void dispose() {
    // "The framework calls this method when this State object will never build again"
    // therefore when going up
    _timer.cancel();
    super.dispose();
  }
}