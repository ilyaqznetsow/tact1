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
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address?;
    customPayload: Cell?;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

contract Task3 with Deployable {
  owner: Address;
  a: Int;
  b: Int;
  jAddressA: Address;
  jAddressB: Address;
  decimal: Int;

   init(admin: Address, newJAddressA: Address, newJAddressB: Address) {
    self.owner = admin;
    self.jAddressA = newJAddressA;
    self.jAddressB = newJAddressB;
    self.a = 0;
    self.b = 0;
    self.decimal = 1000000000;
  }

  receive(msg: TokenNotification) { 
      let valueToSend: Int = 0;
      let sendBack: Bool = false;
      let jAddress: Address = msg.from;

        if (msg.from == self.jAddressA) {
            self.a = self.a + msg.amount;
            
            valueToSend = self.price(self.jAddressA) * msg.amount / self.decimal;
            sendBack = self.b < valueToSend;
        } else if (msg.from == self.jAddressB) {
            self.b = self.b + msg.amount;
            
            valueToSend = self.price(self.jAddressB) * msg.amount / self.decimal;
            sendBack = self.a < valueToSend;
        } else {
          throw(132);
        }


      if(sendBack){
        send(SendParameters{
          to: context().sender,
          value: 0, 
          mode: SendRemainingValue + SendIgnoreErrors, 
          bounce: false, 
          body: TokenTransfer {
            queryId: msg.queryId,
            amount: msg.amount,
            destination: msg.from,
            responseDestination: null,
            customPayload: null,
            forwardTonAmount: 0,
            forwardPayload: msg.forwardPayload
          }.toCell()
        });
        return;
      }
      
      if(context().sender != self.owner){
      
        send(SendParameters{
          to: jAddress,
          value: 0, 
          mode: SendRemainingValue + SendIgnoreErrors, 
          bounce: false, 
          body: TokenTransfer {
            queryId: msg.queryId,
            amount: valueToSend,
            destination: msg.from,
            responseDestination: context().sender,
            customPayload: null,
            forwardTonAmount: 0,
            forwardPayload: msg.forwardPayload
          }.toCell()
        });
      }
  } 
  
  get fun price(jetton: Address): Int { 
    if (jetton == self.jAddressA) {
      require(self.a > 0, "Not enough jettons A");
      return (self.a * self.decimal) / self.b;
    }
    
    if (jetton == self.jAddressB) {
      require(self.b > 0, "Not enough jettons B");
      return (self.b * self.decimal) / self.a;
    }
    return 0;
  }
  
  get fun balance(jetton: Address): Int { 
    if (jetton == self.jAddressA) {
      return self.a * self.decimal;
    } 
    if (jetton == self.jAddressB) {
      return self.b * self.decimal;
    }
     return 0;
  }
}