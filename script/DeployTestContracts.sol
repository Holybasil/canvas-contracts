// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import { SchemaRegistry, ISchemaRegistry } from "@eas/contracts/SchemaRegistry.sol";
import { EAS } from "@eas/contracts/EAS.sol";

import { AttesterProxy } from "../src/AttesterProxy.sol";
import { ScrollBadgeResolver } from "../src/resolver/ScrollBadgeResolver.sol";
import { ScrollBadgeSimple } from "../src/badge/examples/ScrollBadgeSimple.sol";
import { ProfileRegistry } from "../src/profile/ProfileRegistry.sol";
import { Profile } from "../src/profile/Profile.sol";

contract DeployTestContracts is Script {
    uint256 DEPLOYER_PRIVATE_KEY = vm.envUint("DEPLOYER_PRIVATE_KEY");
    address ATTESTER_ADDRESS = vm.envAddress("ATTESTER_ADDRESS");

    function run() external {
        vm.startBroadcast(DEPLOYER_PRIVATE_KEY);

        // deploy EAS
        SchemaRegistry schemaRegistry = new SchemaRegistry();
        EAS eas = new EAS(schemaRegistry);

        // deploy Scroll badge resolver
        ScrollBadgeResolver resolver = new ScrollBadgeResolver(address(eas));
        bytes32 schema = resolver.schema();

        // deploy test badge
        ScrollBadgeSimple badge = new ScrollBadgeSimple(address(resolver), "name", "symbol", "uri");
        AttesterProxy proxy = new AttesterProxy(eas);

        // set permissions
        resolver.toggleBadge(address(badge), true);
        badge.toggleAttester(address(proxy), true);
        proxy.toggleAttester(ATTESTER_ADDRESS, true);

        // deploy profile implementation and registry
        Profile profileImpl = new Profile(address(resolver));
        ProfileRegistry profileRegistry = new ProfileRegistry(address(profileImpl));

        // log addresses
        logAddress("EAS_REGISTRY_CONTRACT_ADDRESS", address(schemaRegistry));
        logAddress("EAS_MAIN_CONTRACT_ADDRESS", address(eas));
        logAddress("SCROLL_BADGE_RESOLVER_CONTRACT_ADDRESS", address(resolver));
        logBytes32("SCROLL_BADGE_SCHEMA_UID", schema);
        logAddress("SIMPLE_BADGE_CONTRACT_ADDRESS", address(badge));
        logAddress("SIMPLE_BADGE_ATTESTER_PROXY_CONTRACT_ADDRESS", address(proxy));
        logAddress("SCROLL_PROFILE_IMPLEMENTATION_CONTRACT_ADDRESS", address(profileImpl));
        logAddress("SCROLL_PROFILE_REGISTRY_CONTRACT_ADDRESS", address(profileRegistry));

        vm.stopBroadcast();
    }

    function logAddress(string memory name, address addr) internal view {
        console.log(string(abi.encodePacked(name, "=", vm.toString(address(addr)))));
    }

    function logBytes32(string memory name, bytes32 data) internal view {
        console.log(string(abi.encodePacked(name, "=", vm.toString(data))));
    }
}
