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
     if (msg.sender == self.admin) {
            // Ensure there are enough funds in the contract to refund
            require(self.balance >= msg.amount, 101, "Insufficient balance for refund");
            
            // Transfer the TONs back to the specified sender
            send(SendParameters{
                to: msg.sender,
                value: msg.amount,
                mode: SendModeOrdinary
            });
        }
  }

  receive(msg: Slice) {
    // Check if the received message includes a positive amount of TONs
        if (msg.amount > 0) {
            // Forward the TONs to the admin contract
            send(SendParameters{
                to: self.admin,
                value: msg.amount,
                mode: SendModeOrdinary,
                body: msg.message
            });
        }
  }
}
