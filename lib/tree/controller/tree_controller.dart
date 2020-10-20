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

import 'package:flutter/cupertino.dart';
import 'node_controller.dart';
import '../node/tree_node.dart';

/// Controls the ListTreeView.
class TreeViewController extends ChangeNotifier {
  TreeViewController();

  NodeController _rootController;

  NodeData rootNodeData;
  List<NodeData> data;

  void treeData(List<NodeData> data) {
    assert(data != null, 'The data should not be empty');
    this.data = data;
    notifyListeners();
  }

  /// Gets the data associated with each item
  NodeData dataForTreeNode(TreeNodeItem nodeItem) {
    final nodeData = nodeItem.parent;
    if (nodeData == null) {
      return data[nodeItem.index];
    }
    return nodeData.children[nodeItem.index];
  }

  int itemChildrenLength(NodeData item) {
    if (item == null) {
      return data.length;
    }
    final nodeData = item;
    return nodeData.children.length;
  }

  ///Gets the number of visible children of the ListTreeView
  int numberOfVisibleChild() {
    return rootController.numberOfVisibleDescendants();
  }

  ///Get the controller for the root node. If null will be initialized according to the data
  NodeController get rootController {
    if (_rootController == null) {
      _rootController = NodeController(
          parent: _rootController,
          expandCallback: (NodeData item) {
            return true;
          });
      final num = data.length;

      final indexes = <int>[];
      for (var i = 0; i < num; i++) {
        indexes.add(i);
      }
      final controllers = createNodeController(_rootController, indexes);
      _rootController.insertChildControllers(controllers, indexes);
    }
    return _rootController;
  }

  /// Click item to expand or contract or collapse
  /// [index] The index of the clicked item
  TreeNode expandOrCollapse(int index) {
    final treeNode = treeNodeOfIndex(index);
    if (treeNode.isExpanded) {
      collapseItem(treeNode);
    } else {
      expandItem(treeNode);
    }

    ///notify refresh ListTreeView
    notifyListeners();
    return treeNode;
  }

  bool isExpanded(NodeData item) {
    final index = indexOfItem(item);
    return treeNodeOfIndex(index).isExpanded;
  }

  /// Begin collapse
  void collapseItem(TreeNode treeNode) {
    final controller = _rootController.controllerOfItem(treeNode.item);
    controller.collapseAndCollapseChildren(true);
  }

  /// Begin expand
  void expandItem(TreeNode treeNode) {
    final items = <NodeData>[treeNode.item];
    while (items.isNotEmpty) {
      final currentItem = items.first;
      items.remove(currentItem);
      final controller = _rootController.controllerOfItem(currentItem);
      final oldChildItems = <NodeController>[];
      for (final controller in controller.childControllers) {
        oldChildItems.add(controller);
      }
      final numberOfChildren = itemChildrenLength(currentItem);
      final indexes = <int>[];
      for (var i = 0; i < numberOfChildren; i++) {
        indexes.add(i);
      }
      final currentChildControllers = createNodeController(controller, indexes);
      final childControllersToInsert = <NodeController>[];
      final indexesForInsertions = <int>[];
      final childControllersToRemove = <NodeController>[];
      final indexesForDeletions = <int>[];
      for (final loopNodeController in currentChildControllers) {
        if (!controller.childControllers.contains(loopNodeController) &&
            !oldChildItems.contains(controller.treeNode.item)) {
          childControllersToInsert.add(loopNodeController);
          // ignore: omit_local_variable_types
          final int index = currentChildControllers.indexOf(loopNodeController);
          assert(index != -1);
          indexesForInsertions.add(index);
        }
      }

      for (final loopNodeController in controller.childControllers) {
        if (!currentChildControllers.contains(loopNodeController) &&
            !childControllersToInsert.contains(loopNodeController)) {
          childControllersToRemove.add(loopNodeController);
          final index = controller.childControllers.indexOf(loopNodeController);
          assert(index != -1);
          indexesForDeletions.add(index);
        }
      }

      controller.removeChildControllers(indexesForDeletions);
      controller.insertChildControllers(childControllersToInsert, indexesForInsertions);
      const expandChildren = false;
      if (expandChildren) {
        for (final nodeController in controller.childControllers) {
          items.add(nodeController.treeNode.item);
        }
      }
      controller.expandAndExpandChildren(false);
      notifyListeners();
    }
  }

  /// Insert a node in the head
  /// [parent] The parent node
  /// [newNode] The node will be insert
  /// [closeCanInsert] Can insert when parent closed
  void insertAtFront(NodeData parent, NodeData newNode, {bool closeCanInsert = false}) {
    if (!closeCanInsert) {
      if (parent != null && !isExpanded(parent)) {
        return;
      }
    }
    parent.children.insert(0, newNode);
    _insertItemAtIndex(0, parent);
    notifyListeners();
  }

  /// Appends all nodes to the head of parent.
  /// [parent] The parent node
  /// [newNode] The node will be insert
  /// [closeCanInsert] Can insert when parent closed
  void insertAllAtFront(NodeData parent, List<NodeData> newNodes, {bool closeCanInsert = false}) {
    if (!closeCanInsert) {
      if (parent != null && !isExpanded(parent)) {
        return;
      }
    }
    parent.children.insertAll(0, newNodes);
    _insertAllItemAtIndex(0, parent, newNodes);
    notifyListeners();
  }

  /// Insert a node in the end
  /// [parent] The parent node
  /// [newNode] The node will be insert
  /// [closeCanInsert] Can insert when parent closed
  void insertAtRear(NodeData parent, NodeData newNode, {bool closeCanInsert = false}) {
    if (!closeCanInsert) {
      if (parent != null && !isExpanded(parent)) {
        return;
      }
    }
    parent.children.add(newNode);
    _insertItemAtIndex(0, parent, isFront: false);
    notifyListeners();
  }

