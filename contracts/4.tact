import "@stdlib/deploy";

/*
  TASK 4 - NFT locker
  Implement a smart contract that will lock NFT for a period of time specified by the owner.
  Smart conrtact should contain logic to process following messages and getters: 

  Messages: 
  * OwnershipAssigned
   - Recives nft + time (in a forwardPayload message as uint32) for which this nft will be locked + address of the sender of the nft (prevOwner).
   - If the smart contract already holds an nft then return the incoming nft back to the sender
  * NftWithdrawal
   - Request withdrawal of the locked nft
   - If sender is not the owner (that came from OwnershipAssigned as prevOwner address) then throw "Invalid sender" 
   - If time has not passed then send message back to the sender with the comment "NFT is still locked" according to the TON's "message with text comment" standard 
   - Otherwise (all good) send the locked nft back to the owner with all the remaining TON balance
   Note that the order of checks is important
   (in case: "sender is not the owner" and "time has not passed" at the same time, "Invalid sender" error takes priority)

  Getters:
  * time
   - get how much lock time is left
  * nft
   - get the address of the locked nft 
  * owner
   - get the owner of the locked nft (that came from OwnershipAssigned as prevOwner)
*/

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

message NftWithdrawal {
  queryId: Int as uint64;
  nftAddress: Address;
}

contract Task4 with Deployable {
  seed: Int as uint128;
  lockedUntil: Int;
  lockedNft: Address?;
  nftOwner: Address?;

  init(seed: Int) {
    self.seed = seed;
    self.lockedUntil = 0;
  }

  receive(msg: OwnershipAssigned) {    
    if (self.lockedNft != null) {
      self.sendTo(sender(), msg.prevOwner, msg.queryId);     
    }
    else {
      self.lockedNft = sender();
      self.nftOwner = msg.prevOwner; 
      self.lockedUntil = now() + msg.forwardPayload.loadUint(32);
    }
  }

  receive(msg: NftWithdrawal) {
    require(sender() == self.nftOwner, "Invalid sender");
    require(msg.nftAddress == self.lockedNft!!, "Invalid NFT address");

    if (now() < self.lockedUntil) {
      nativeSendMessage(beginCell()
      .storeInt(1,2)
      .storeBool(true)
      .storeInt(0,3)
      .storeAddress(sender())
      .storeCoins(0)
      .storeUint(0, 1 + 4 + 4 + 64 + 32)
      .storeBool(false)
      .storeBool(true)
      .storeRef(
        "NFT is still locked".asComment()
        )
      .endCell(), 64);
      
      // self.reply("NFT is still locked".asComment());
    }
    else 
    {
      self.sendTo(self.lockedNft!!, self.nftOwner!!, msg.queryId);

      self.lockedNft = null;
      self.nftOwner = null;
    }
  }

  inline fun sendTo(to: Address, owner: Address, queryId: Int) {
     nativeSendMessage(beginCell()
      .storeInt(1,2)
      .storeBool(false)
      .storeInt(0,3)
      .storeAddress(to)
      .storeCoins(0)
      .storeUint(0, 1 + 4 + 4 + 64 + 32)
      .storeBool(false)
      .storeBool(true)
      .storeRef(
        beginCell()
        .storeUint(0x5fcc3d14, 32)
        .storeUint(queryId, 64)
        .storeAddress(owner)
        .storeAddress(owner)
        .storeInt(0, 1)
        .storeCoins(0)
        .storeSlice(beginCell().endCell().asSlice())
        .endCell()
        )
      .endCell(), 64);

    // send(SendParameters {
    //       to: to,
    //       value: 0,
    //       mode: SendRemainingValue,
    //       body: Transfer{
    //           queryId: queryId,            
    //           newOwner: owner,
    //           responseDestination: owner, 
    //           customPayload: null, 
    //           forwardAmount: 0,
    //           forwardPayload: emptySlice()
    //         }.toCell()
    //     });
  }

  get fun time(): Int {
    return self.lockedUntil - now();
  }

  get fun nft(): Address? {
    return self.lockedNft;
  }

  get fun owner(): Address? {
    return self.nftOwner;
  }
}