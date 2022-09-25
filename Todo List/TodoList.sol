// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

contract TodoList{
    struct Todo {
        uint256 id;
        bytes32 content;
        address owner;
        bool isCompleted;
        uint256 timeStamp;
    }
    uint256 public constant maxAmountTodos = 10;

    //owner => todo;
    mapping (address => Todo[maxAmountTodos]) public todos;

    //owner => last todo id;
    mapping ( address => uint256) public lastIds;

    modifier onlyOwner (address _owner){
        require(msg.sender == _owner);
        _;
    }

    //Add a todo to a list
    function addTodo(bytes32 _content)public{
        Todo memory myNote = Todo(lastIds[msg.sender],_content,msg.sender,false,block.timestamp);
        todos[msg.sender][lastIds[msg.sender]] = myNote;
        if(lastIds[msg.sender] >= maxAmountTodos)
        lastIds[msg.sender] = 0;
        else lastIds[msg.sender]++;
    }

    //mark a todo as completed
    function markTodoAsCompleted(uint256 _todoId) public{
        require(_todoId < maxAmountTodos);
        require(!todos[msg.sender][_todoId].isCompleted);
        todos[msg.sender][_todoId].isCompleted = true;
    }
}