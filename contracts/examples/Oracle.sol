pragma solidity ^0.5.8;
import "../platform/dispatch/DispatchInterface.sol";
import "../platform/registry/RegistryInterface.sol";
import "../lib/ownership/ZapCoordinatorInterface.sol";

contract Oracle {
    event RecievedQuery(string query, bytes32 endpoint, bytes32[] params);


    DispatchInterface public dispatch;
    RegistryInterface public registry;

    address public dispatchAddress;
    address public registryAddress;
    ZapCoordinatorInterface public coordinator;

    bytes32 public spec1 = "OnChainEndpointMoin";
    int256[] curve1 = [1,1,1000];

    constructor(address _zapCoor) public {
        coordinator = ZapCoordinatorInterface(_zapCoor);
        dispatchAddress = coordinator.getContract("DISPATCH");
        registryAddress = coordinator.getContract("REGISTRY");
        dispatch = DispatchInterface(dispatchAddress);
        registry = RegistryInterface(registryAddress);
        // initialize in registry
        bytes32 title = "MoinOracle";

        registry.initiateProvider(12345, title);
        registry.initiateProviderCurve(spec1, curve1, address(0));
    }

    // middleware function for handling queries
    function receive(uint256 id, string calldata userQuery, bytes32 endpoint, bytes32[] calldata endpointParams, bool onchainSubscriber) external {
        emit RecievedQuery(userQuery, endpoint, endpointParams);
        endpoint1(id);
    }

    function endpoint1(uint256 id) public {
        dispatch.respond1(id, "Onchain Answer Moin");
        // dispatch.respond2(id, "String1","String2");
        // dispatch.respond3(id, "String1","String2","String3");
        // dispatch.respond4(id, "String1","String2","String3","String4");

    }



}