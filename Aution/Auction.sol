// SPDX-License-Identifier: MIT

pragma solidity ^0.8;
pragma experimental  ABIEncoderV2;

library SafeMath{
    function safeAdd(uint a, uint b)public pure returns(uint c){
        require(c >= a);
        c = a + b;
    }
    function safeSub(uint a, uint b)public pure returns(uint c){
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b)public pure returns(uint c){
        require(a == 0 || c/a == b);
        c = a * b;
    }
    function safeDiv(uint a, uint b)public pure returns(uint c){
        require(b > 0);
        c = a / b;
    }
}

contract Auction_Manager{

    using SafeMath for uint;
    enum Auction_State{
        Created,
        Live,
        Closed
    }
    
    enum Bid_State{
        Placed,
        Accepted
    }

    struct Auction{
        string Auction_Id;
        address Auction_owner;
        uint256 highest_Bid;
        uint256 Auction_Start_Date;
        uint256 Auction_Expiry_Date;
        bool Auction_Is_Live;
        address Top_Bidder;
        uint Auction_Index;
        Auction_Manager.Auction_State state;
    }

    struct Bid{
        string Bid_Id;
        string Auction_Id;
        string Payable_Date;
        address Bid_Owner;
        uint256 Bid_Value;
        bool Bid_Accepted;
    }

    mapping(uint => Auction) public auctions;
    mapping(uint => Bid[]) public bids;
    mapping(address => uint) balances;

    modifier onlyAuctionOwner(uint _auction_index){
        require(msg.sender == auctions[_auction_index].Auction_owner,"Only Auction Owner is Allowed");
        _;
    }

    modifier onlyBidOwner(uint _bid_index , uint _auction_index){
        require(msg.sender == bids[_auction_index][_bid_index].Bid_Owner,"Only Bid Owner is Allowed");
        _;
    }

    modifier onlyAuction_Or_BidOwner(uint _bid_index , uint _auction_index){
        require ((msg.sender == auctions[_auction_index].Auction_owner) || (msg.sender == bids[_auction_index][_bid_index].Bid_Owner) , "You either be a Auction Owner or Bid Owner");
        _;
    }

    Bid[] bid_list;
    Auction[] auction_list;

    uint auction_index = 0;
    uint bid_index = 0;


    function create_Auction(string memory _Auction_Id)public returns (bool success){
        auctions[auction_index].Auction_Id = _Auction_Id;
        auctions[auction_index].highest_Bid = 0;
        auctions[auction_index].Auction_owner = msg.sender;
        auctions[auction_index].state = Auction_State.Created;
        auctions[auction_index].Auction_Start_Date = block.timestamp ;
        auctions[auction_index].Auction_Expiry_Date = 90 seconds + block.timestamp ;
        auctions[auction_index].Auction_Is_Live = true;
        auctions[auction_index].Auction_Index = auction_index;
        auction_index++;
        return success = true;
    }


    function Read_AUction(uint _auction_index) public view returns(string memory Auction_Id, address Auction_owner, uint256 highest_Bid, Auction_Manager.Auction_State, uint256 Auction_Start_Date, uint256 Auction_Expiry_Date,bool Auction_Is_Live, uint Auction_Index){
        Auction storage a = auctions[_auction_index];
        return(a.Auction_Id,a.Auction_owner,a.highest_Bid,a.state,a.Auction_Start_Date,a.Auction_Expiry_Date,a.Auction_Is_Live,a.Auction_Index);
    }


    function Place_Bid (uint _auction_index, string memory _Bid_Id, uint256 _Bid_Amount, string memory payable_date)public returns (bool success){
      require(auctions[_auction_index].Auction_owner != msg.sender , "Auction OWner Should not Bid on Own Auction");
      require(auctions[_auction_index].Auction_Is_Live  , "Auction Should belive to place Bid");

      uint i;
      bool exists=false;

      for (i=0; i< bids[_auction_index].length; i++){
          if (bids[_auction_index][i].Bid_Owner == msg.sender){
              require (bids[_auction_index][i].Bid_Value < _Bid_Amount, "Bid must belarger than previous");
              exists = true;
              break;
          }
      }

      if(exists == true) {
          bids[_auction_index][i].Bid_Value = _Bid_Amount;
      }
      else{
          bids[_auction_index].push(Bid({
              Bid_Id : _Bid_Id,
              Auction_Id : auctions[_auction_index].Auction_Id,
              Bid_Owner : msg.sender,
              Bid_Value : _Bid_Amount,
              Payable_Date : payable_date,
              Bid_Accepted : false
          }));
      }
      bid_index++;

      if(auctions[_auction_index].highest_Bid < _Bid_Amount){
          auctions[_auction_index].highest_Bid = _Bid_Amount;
          auctions[_auction_index].state = Auction_State.Live;
      }

      return success = true;
    }


    function Total_Bid (uint _auction_index) public view onlyAuctionOwner(_auction_index)returns(uint){
        return bids[_auction_index].length;
    }

    function Read_Bid(uint _bid_index, uint _auction_index) public view onlyAuction_Or_BidOwner(_bid_index, _auction_index) returns (Bid[] memory){
        Bid storage b = bids[_auction_index][_bid_index];
        //return b ;
    }

    function readAllBids(uint _auction_index) public view onlyAuctionOwner(_auction_index) returns(Bid[] memory){
        return bids[_auction_index];
    }

    function Accepted_Bid(uint _bid_index, uint _auction_index) public onlyAuctionOwner(_auction_index){
       bids[_auction_index][_bid_index].Bid_Accepted = true;
       auctions[_auction_index].state = Auction_State.Closed;
       auctions[_auction_index].Auction_Is_Live = false;
    }


    function Close_Auction(uint _auction_index) public onlyAuctionOwner(_auction_index)returns(bool success){
        require(block.timestamp > auctions[auction_index].Auction_Start_Date);
        auctions[_auction_index].state = Auction_State.Closed;
        auctions[_auction_index].Auction_Is_Live = false;
        return success = true;
    }


    function Repay_Auction (uint _bid_index , uint _auction_index)payable public onlyBidOwner(_bid_index , _auction_index)returns(bool success){
        require (msg.value ==  bids[_auction_index][_bid_index].Bid_Value);
        require(  bids[_auction_index][_bid_index].Bid_Accepted = true);
        address Auc_owner = auctions[_auction_index].Auction_owner;
        return success = true;
    }

}