// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import "../src/TaxToken.sol";
import "../src/TaxTokenFactory.sol";

contract Deploy is Script {

    // forge script script/Deploy.sol --rpc-url $TESTNET_RPC_URL \ 
    // --etherscan-api-key $SONICSCAN_API_KEY \
    // --verify -vvvv --slow --broadcast --interactives 1

    function run() external {
        
        vm.startBroadcast();

        TaxToken taxToken = new TaxToken();

        TaxTokenFactory taxTokenFactory = new TaxTokenFactory (
            address(taxToken),
            msg.sender,
            0
        );

        console.log("TaxToken deployed at: ", address(taxToken));
        console.log("TaxTokenFactory deployed at: ", address(taxTokenFactory));

        vm.stopBroadcast();
    }
}