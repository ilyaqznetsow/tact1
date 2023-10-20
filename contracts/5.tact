import "@stdlib/deploy";

/*
  TASK 5 - NFT random swap 
  The smart contract contains a bunch of different NFTs.
  A user brings his NFT (sends it to the smart contract), with 2.1 TON (2 for admin's profit, 0.1 for gas) in attachment (as fee for swap).
  The smart contract randomly chooses some NFT from the available NFTs (including the newly incoming one) and gives it to the user in exchange for the brought NFT (but occasionally just returns user's NFT in some cases).
  Admin can deposit NFTs without swap logic. Any NFT received from the admin is considered deposited. Admin can't swap.
  Admin can withdraw all NFTs at once, and also all TONs collected from users as fees.
  Implement getter that will return NFT addresses held by the smart contract.
  Implement getter that will return the amount of admin`s profit collected.

  In details, the smart contract (later: SC) should have this logic:
  Messages

*/

message AdminWithdrawalProfit {
  queryId: Int as uint64;
}

message AdminWithdrawalAllNFTs {
  queryId: Int as uint64;
}

message AdminFetchProfit {
  queryId: Int as uint64;
}

message(0x05138d91) OwnershipAssigned {
    queryId: Int as uint64;
    prevOwner: Address;
    forwardPayload: Slice as remaining; 
}

message(0x5fcc3d14) Transfer { 
    queryId: Int as uint64;            
    newOwner: Address; 
    responseDestination: Address; 
    customPayload: Cell?; 
    forwardAmount: Int as coins; 
    forwardPayload: Slice as remaining; 
}

