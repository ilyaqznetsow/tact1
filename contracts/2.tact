import "@stdlib/deploy";

/*
  TASK 2 - Proxy 
  Create a contract that forwards all received TONs
  to the admin contract (whose address is set in init_store).
  Message from this proxy contract to the admin contract should contain:
    - Address of user who sent original message (should be stored in the outcoming body's data/bits)
    - Original message that proxy smart contract received from user (should be stored in the outcoming body's first ref)
  Also, if admin contract decides to reject message (if it sends to the proxy "Refund" message with opcode=0x44),
  proxy contract needs to forward all TONs (attached to Refund message) back to the user.
  User address will be provided in Refund message body as "sender".
  In refund transaction, it is important to have a check that the refund message came from the admin address
*/

message(0x44) Refund {
  queryId: Int as uint64;
  sender: Address;
}

contract Task2 with Deployable {
  admin: Address;

  init(admin: Address) {
    self.admin = admin;
  }
  
  receive(msg: Refund) {
    // Handle refund request from the admin contract
    require(msg.sender == self.admin, 101, "Unauthorized sender");
    
    // Calculate the attached deposit (TONs) for the refund
    let refundAmount = msg.value;

    // Ensure there are enough funds in the contract to refund
    require(self.balance >= refundAmount, 102, "Insufficient balance for refund");

    // Transfer the TONs back to the user specified in the Refund message
    transfer(refundAmount, msg.sender);
  }

  receive(msg: Slice) {
    // Handle incoming TON transfer
    if msg.value > 0 {
      // Forward received TONs to the admin contract
      transfer(self.balance, self.admin);
      
      // Store the user's address in the outgoing body's data/bits
      msg.body.with(sender: msg.sender);

      // Store the original message in the outgoing body's first ref
      msg.ref(0).store(msg.data);

      // Forward the message to the admin contract
      send_raw_message(self.admin, msg.value, msg);

      // Terminate the current contract execution
      tvm.exit();
    }
  }
}
