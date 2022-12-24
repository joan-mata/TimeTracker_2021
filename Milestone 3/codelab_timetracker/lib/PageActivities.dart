import 'package:codelab_timetracker/PageIntervals.dart';
import 'package:codelab_timetracker/PageTaskDetail.dart';
import 'package:flutter/material.dart';
import 'package:codelab_timetracker/tree.dart' hide getTree;
// the old getTree()
import 'package:codelab_timetracker/requests.dart';
// has the new getTree() that sends an http request to the server
import 'dart:async';

class PageActivities extends StatefulWidget {
  final int id;
  PageActivities(this.id);

  @override
  _PageActivitiesState createState() => _PageActivitiesState();
}

class _PageActivitiesState extends State<PageActivities> {
  late int id;
  late Future<Tree> futureTree;

  late Timer _timer;
  static const int periodeRefresh = 2;

  //Used in form to create new activity
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    id = widget.id;
    futureTree = getTree(id);
    _activateTimer();
  }


// future with listview
// https://medium.com/nonstopio/flutter-future-builder-with-list-view-builder-d7212314e8c9
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Tree>(
      future: futureTree,
      // this makes the tree of children, when available, go into snapshot.data
      builder: (context, snapshot) {
        // anonymous function
        if (snapshot.hasData) {
          return DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(                                          //APPBAR
                bottom: const TabBar(
                  tabs: [
                    Tab(
                      text: 'Tasks and projects',
                      icon: Icon(Icons.list_alt_outlined),
                    ),
                    Tab(
                        text: 'Information',
                        icon: Icon(Icons.info_outline),
                    ),
                  ],
                ),
                title: Text((() {
                  if(snapshot.data!.root.id == 0){
                    return "Time Tracker";
                  }
                  else {
                    return snapshot.data!.root.name;
                }})()),

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
                        PageActivities(0);
                      }),
                  //TODO other actions
                ],
              ),




              body: TabBarView(
                children: [
                  (() {                                                                  //TASKS AND PROJECTS
                    if(snapshot.data!.root.children.isNotEmpty) {
                      return(
                          ListView.separated(
                            // it's like ListView.builder() but better because it includes a separator between items
                            padding: const EdgeInsets.all(16.0),
                            itemCount: snapshot.data!.root.children.length,
                            itemBuilder: (BuildContext context, int index) =>
                                _buildRow(snapshot.data!.root.children[index], index),
                            separatorBuilder: (BuildContext context, int index) =>
                            const Divider(),
                          )
                      );
                    }
                    else {
                      return(const Center(
                        child: Text(
                          'No tasks or projects yet.',
                          style: TextStyle(fontSize: 24),
                        ),
                      ));
                    }
                    // your code here
                  }()),
                  Container(                                                                 //INFORMATION
                      padding: const EdgeInsets.all(5),
                      child: Column( //Main colum
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children:
                        (() {
                          if (snapshot.data!.root.children.isNotEmpty && snapshot.data!.root.initialDate!=null){
                            return(
                                [
                                  Container( //initial date
                                      padding: const EdgeInsets.all(30),
                                      child:
                                      Column(
                                        children: [
                                          Text('Initial date'),
                                          Divider(),
                                          Text(snapshot.data!.root.initialDate.toString().split('.')[0],
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
                                          Text(snapshot.data!.root.finalDate.toString().split('.')[0],
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
                                      Text('Project not started yet',
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

                ],
              ),
              floatingActionButton: FloatingActionButton(                             //FLOATING BUTTON
                onPressed: () => _addActivity(snapshot.data!.root.id),
                tooltip: 'Increment'
                ,
                child: const Icon(Icons.add),
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
            child: const Center(
              child: CircularProgressIndicator(),
            ));
      },
    );
  }

  Widget _buildRow(Activity activity, int index) {
    String strDuration = Duration(seconds: activity.duration).toString().split('.').first;
    // split by '.' and taking first element of resulting list removes the microseconds part
    if (activity is Project) {       //PROJECT

      Widget trailing;
      trailing = Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(strDuration),
            IconButton(
              icon: const Icon(Icons.brightness_1_outlined),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('This project is not active'))
                );
              },
            ),
          ]);

      return ListTile(
        title: Text('${activity.name}'),
        trailing: trailing,
        onTap: () => _navigateDownActivities(activity.id),
      );
    } else if (activity is Task) {       //TASK
      Task task = activity as Task;

      Widget trailing;
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(strDuration),
          IconButton(
            icon:(() {
              if (task.active && task.children.isNotEmpty) {
                return(const Icon(
                Icons.pause,
                color: Colors.red,));
              } else {
                return(const Icon(
                Icons.play_arrow,
                color: Colors.green,));
              }} ()),

            onPressed: () {
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
          ),

      ]);

      return ListTile(
        title: Text('${activity.name}'),
        trailing: trailing,
        onTap: () => _navigateDownIntervals(activity.id),
      );
    } else {
      throw(Exception("Activity that is neither a Task or a Project"));
      // this solves the problem of return Widget is not nullable because an
      // Exception is also a Widget?
    }
  }



  void _navigateDownActivities(int childId) {
    _timer.cancel();
    // we can not do just _refresh() because then the up arrow doesn't appear in the appbar
    Navigator.of(context)
        .push(MaterialPageRoute<void>(
      builder: (context) => PageActivities(childId),
    )).then((var value) {
      _activateTimer();
      _refresh();
    });
    //https://stackoverflow.com/questions/49830553/how-to-go-back-and-refresh-the-previous-page-in-flutter?noredirect=1&lq=1
  }

  void _navigateDownIntervals(int childId) {
    _timer.cancel();
    Navigator.of(context)
        .push(MaterialPageRoute<void>(
      //builder: (context) => PageIntervals(childId),
      builder: (context) => PageTaskDetail(childId),
    )).then((var value) {
      _activateTimer();
      _refresh();
    });
  }

  void _addActivity(int parentId){
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            scrollable: true,
            title: Text('Create new task or project'),
            content: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        icon: Icon(Icons.account_box),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter some text';
                        }
                        return null;
                      },
                      controller: _nameController,
                    ),
                    Divider(
                      height: 30,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          addTask(parentId, _nameController.text);
                          _nameController.clear();
                          _refresh();
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Task created'))
                          );
                          Navigator.pop(context);
                        }
                      },
                      child: const Text("Create Task"),
                    ),

                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          addProject(parentId, _nameController.text);
                          _nameController.clear();
                          _refresh();
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Project created'))
                          );
                          Navigator.pop(context);
                        }
                      },
                      child: const Text("Create Project"),
                    ),
                  ],
                ),
              ),
            ),
          );
        });

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