contract Task5 with Deployable {
  seed: Int as uint128;
  owner: Address;
  items: map<Int as uint16, Address>;
  itemsSize: Int as uint16 = 0;

  init(seed: Int, owner: Address) {
    self.owner = owner;
    self.seed = seed; 
  }

  receive(msg: OwnershipAssigned) {
    if(msg.prevOwner == self.owner) {
      self.items.set(self.itemsSize, sender());
      self.itemsSize = self.itemsSize + 1;
      return;
    }

    // let body: Cell = Transfer{
    //         queryId: msg.queryId,         
    //         newOwner: msg.prevOwner, 
    //         responseDestination: msg.prevOwner, 
    //         customPayload: null, 
    //         forwardAmount: 0,
    //         forwardPayload: emptySlice()
    //       }.toCell();

    let body: Cell = beginCell()
        .storeUint(0x5fcc3d14, 32)
        .storeUint(msg.queryId, 64)
        .storeAddress(msg.prevOwner)
        .storeAddress(msg.prevOwner)
        .storeInt(0, 1)
        .storeCoins(0)
        .storeSlice(beginCell().endCell().asSlice())
        .endCell();

    if(context().value < ton("2.1")){
      nativeSendMessage(beginCell()
        .storeInt(0, 6)
        // .storeBool(false)
        // .storeInt(0,3)
        .storeAddress(sender())
        // .storeCoins(0)
        // .storeUint(0, 1 + 4 + 4 + 64 + 32)
        // .storeBool(false)
        // .storeBool(true)
        .storeUint(1, 111)
        .storeRef(body)
        .endCell(), 64);

      //  send(SendParameters {
      //     to: sender(),
      //     value: 0,
      //     mode: 64,
      //     body: body
      //   });
        return;
    }   

    nativePrepareRandom();
    let index: Int = nativeRandomInterval(self.itemsSize);

    // let index: Int = random(0, self.itemsSize);
    let nft: Address = self.items.get(index)!!;

    if(index == self.itemsSize){
      nft = sender();
    }
    else
    {
      self.items.set(index, sender());
    }

    nativeReserve(ton("2.0"), 0);

    nativeSendMessage(beginCell()
        .storeInt(0, 6)
        // .storeBool(false)
        // .storeInt(0,3)
        .storeAddress(nft)
        // .storeCoins(0)
        // .storeUint(0, 1 + 4 + 4 + 64 + 32)
        // .storeBool(false)
        // .storeBool(true)
        .storeUint(1, 111)
        .storeRef(body)
        .endCell(), 128);

    //  send(SendParameters {
    //     to: nft,
    //     value: 0,
    //     mode: 128,
    //     body: body
    //     });
  }

  receive(msg: AdminWithdrawalProfit) {
    require(sender() == self.owner, "Insufficient privileges");
    nativeReserve(ton("0.1"), 0);


    nativeSendMessage(beginCell()
        .storeInt(1, 2)
        .storeBool(true)
        .storeInt(0,3)
        .storeAddress(self.owner)
        .storeCoins(0)
        .storeUint(0, 1 + 4 + 4 + 64 + 32)
        .storeBool(false)
        .storeBool(true)
        // .storeUint(1, 111)
        .storeRef(
          beginCell()
          .storeUint(4255419257, 32)
          .storeUint(msg.queryId, 64)
          .endCell()
        )
        .endCell(), 128);

    // send(SendParameters{
    //     to: self.owner,
    //     value: 0,
    //     mode: 128,
    //     body: AdminFetchProfit{
    //         queryId: msg.queryId
    //     }.toCell()
    //   });
  }

  receive(msg: AdminWithdrawalAllNFTs) {
    if(sender() != myAddress()){
      require(context().value >= (ton("1") + self.itemsSize * ton("0.08")), "Insufficient funds");
      require(sender() == self.owner, "Insufficient privileges");
    }

    acceptMessage();

    // let body: Slice = beginCell()
    //     .storeUint(0x5fcc3d14, 32)
    //     .storeUint(msg.queryId, 64)
    //     .storeAddress(self.owner)
    //     .storeAddress(self.owner)
    //     .storeInt(0, 1)
    //     .storeCoins(0)
    //     .storeSlice(beginCell().endCell().asSlice())
    //     .endCell().asSlice();
    // let body: Cell = Transfer{
    //         queryId: msg.queryId,            
    //         newOwner: self.owner, 
    //         responseDestination: self.owner, 
    //         customPayload: null, 
    //         forwardAmount: 0,
    //         forwardPayload: emptySlice()
    //       }.toCell();
        
    repeat(min(100, self.itemsSize)) {
      self.itemsSize = self.itemsSize - 1;

    nativeSendMessage(beginCell()
        .storeInt(1,2)
        .storeBool(true)
        .storeInt(0,3)
        .storeAddress(self.items.get(self.itemsSize)!!)
        .storeCoins(ton("0.02"))
        .storeUint(0, 1 + 4 + 4 + 64 + 32)
        .storeBool(false)
        .storeBool(false)
        .storeUint(0x5fcc3d14, 32)
        .storeUint(msg.queryId, 64)
        .storeAddress(self.owner)
        .storeAddress(self.owner)
        .storeInt(0, 1)
        .storeCoins(0)
        .storeSlice(beginCell().endCell().asSlice())
        // .storeUint(1, 106)
        // .storeRef(body)
        .endCell(), 0);
        
      //  send(SendParameters {
      //   to: self.items.get(self.itemsSize)!!,
      //   value: ton("0.02"),
      //   mode: 0,
      //   body: body
      //   });
    }

     if (self.itemsSize > 0) {
        nativeSendMessage(beginCell()
        .storeInt(1, 2)
        .storeBool(true)
        .storeInt(0,3)
        .storeAddress(myAddress())
        .storeCoins(0)
        .storeUint(0, 1 + 4 + 4 + 64 + 32)
        .storeBool(false)
        .storeBool(false)
        // .storeUint(1, 111)
        // .storeRef(beginCell()
        //   .storeUint(1664696863, 32)
        //   .storeUint(msg.queryId, 64)
        //   .endCell()
        // )
        .storeUint(1664696863, 32)
        .storeUint(msg.queryId, 64)
        .endCell(), 64);

            // send(SendParameters{
            //     to: myAddress(),
            //     value: 0,
            //     mode: 64,
            //     body: AdminWithdrawalAllNFTs{
            //       queryId:msg.queryId
            //     }.toCell()
            // });
        } else {
            self.items = null;
        }
  }

  get fun profit(): Int { 
    return myBalance() - ton("0.1");
  }
  
  get fun nfts(): map<Int as uint16, Address> { 
    return self.items;
  }
}