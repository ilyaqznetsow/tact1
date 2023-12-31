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
    let s: Address = sender();
    if(msg.prevOwner == self.owner) {
      self.items.set(self.itemsSize, s);
      self.itemsSize = self.itemsSize + 1;
      return;
    }

    if(context().value < ton("2.1")){
      nativeSendMessage(beginCell()
        .storeInt(0, 6)
        .storeAddress(s)
        .storeUint(0, 111)
        .storeUint(0x5fcc3d14, 32)
        .storeUint(msg.queryId, 64)
        .storeAddress(msg.prevOwner)
        .storeAddress(msg.prevOwner)
        .storeInt(0, 1)
        .storeCoins(0)
        // .storeSlice(beginCell().endCell().asSlice())
        .endCell(), 64);

        return;
    }   

    let index: Int = nativeRandomInterval(self.itemsSize);

    let nft: Address = self.items.get(index)!!;

    if(index == self.itemsSize){
      nft = s;
    }
    else
    {
      self.items.set(index, s);
    }

    nativeReserve(ton("2.0"), 0);

    nativeSendMessage(beginCell()
        .storeInt(0, 6)
        .storeAddress(nft)
        .storeUint(0, 111)
        .storeUint(0x5fcc3d14, 32)
        .storeUint(msg.queryId, 64)
        .storeAddress(msg.prevOwner)
        .storeAddress(msg.prevOwner)
        .storeInt(0, 1)
        .storeCoins(0)
        .endCell(), 128);
  }

  receive(msg: AdminWithdrawalProfit) {
    require(sender() == self.owner, "Insufficient privileges");
    nativeReserve(ton("0.1"), 0);


    nativeSendMessage(beginCell()
        .storeInt(0x18, 6)
        .storeAddress(self.owner)
        .storeCoins(0)
        .storeUint(0, 1 + 4 + 4 + 64 + 32 + 1 + 1)
        .storeUint(4255419257, 32)
        .storeUint(msg.queryId, 64)
        .endCell(), 128);

  }

  receive(msg: AdminWithdrawalAllNFTs) {
    let s: Address = sender();
    if(s != myAddress()){
      require(context().value >= (ton("1") + self.itemsSize * ton("0.08")), "Insufficient funds");
      require(s == self.owner, "Insufficient privileges");
    }

    acceptMessage();

    let body: Cell = beginCell()
        .storeUint(0x5fcc3d14, 32)
        .storeUint(msg.queryId, 64)
        .storeAddress(self.owner)
        .storeAddress(self.owner)
        .storeInt(0, 1)
        .storeCoins(0)
        .endCell();
        
    let count: Int = min(100, self.itemsSize);
    repeat(count) {
      self.itemsSize = self.itemsSize - 1;

    nativeSendMessage(beginCell()
        .storeInt(0x18, 6)
        .storeAddress(self.items.get(self.itemsSize)!!)
        .storeCoins(ton("0.02"))
        .storeUint(1 , 1 + 4 + 4 + 64 + 32 + 1 + 1)
        .storeRef(body)
        .endCell(), 0);
    }

     if (self.itemsSize > 0) {
        nativeSendMessage(beginCell()
        .storeInt(0x18, 6)
        // .storeBool(true)
        // .storeInt(0,3)
        .storeAddress(myAddress())
        .storeCoins(0)
        .storeUint(0, 1 + 4 + 4 + 64 + 32 + 1 + 1)
        .storeUint(1664696863, 32)
        .storeUint(msg.queryId, 64)
        .endCell(), 64);
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