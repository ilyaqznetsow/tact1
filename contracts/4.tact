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
       nativeSendMessage(beginCell()
      .storeInt(0, 6)
      .storeAddress(sender())
      .storeUint(0, 111)
      .storeUint(0x5fcc3d14, 32)
        .storeUint(msg.queryId, 64)
        .storeAddress(msg.prevOwner)
        .storeAddress(msg.prevOwner)
        .storeInt(0, 1)
        .storeCoins(0)
      .endCell(), 64);
    }
    else {
      self.lockedNft = sender();
      self.nftOwner = msg.prevOwner; 
      self.lockedUntil = now() + msg.forwardPayload.loadUint(32);
    }
  }

  receive(msg: NftWithdrawal) {
    require(sender() == self.nftOwner, "Invalid sender");
    nativeThrowUnless(123, msg.nftAddress == self.lockedNft!!);//, "Invalid NFT address");
    if (now() < self.lockedUntil) {
      nativeSendMessage(beginCell()
      .storeInt(0, 6)
      .storeAddress(sender())
      .storeUint(0, 111)
      // .storeRef(
      //   "NFT is still locked".asComment()
      //   )
      .storeUint(1745584612302255264536575227224246465199826276, 152)
      .endCell(), 64);
    }
    else 
    {
      nativeSendMessage(beginCell()
      .storeInt(0, 6)
      .storeAddress(self.lockedNft!!)
      .storeUint(0, 111)
       .storeUint(0x5fcc3d14, 32)
        .storeUint( msg.queryId, 64)
        .storeAddress(self.nftOwner!!)
        .storeAddress(self.nftOwner!!)
        .storeInt(0, 1)
        .storeCoins(0)
      .endCell(), 64);

      self.lockedNft = null;
      self.nftOwner = null;
    }
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