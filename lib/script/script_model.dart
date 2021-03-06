// This source code is a part of Project Violet.
// Copyright (C) 2021.violet-team. Licensed under the Apache-2.0 License.

import 'package:violet/script/parser.dart';

enum PNodeType {
  line_node,
  statement_node,
  block_node,
  index_node,
  variable_node,
  argument_node,
  function_node,
  runnable_node,
}

abstract class INode {
  PNodeType nodeType;

  INode(this.nodeType);
}

class PLine extends INode {
  PStatement statement;

  PLine(this.statement) : super(PNodeType.line_node);
}

enum StatementType {
  sfunction,
  sindex,
  srunnable,
}

class PStatement extends INode {
  StatementType type;

  PFunction function;
  PIndex index1, index2;
  PRunnable runnable;

  PStatement(this.type,
      {this.function, this.index1, this.index2, this.runnable})
      : super(PNodeType.statement_node);
}

class PBlock extends INode {
  bool isInnerBlock = false;
  bool isEmpty = false;
  bool isLine = false;
  PLine line;
  PBlock block;

  PBlock({this.isInnerBlock, this.isLine, this.isEmpty, this.line, this.block})
      : super(PNodeType.block_node);
}

class PIndex extends INode {
  bool isIndexing;
  PVariable variable1;
  PVariable variable2;

  PIndex({this.isIndexing, this.variable1, this.variable2})
      : super(PNodeType.index_node);
}

class PVariable extends INode {
  Object content;

  PVariable({this.content}) : super(PNodeType.variable_node);
}

class PArgument extends INode {
  PIndex index;
  PArgument argument;

  PArgument(this.index, {this.argument}) : super(PNodeType.argument_node);
}

class PFunction extends INode {
  String name;
  PArgument argument;

  PFunction(this.name, {this.argument}) : super(PNodeType.function_node);
}

enum RunnableType {
  sloop,
  sforeach,
  sif,
  sifelse,
}

class PRunnable extends INode {
  RunnableType type;
  String name;
  PIndex index1, index2;
  PBlock block1, block2;

  PRunnable(this.type, this.block1,
      {this.block2, this.name, this.index1, this.index2})
      : super(PNodeType.runnable_node);
}

class PActionDescription {
  /*   
     1:         S' -> script 
     2:     script -> block 
     3:       line -> stmt 
     4:       stmt -> function 
     5:       stmt -> index = index 
     6:       stmt -> runnable 
     7:      block -> [ block ] 
     8:      block -> line block 
     9:      block ->  
    10:     consts -> number 
    11:     consts -> string 
    12:      index -> variable 
    13:      index -> variable [ variable ] 
    14:   variable -> name 
    15:   variable -> function 
    16:   variable -> consts 
    17:   argument -> index 
    18:   argument -> index , argument 
    19:   function -> name ( ) 
    20:   function -> name ( argument ) 
    21:   runnable -> loop ( name = index to index ) block 
    22:   runnable -> foreach ( name : index ) block 
    23:   runnable -> if ( index ) block 
    24:   runnable -> if ( index ) block else block 
  */
  static List<ParserAction> actions = [
    //  1:         S' -> script
    //  2:     script -> block
    ParserAction((node) => node.userContents = node.childs[0].userContents),
    //  3:       line -> stmt
    ParserAction(
        (node) => node.userContents = PLine(node.childs[0].userContents)),
    //  4:       stmt -> function
    ParserAction((node) => node.userContents = PStatement(
        StatementType.sfunction,
        function: node.childs[0].userContents)),
    //  5:       stmt -> index = index
    ParserAction((node) => node.userContents = PStatement(StatementType.sindex,
        index1: node.childs[0].userContents,
        index2: node.childs[2].userContents)),
    //  6:       stmt -> runnable
    ParserAction((node) => node.userContents = PStatement(
        StatementType.srunnable,
        runnable: node.childs[0].userContents)),
    //  7:      block -> [ block ]
    ParserAction((node) => node.userContents =
        PBlock(isInnerBlock: true, block: node.childs[0].userContents)),
    //  8:      block -> line block
    ParserAction((node) => node.userContents = PBlock(
        isLine: true,
        line: node.childs[0].userContents,
        block: node.childs[1].userContents)),
    //  9:      block ->
    ParserAction((node) => node.userContents = PBlock(isEmpty: true)),
    // 10:     consts -> number
    ParserAction((node) =>
        node.userContents = PVariable(content: node.childs[0].contents)),
    // 11:     consts -> string
    ParserAction((node) =>
        node.userContents = PVariable(content: node.childs[0].contents)),
    // 12:      index -> variable
    ParserAction((node) =>
        node.userContents = PIndex(variable1: node.childs[0].userContents)),
    // 13:      index -> variable [ variable ]
    ParserAction((node) => node.userContents = PIndex(
        isIndexing: true,
        variable1: node.childs[0].userContents,
        variable2: node.childs[2].userContents)),
    // 14:   variable -> name
    ParserAction((node) =>
        node.userContents = PVariable(content: node.childs[0].contents)),
    // 15:   variable -> function
    ParserAction((node) =>
        node.userContents = PVariable(content: node.childs[0].userContents)),
    // 16:   variable -> consts
    ParserAction((node) =>
        node.userContents = PVariable(content: node.childs[0].userContents)),
    // 17:   argument -> index
    ParserAction(
        (node) => node.userContents = PArgument(node.childs[0].userContents)),
    // 18:   argument -> index , argument
    ParserAction((node) => node.userContents = PArgument(
        node.childs[0].userContents,
        argument: node.childs[1].userContents)),
    // 19:   function -> name ( )
    ParserAction(
        (node) => node.userContents = PFunction(node.childs[0].userContents)),
    // 20:   function -> name ( argument )
    ParserAction((node) => node.userContents = PFunction(
        node.childs[0].userContents,
        argument: node.childs[2].userContents)),
    // 21:   runnable -> loop ( name = index to index ) block
    ParserAction((node) => node.userContents = PRunnable(
        RunnableType.sloop, node.childs[8].userContents,
        name: node.childs[2].userContents,
        index1: node.childs[4].userContents,
        index2: node.childs[6].userContents)),
    // 22:   runnable -> foreach ( name : index ) block
    ParserAction((node) => node.userContents = PRunnable(
        RunnableType.sforeach, node.childs[6].userContents,
        name: node.childs[2].userContents,
        index1: node.childs[4].userContents)),
    // 23:   runnable -> if ( index ) block
    ParserAction((node) => node.userContents = PRunnable(
        RunnableType.sif, node.childs[4].userContents,
        index1: node.childs[2].userContents)),
    // 24:   runnable -> if ( index ) block else block
    ParserAction((node) => node.userContents = PRunnable(
        RunnableType.sif, node.childs[4].userContents,
        index1: node.childs[2].userContents,
        block2: node.childs[6].userContents)),
  ];
}