  ///Inserts a node at position [index] in parent.
  /// The [index] value must be non-negative and no greater than [length].
  void insertAtIndex(int index, NodeData parent, NodeData newNode, {bool closeCanInsert = false}) {
    assert(index <= parent.children.length);
    if (!closeCanInsert) {
      if (parent != null && !isExpanded(parent)) {
        return;
      }
    }
    parent.children.insert(index, newNode);
    _insertItemAtIndex(index, parent, isIndex: true);

    notifyListeners();
  }

  void _insertItemAtIndex(int index, NodeData parent, {bool isIndex = false, bool isFront = true}) {
    final idx = indexOfItem(parent);
    if (idx == -1) {
      return;
    }
    final parentController = _rootController.controllerOfItem(parent);
    if (isIndex) {
      final newControllers = createNodeController(parentController, [index]);
      parentController.insertNewChildControllers(newControllers[0], index);
    } else {
      if (isFront) {
        final newControllers = createNodeController(parentController, [0]);
        parentController.insertChildControllers(newControllers, [0]);
      } else {
        final newControllers =
            createNodeController(parentController, [parentController.childControllers.length]);
        parentController.addChildController(newControllers);
      }
    }
  }

  void _insertAllItemAtIndex(
    int index,
    NodeData parent,
    List<NodeData> newNodes, {
    bool isIndex = false,
    bool isFront = true,
  }) {
    final idx = indexOfItem(parent);
    if (idx == -1) {
      return;
    }
    final parentController = _rootController.controllerOfItem(parent);
    if (isIndex) {
      final newControllers = createNodeController(parentController, [index]);
      parentController.insertNewChildControllers(newControllers[0], index);
    } else {
      if (isFront) {
        final nodes = <int>[];
        for (var i = 0; i < newNodes.length; i++) {
          nodes.add(i);
        }
        final newControllers = createNodeController(parentController, nodes);
        parentController.insertChildControllers(newControllers, nodes);
      } else {
        final newControllers =
            createNodeController(parentController, [parentController.childControllers.length]);
        parentController.addChildController(newControllers);
      }
    }
  }

  ///remove
  void removeItem(NodeData item) {
    final temp = parentOfItem(item);
    final parent = temp;
    var index = 0;
    if (parent == null) {
      index = data.indexOf(item);
      data.remove(item);
    } else {
      index = parent.children.indexOf(item);
      parent.children.remove(item);
    }

    removeItemAtIndexes(index, parent);

    notifyListeners();
  }

  ///
  void removeItemAtIndexes(int index, NodeData parent) {
    if (parent != null && !isExpanded(parent)) {
      return;
    }
    final nodeController = _rootController.controllerOfItem(parent).childControllers[index];
    final child = nodeController.treeNode.item;
    final idx = _rootController.lastVisibleDescendantIndexForItem(child);
    if (idx == -1) {
      return;
    }
    final parentController = _rootController.controllerOfItem(parent);
    parentController.removeChildControllers([index]);
  }

  ///select
  void selectItem(NodeData item) {
    assert(item != null, 'Item should not be null');
    item.isSelected = !item.isSelected;
    notifyListeners();
  }

  void selectAllChild(NodeData item) {
    assert(item != null, 'Item should not be null');
    item.isSelected = !item.isSelected;
    if (item.children.isNotEmpty) {
      _selectAllChild(item);
    }
    notifyListeners();
  }

  void _selectAllChild(NodeData sItem) {
    if (sItem.children.isEmpty) return;
    for (final child in sItem.children) {
      child.isSelected = sItem.isSelected;
      _selectAllChild(child);
    }
  }

  /// Create controllers for each child node
  List<NodeController> createNodeController(NodeController parentController, List<int> indexes) {
    final children = parentController.childControllers.map((e) => e).toList();
    final newChildren = <NodeController>[];

    indexes.forEach((element) {});

    for (final i in indexes) {
      NodeController controller;
      NodeController oldController;
      final lazyItem =
          TreeNodeItem(parent: parentController.treeNode.item, controller: this, index: i);
      parentController.childControllers.forEach((controller) {
        if (controller.treeNode.item == lazyItem.item) {
          oldController = controller;
        }
      });
      if (oldController != null) {
        controller = oldController;
      } else {
        controller = NodeController(
            parent: parentController,
            nodeItem: lazyItem,
            expandCallback: (NodeData item) {
              var result = false;
              children.forEach((controller) {
                if (controller.treeNode.item == item) {
                  result = true;
                }
              });
              return result;
            });
      }
      newChildren.add(controller);
    }
    return newChildren;
  }

  NodeController createNewNodeController(NodeController parentController, int index) {
    final lazyItem =
        TreeNodeItem(parent: parentController.treeNode.item, controller: this, index: index);
    final controller = NodeController(
      parent: parentController,
      nodeItem: lazyItem,
      expandCallback: (NodeData item) => false,
    );
    return controller;
  }

  ///Gets the data information for the parent node
  NodeData parentOfItem(NodeData item) {
    final controller = _rootController.controllerOfItem(item);
    return controller.parent.treeNode.item;
  }

  /// TreeNode by index
  TreeNode treeNodeOfIndex(int index) {
    return _rootController.controllerForIndex(index).treeNode;
  }

  /// The level of the specified item
  int levelOfNode(NodeData item) {
    final controller = _rootController.controllerOfItem(item);
    return controller.level;
  }

  /// The index of the specified item
  int indexOfItem(NodeData item) {
    return _rootController.indexOfItem(item);
  }
}
