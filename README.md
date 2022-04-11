# Open Edition Extension with Day & Night Mechanic

Open Edition Extension w/Day &amp; Night Mechanic for the Manifold Creator Core

To implement, you need to follow these steps:

1. Create a creator core contract via studio.manifold.xyz
2. Deploy this custom contract extension, adjusted for your drop
3. Make sure when you deploy that '_creator' is set to the address of your core contract
4. Once deployed, take the contract address of your extension and register it with your core contract by calling `registerExtension`

Now you can integrate the Open Edition Extension with your dapp. The tokens will mint from your creater core contract, but will follow the logic of this contract extension. 

---
**Sample Creator Core Contract**
* https://etherscan.io/address/0x6913233ada65330adf01f24f715dffcc60497cc8 (FirstDayOut Creator Core)

**Sample Contract Extension**
* https://etherscan.io/address/0x5a2bf870d4c7a94e15d27ccc192b9041920ea8c9 (FirstDayOut Open Edition Extension)

**Sample Dapp**
* https://firstdayout.driftershoots.com

---
**Thank you**
- @yungwknd for the initial seed code and review.
- @pepperonick for the dapp development
- @jeffreyraefan for the dapp design
