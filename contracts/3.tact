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
    let allowed: Bool = false;
    let from: Address = sender();

    if(msg.from == self.owner){
      if(from == self.jAddressA){
        self.a = self.a + msg.amount;
      } else if(from == self.jAddressB){
        self.b = self.b + msg.amount;
      }
      return;
    }

    allowed = from == self.jAddressA || from == self.jAddressB;
    require(allowed, "Not allowed to add jettons");

      let amount_out: Int = 0;
      let amount_in: Int = msg.amount;
      let amount_left: Int = 0;
      let sendBack: Bool = false;
      //b = 2 a = 10 amount_in = 10
      if (from == self.jAddressA) {            
        amount_out = self.price(self.jAddressB) * amount_in;
        sendBack = self.b <= amount_out / self.decimal;
      }
        
      if (from == self.jAddressB) {   
        //message from b
        amount_out = self.price(self.jAddressA) * amount_in;
        sendBack = self.a <= amount_out / self.decimal;
      }


      if(sendBack){
        send(SendParameters{
          to: from,
          value: 0, 
          mode: SendRemainingValue, 
          bounce: false, 
          body: TokenTransfer {
            queryId: msg.queryId,
            amount: amount_in,
            destination: msg.from,
            responseDestination: myAddress(),
            customPayload: null,
            forwardTonAmount: ton("0.01"),
            forwardPayload: msg.forwardPayload
          }.toCell()
        });
        return;
      }
      else {            
        send(SendParameters{
          to: from,
          value: 0, 
          mode: SendRemainingValue, 
          bounce: false, 
          body: TokenTransfer {
            queryId: msg.queryId,
            amount: amount_out,
            destination: msg.from,
            responseDestination: myAddress(),
            customPayload: null,
            forwardTonAmount: ton("0.01"),
            forwardPayload: msg.forwardPayload
          }.toCell()
        });

        if (from == self.jAddressA) {
          self.a = self.a - amount_out;
          self.b = self.b + amount_in;
        } else {
          self.b = self.b - amount_out;
          self.a = self.a + amount_in;
        }
      }
  } 
  
  get fun price(jetton: Address): Int {
    require(jetton == self.jAddressA || jetton == self.jAddressB, "Not allowed to get price");

    if (jetton == self.jAddressA) {
      require(self.b > 0, "Not enough jettons A");
      return (self.a * self.decimal) / self.b;
    }
    
    if (jetton == self.jAddressB) {
      require(self.a > 0, "Not enough jettons B");
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