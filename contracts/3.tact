import "@stdlib/deploy";

/*
  TASK 3 - DEX
  Create a simple jetton dex contract that trades one pair of jettons: A and B.
  The price of jettons depends on the amount of jettons that smart contract has.
  Therefore, the smart contract needs to keep track of how much jettons it has.
  
  Price for the jetton A in swap B->A should be calculated by formula "amountOfJettonAOnContract * decimal / amountOfJettonBOnContract".
  Decimals are only needed for price accuracy. It should be set as 1e9.
  So, if smart contract has 10 of jetton A and 2 of jetton B, then after sending 1 jetton B you should receive 5 of jettons A.

  Example formula for amountOfBJettonToSend in A->B swap will be
  (amountOfJettonAOnContract * decimal / amountOfJettonBOnContract) * amountOfTokenAToSwap / decimal

  If smart contract pool doesn't have enough jettons to trade,
  then it should send incoming jettons back to the user. For a clearer explanation,
  let's look at the example we described above (smart contract has 10 of jetton A and 2 of jetton B).
  If user will send 3 jettons B, smart contract should reject the message (because contract does not have 3 * 5 = 15 jettons A)
  and send 3 jettons B back to the user.

  If smart contract receives a different jetton (neither A nor B) then throw an error.

  Implement a getter that returns the number of jettons in the pool and
  one more to get the price of jetton A or jetton B.
  Getters' behavior with incorrect parameter (address other than that of jetton A or B)
  is undefined (there are no such tests).
  
  Note:
  Admin can add jettons A and B just by sending them to the smart contract (we need to add initial supply to the pool for it to be functional).
  To be exact: any jettons (A or B) received from the admin are "added". Admin can't swap.
*/


message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forwardPayload: Slice as remaining;
}

message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64; // should be 0
     amount: Int as coins; // should be amount of jettons to send
     destination: Address; // should be user address / TokenNotification.from
     responseDestination: Address?; // should be myAddress()
     customPayload: Cell?; // should be null
     forwardTonAmount: Int as coins; // should be ton("0.01")
     forwardPayload: Slice as remaining; // should be emptySlice()
}

