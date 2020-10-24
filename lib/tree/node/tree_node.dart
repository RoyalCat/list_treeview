// Copyright (c) 2020 sooxie
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
import 'package:meta/meta.dart';

import '../../list_treeview.dart';

class TreeNode {
  TreeNode({
    TreeNodeItem lazyItem,
    @required this.expandCallback,
  }) : _lazyItem = lazyItem;

  bool _expanded = false;
  bool Function(NodeData item) expandCallback;

  final TreeNodeItem _lazyItem;

  NodeData get item => _lazyItem?.item;

  bool get isExpanded {
    if (expandCallback != null) {
      _expanded = expandCallback(item);
    }
    return _expanded;
  }

  set isExpanded(bool expanded) {
    expandCallback = null;
    _expanded = expanded;
  }
}

class TreeNodeItem {
  TreeNodeItem({this.parent, this.index, this.controller});

  final NodeData parent;
  final int index;
  final TreeViewController controller;
  NodeData _item;

  NodeData get item {
    _item ??= controller.dataForTreeNode(this);
    return _item;
  }
}

///This class contains information about the nodes, such as Index and level, and whether to expand. It also contains other information
class NodeData<T> {
  NodeData.raw(this.data, this.children, this.isSelected, this.index, this.indexInParent,
      this.level, this.isExpand);
  NodeData.fromData({this.data, List<NodeData<dynamic>> children})
      : children = children ?? <NodeData>[];

  T data;

  List<NodeData<dynamic>> children;
  bool isSelected = false;

  /// Index in all nodes
  int index;

  /// Index in parent node
  int indexInParent;
  int level;
  bool isExpand = false;

  void addChild(NodeData<dynamic> child) {
    children.add(child);
  }

  void addChildren(List<NodeData<dynamic>> child) {
    children.addAll(child);
  }

  NodeData copyWith({
    T data,
    List<NodeData<dynamic>> children,
    bool isSelected,
    int index,
    int indexInParent,
    int level,
    bool isExpand,
  }) =>
      NodeData<T>.raw(
        data ?? this.data,
        children ?? this.children,
        isSelected ?? this.isSelected,
        index ?? this.index,
        indexInParent ?? this.indexInParent,
        level ?? this.level,
        isExpand ?? this.isExpand,
      );
}
