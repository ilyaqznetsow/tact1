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
  adminProfit: Int as coins = ton("2.0");
  requiredSwapFee: Int as coins = ton("2.1");
  requiredStorageFee: Int as coins = ton("0.1");
  nftWithdrawalFee: Int as coins = ton("0.08");
  minimumTonValue: Int as coins = ton("1");
  nftSendFee: Int as coins = ton("0.02");
  items: map<Int as uint16, Address>;
  itemsSize: Int as uint16 = 0;

  init(seed: Int, owner: Address) {
    self.owner = owner;
    self.seed = seed; // needed to deploy multiple smart contracts copies from one admin address
  }

  receive(msg: OwnershipAssigned) {
    let ctx: Context = context();
    if(msg.prevOwner == self.owner) {
      self.items.set(self.itemsSize, ctx.sender);
      self.itemsSize = self.itemsSize + 1;
      return;
    }

    if(ctx.value < self.requiredSwapFee){
       send(SendParameters {
        to: ctx.sender,
        value: 0,
        mode: SendRemainingValue,
        body: Transfer{
            queryId: msg.queryId,         
            newOwner: msg.prevOwner, 
            responseDestination: msg.prevOwner, 
            customPayload: null, 
            forwardAmount: 0,
            forwardPayload: emptySlice()
          }.toCell()
        });
        return;
    }   

    let index: Int = random(0, self.itemsSize);
    let nft: Address = ctx.sender;

    if(index == self.itemsSize){
      nft = ctx.sender;
    }
    else{
      nft = self.items.get(index)!!;
    }

      self.items.set(index, ctx.sender);

     send(SendParameters {
        to: nft,
        value: ctx.value - self.adminProfit,
        mode: 0,
        body: Transfer{
            queryId: msg.queryId,         
            newOwner: msg.prevOwner, 
            responseDestination: msg.prevOwner, 
            customPayload: null, 
            forwardAmount: 0,
            forwardPayload: msg.forwardPayload
          }.toCell()
        });

  }

  receive(msg: AdminWithdrawalProfit) {

    let ctx: Context = context();
    require(ctx.sender == self.owner, "Insufficient privileges");
    nativeReserve(self.requiredStorageFee, 0);

    send(SendParameters{
        to: self.owner,
        value: 0,
        mode: 128,
        body: AdminFetchProfit{
            queryId: msg.queryId
        }.toCell()
      });
  }

  receive(msg: AdminWithdrawalAllNFTs) {
    let ctx: Context = context();
    let requiredTons: Int = self.minimumTonValue + self.itemsSize * self.nftWithdrawalFee;

    if(ctx.sender != myAddress()){
      require(ctx.value >= requiredTons, "Insufficient funds");
      require(ctx.sender == self.owner, "Insufficient privileges");
    }

    acceptMessage();

    repeat(min(100, self.itemsSize)) {
      self.itemsSize = self.itemsSize - 1;
       send(SendParameters {
        to: self.items.get(self.itemsSize)!!,
        value: self.nftSendFee,
        mode: 0,
        body: Transfer{
            queryId: msg.queryId,            
            newOwner: self.owner, 
            responseDestination: self.owner, 
            customPayload: null, 
            forwardAmount: 0,
            forwardPayload: emptySlice()
          }.toCell()
        });
    }

     if (self.itemsSize > 0) {
            send(SendParameters{
                to: myAddress(),
                value: 0,
                mode: 64,
                body: AdminWithdrawalAllNFTs{
                  queryId:msg.queryId
                }.toCell()
            });
        } else {
            self.items = emptyMap();
        }
  }

  get fun profit(): Int { 
    return myBalance() - self.requiredStorageFee;
  }
  
  get fun nfts(): map<Int as uint16, Address> { 

    return self.items;
  }
}