contract Task3 with Deployable {
  owner: Address;
  aAmount: Int;
  bAmount: Int;
  jettonAddressA: Address;
  jettonAddressB: Address;
  decimal: Int;

  init(admin: Address, newJettonAddressA: Address, newJettonAddressB: Address) {
    self.owner = admin;
    self.jettonAddressA = newJettonAddressA;
    self.jettonAddressB = newJettonAddressB;
    self.aAmount = 0;
    self.bAmount = 0;
    self.decimal = 1000000000;
  }

  receive(msg: TokenNotification) {
    require(sender() == self.jettonAddressA || sender() == self.jettonAddressB, "Wrong jetton");

      if(sender() == self.jettonAddressA)
      {
        if(msg.from != self.owner)        
        {
          // self.swapAB(msg.amount, msg.from);
           let amountOut: Int = (self.bAmount * self.decimal) / self.aAmount * msg.amount / self.decimal;
            if (amountOut > self.bAmount)
              {
                // self.sendJetton(self.jettonAddressA, amountA, user);
                nativeSendMessage(beginCell()
                    .storeInt(1,2)
                    .storeBool(false)
                    .storeInt(0,3)
                    .storeAddress(self.jettonAddressA)
                    .storeCoins(0)
                    .storeUint(0, 1 + 4 + 4 + 64 + 32)
                    .storeBool(false)
                    .storeBool(true)
                    .storeRef(
                      beginCell()
                      .storeUint(0xf8a7ea5, 32)
                      .storeUint(0, 64)
                      .storeCoins(msg.amount)
                      .storeAddress(msg.from)
                      .storeAddress(myAddress())
                      .storeInt(0, 1)
                      .storeCoins(ton("0.01"))
                      .storeSlice(beginCell().endCell().asSlice())
                      .endCell()
                      )
                    .endCell(), 64);
                return;
              }

        // self.sendJetton(self.jettonAddressB, amountOut, user);
          nativeSendMessage(beginCell()
                .storeInt(1,2)
                .storeBool(false)
                .storeInt(0,3)
                .storeAddress(self.jettonAddressB)
                .storeCoins(0)
                .storeUint(0, 1 + 4 + 4 + 64 + 32)
                .storeBool(false)
                .storeBool(true)
                .storeRef(
                  beginCell()
                  .storeUint(0xf8a7ea5, 32)
                  .storeUint(0, 64)
                  .storeCoins(amountOut)
                  .storeAddress(msg.from)
                  .storeAddress(myAddress())
                  .storeInt(0, 1)
                  .storeCoins(ton("0.01"))
                  .storeSlice(beginCell().endCell().asSlice())
                  .endCell()
                  )
                .endCell(), 64);
          self.bAmount = self.bAmount - amountOut;
        }

        self.aAmount = self.aAmount + msg.amount;
      }
      else
      {
        if(msg.from != self.owner)
        {
          // self.swapBA(msg.amount, msg.from);
          let amountOut: Int = (self.aAmount * self.decimal) / self.bAmount * msg.amount / self.decimal;
          if (amountOut > self.aAmount)
            {
                // self.sendJetton(self.jettonAddressB, amountB, user);
                nativeSendMessage(beginCell()
                  .storeInt(1,2)
                  .storeBool(false)
                  .storeInt(0,3)
                  .storeAddress(self.jettonAddressB)
                  .storeCoins(0)
                  .storeUint(0, 1 + 4 + 4 + 64 + 32)
                  .storeBool(false)
                  .storeBool(true)
                  .storeRef(
                    beginCell()
                    .storeUint(0xf8a7ea5, 32)
                    .storeUint(0, 64)
                    .storeCoins(msg.amount)
                    .storeAddress(msg.from)
                    .storeAddress(myAddress())
                    .storeInt(0, 1)
                    .storeCoins(ton("0.01"))
                    .storeSlice(beginCell().endCell().asSlice())
                    .endCell()
                    )
                  .endCell(), 64);
                return;
            }

        // self.sendJetton(self.jettonAddressA, amountOut, user);

          nativeSendMessage(beginCell()
                .storeInt(1,2)
                .storeBool(false)
                .storeInt(0,3)
                .storeAddress(self.jettonAddressA)
                .storeCoins(0)
                .storeUint(0, 1 + 4 + 4 + 64 + 32)
                .storeBool(false)
                .storeBool(true)
                .storeRef(
                  beginCell()
                  .storeUint(0xf8a7ea5, 32)
                  .storeUint(0, 64)
                  .storeCoins(amountOut)
                  .storeAddress(msg.from)
                  .storeAddress(myAddress())
                  .storeInt(0, 1)
                  .storeCoins(ton("0.01"))
                  .storeSlice(beginCell().endCell().asSlice())
                  .endCell()
                  )
                .endCell(), 64);
          self.aAmount = self.aAmount - amountOut;
        }

        self.bAmount = self.bAmount + msg.amount;
      }
  }

  // fun sendJetton(to: Address, amount: Int, user: Address) {

  //   nativeSendMessage(beginCell()
  //     .storeInt(1,2)
  //     .storeBool(false)
  //     .storeInt(0,3)
  //     .storeAddress(to)
  //     .storeCoins(0)
  //     .storeUint(0, 1 + 4 + 4 + 64 + 32)
  //     .storeBool(false)
  //     .storeBool(true)
  //     .storeRef(
  //       beginCell()
  //       .storeUint(0xf8a7ea5, 32)
  //       .storeUint(0, 64)
  //       .storeCoins(amount)
  //       .storeAddress(user)
  //       .storeAddress(myAddress())
  //       .storeInt(0, 1)
  //       .storeCoins(ton("0.01"))
  //       .storeSlice(beginCell().endCell().asSlice())
  //       .endCell()
  //       )
  //     .endCell(), 64);
  //     // send(SendParameters{
  //     //       to: to,
  //     //       value: 0,
  //     //       mode: SendRemainingValue + SendIgnoreErrors, 
  //     //       body: TokenTransfer {
  //     //         queryId: 0,
  //     //         amount: amount,
  //     //         destination: user,
  //     //         responseDestination: myAddress(),
  //     //         customPayload: null,
  //     //         forwardTonAmount: ton("0.01"),
  //     //         forwardPayload: emptySlice()
  //     //       }.toCell()
  //     //     });
  // }

  // fun swapBA(amountB: Int, user: Address){
  //     let amountOut: Int = (self.aAmount * self.decimal) / self.bAmount * amountB / self.decimal;
  //     if (amountOut > self.aAmount)
  //       {
  //           // self.sendJetton(self.jettonAddressB, amountB, user);
  //            nativeSendMessage(beginCell()
  //             .storeInt(1,2)
  //             .storeBool(false)
  //             .storeInt(0,3)
  //             .storeAddress(self.jettonAddressB)
  //             .storeCoins(0)
  //             .storeUint(0, 1 + 4 + 4 + 64 + 32)
  //             .storeBool(false)
  //             .storeBool(true)
  //             .storeRef(
  //               beginCell()
  //               .storeUint(0xf8a7ea5, 32)
  //               .storeUint(0, 64)
  //               .storeCoins(amountB)
  //               .storeAddress(user)
  //               .storeAddress(myAddress())
  //               .storeInt(0, 1)
  //               .storeCoins(ton("0.01"))
  //               .storeSlice(beginCell().endCell().asSlice())
  //               .endCell()
  //               )
  //             .endCell(), 64);
  //           return;
  //       }

  //       // self.sendJetton(self.jettonAddressA, amountOut, user);

  //        nativeSendMessage(beginCell()
  //             .storeInt(1,2)
  //             .storeBool(false)
  //             .storeInt(0,3)
  //             .storeAddress(self.jettonAddressA)
  //             .storeCoins(0)
  //             .storeUint(0, 1 + 4 + 4 + 64 + 32)
  //             .storeBool(false)
  //             .storeBool(true)
  //             .storeRef(
  //               beginCell()
  //               .storeUint(0xf8a7ea5, 32)
  //               .storeUint(0, 64)
  //               .storeCoins(amountOut)
  //               .storeAddress(user)
  //               .storeAddress(myAddress())
  //               .storeInt(0, 1)
  //               .storeCoins(ton("0.01"))
  //               .storeSlice(beginCell().endCell().asSlice())
  //               .endCell()
  //               )
  //             .endCell(), 64);
  //       self.aAmount = self.aAmount - amountOut;
  //       self.bAmount = self.bAmount + amountB;
  // }

    // fun swapAB(amountA: Int, user: Address){
    //   let amountOut: Int = (self.bAmount * self.decimal) / self.aAmount * amountA / self.decimal;
    //   if (amountOut > self.bAmount)
    //     {
    //       // self.sendJetton(self.jettonAddressA, amountA, user);
    //        nativeSendMessage(beginCell()
    //           .storeInt(1,2)
    //           .storeBool(false)
    //           .storeInt(0,3)
    //           .storeAddress(self.jettonAddressA)
    //           .storeCoins(0)
    //           .storeUint(0, 1 + 4 + 4 + 64 + 32)
    //           .storeBool(false)
    //           .storeBool(true)
    //           .storeRef(
    //             beginCell()
    //             .storeUint(0xf8a7ea5, 32)
    //             .storeUint(0, 64)
    //             .storeCoins(amountA)
    //             .storeAddress(user)
    //             .storeAddress(myAddress())
    //             .storeInt(0, 1)
    //             .storeCoins(ton("0.01"))
    //             .storeSlice(beginCell().endCell().asSlice())
    //             .endCell()
    //             )
    //           .endCell(), 64);
    //       return;
    //     }

    //     // self.sendJetton(self.jettonAddressB, amountOut, user);
    //      nativeSendMessage(beginCell()
    //           .storeInt(1,2)
    //           .storeBool(false)
    //           .storeInt(0,3)
    //           .storeAddress(self.jettonAddressB)
    //           .storeCoins(0)
    //           .storeUint(0, 1 + 4 + 4 + 64 + 32)
    //           .storeBool(false)
    //           .storeBool(true)
    //           .storeRef(
    //             beginCell()
    //             .storeUint(0xf8a7ea5, 32)
    //             .storeUint(0, 64)
    //             .storeCoins(amountOut)
    //             .storeAddress(user)
    //             .storeAddress(myAddress())
    //             .storeInt(0, 1)
    //             .storeCoins(ton("0.01"))
    //             .storeSlice(beginCell().endCell().asSlice())
    //             .endCell()
    //             )
    //           .endCell(), 64);
    //     self.bAmount = self.bAmount - amountOut;
    //     self.aAmount = self.aAmount + amountA;
    // }
  
  get fun price(jetton: Address): Int {
    if (jetton == self.jettonAddressA) {
      return (self.bAmount * self.decimal) / self.aAmount;
    }
    else {
      return (self.aAmount * self.decimal) / self.bAmount;
    }
  }
  
  get fun balance(jetton: Address): Int { 
    if (jetton == self.jettonAddressA) {
      return self.aAmount;
    } 
    // if (jetton == self.jettonAddressB) {
    else 
    {
      return self.bAmount;
    }
  }
}