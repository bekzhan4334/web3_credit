//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;
 
contract Example {

    struct St{
        uint256 number;
        string str;
    }

    uint256 public x;
    uint256 public y;
    string public str;
    
    uint256[] data;
    mapping(address => St) public map;

    constructor(uint256 _x, uint256 _y, string memory _str){
        x = _x;
        y = _y;
        str = _str;
    }

    function setXY(uint256 _x, uint256 _y)public returns(uint256){
        x = _x;
        y = _y;
        return _x + _y;
    }

    function setStr(string memory _str)public{
        str = _str;
    }

    function init(uint256 count)public returns(uint256[] memory){
        for(uint256 i = 0; i < count; i++){
            data.push(i * i);
        }
        return data;
    }

    function addToMap(address adr, St memory st)public{
        map[adr] = st;
    }
}
