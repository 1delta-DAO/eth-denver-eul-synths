// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.19;

import {BalancerAdapter} from "./BalancerAdapter.sol";
import {BalancerSepoliaAddresses} from "../../test/balancer-adapter/BalancerSepoliaAddresses.sol";

contract BalancerAdapterSepolia is BalancerSepoliaAddresses, BalancerAdapter {
    constructor(
        address evc
    ) BalancerAdapter(CSP_FACTORY, BALANCER_VAULT, evc) {}
}
