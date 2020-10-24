import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:list_treeview/list_treeview.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Center(
        child: RaisedButton(
          child: Text('TreeView'),
          onPressed: () {
            Navigator.push<Widget>(
              context,
              CupertinoPageRoute(builder: (_) => TreePage()),
            );
          },
        ),
      ),
    );
  }
}

/// The data class that is bound to the child node
/// You must inherit from NodeData ！！！
/// You can customize any of your properties
class TreeNodeData {
  TreeNodeData({this.label, this.color});

  final String label;
  final Color color;
}

class TreePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _TreePageState();
  }
}

class _TreePageState extends State<TreePage> with SingleTickerProviderStateMixin {
  TreeViewController _controller;
  bool _isSuccess;

  @override
  void initState() {
    super.initState();

    ///The controller must be initialized when the treeView create
    _controller = TreeViewController();

    ///Data may be requested asynchronously
    getData();
  }

  Future<void> getData() async {
    print('start get data');
    _isSuccess = false;
    //await Future<void>.delayed(Duration(seconds: 2));

    final colors1 = NodeData<TreeNodeData>.fromData(
      data: TreeNodeData(
        label: 'kek',
        color: Color.fromARGB(255, 0, 139, 69),
      ),
      children: [
        NodeData<TreeNodeData>.fromData(
          data: TreeNodeData(
            label: 'kek',
            color: Color.fromARGB(255, 0, 139, 69),
          ),
        ),
      ],
    );

    /// set data
    _controller.treeData([colors1]);
    print('set treeData suceess');

    setState(() {
      _isSuccess = true;
    });
  }

  NodeData<TreeNodeData> randomColorNode({List<NodeData> children}) {
    final r = Random.secure().nextInt(254);
    final g = Random.secure().nextInt(254);
    final b = Random.secure().nextInt(254);
    final color = Color.fromARGB(255, r, g, b);
    return NodeData<TreeNodeData>.fromData(
      data: TreeNodeData(label: color.toString(), color: color),
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TreeView'),
      ),
      body: _isSuccess ? getBody() : getProgressView(),
    );
  }

  Widget getProgressView() {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget getBody() {
    return ListTreeView(
      shrinkWrap: false,
      padding: EdgeInsets.all(0),
      itemBuilder: (BuildContext context, NodeData data) {
        final offsetX = data.level * 16.0;
        return Container(
          height: 54,
          padding: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(width: 1, color: Colors.grey),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: offsetX),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(right: 5),
                        child: InkWell(
                          splashColor: Colors.amberAccent.withOpacity(1),
                          highlightColor: Colors.red,
                          onTap: () => _controller.selectAllChild(data),
                          child: data.isSelected
                              ? Icon(
                                  Icons.star,
                                  size: 30,
                                  color: Color(0xFFFF7F50),
                                )
                              : Icon(
                                  Icons.star_border,
                                  size: 30,
                                  color: Color(0xFFFFDAB9),
                                ),
                        ),
                      ),
                      Text(
                        'level-${data.level}-${data.indexInParent}',
                        style: TextStyle(fontSize: 15, color: (data.data as TreeNodeData).color),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                    ],
                  ),
                ),
              ),
              Visibility(
                visible: data.isExpand,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => _controller.insertAtRear(data, randomColorNode()),
                      icon: Icon(Icons.arrow_downward, size: 30),
                    ),
                    IconButton(
                      onPressed: () => _controller.insertAtFront(data, randomColorNode()),
                      icon: Icon(Icons.arrow_upward, size: 30),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
      onTap: (NodeData node) => print('index = ${node.index}'),
      onLongPress: (NodeData data) => _controller.removeItem(data),
      controller: _controller,
    );
  }
}
