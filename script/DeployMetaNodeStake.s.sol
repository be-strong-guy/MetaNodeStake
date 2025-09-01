// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MetaNodeToken.sol";
import "../src/MetaNodeStake.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployMetaNodeStake is Script {
    // 自定义参数
    uint256 constant START_BLOCK_OFFSET = 10;
    uint256 constant END_BLOCK_OFFSET   = 1000;
    uint256 constant REWARD_PER_BLOCK   = 1 ether;

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer    = vm.addr(deployerKey);

        vm.startBroadcast(deployerKey);

        // 1️ 部署奖励代币
        MetaNodeToken rewardToken = new MetaNodeToken();
        console.log("MetaNodeToken:", address(rewardToken));

        // 2️ 部署实现合约
        MetaNodeStake impl = new MetaNodeStake();
        console.log("MetaNodeStakeImpl:", address(impl));

        // 3️ 组装初始化参数
        uint256 startBlock = block.number + START_BLOCK_OFFSET;
        uint256 endBlock   = block.number + END_BLOCK_OFFSET;

        bytes memory initData = abi.encodeWithSelector(
            MetaNodeStake.initialize.selector,
            address(rewardToken), // IERC20 _MetaNode
            startBlock,
            endBlock,
            REWARD_PER_BLOCK
        );

        // 4️ 部署代理
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        MetaNodeStake stake = MetaNodeStake(address(proxy));
        console.log("MetaNodeStake Proxy:", address(stake));

        // 5️ 预置奖励：把 1000 万 token 全部转给质押合约
        uint256 rewardAmount = 10_000_000 ether;
        rewardToken.transfer(address(stake), rewardAmount);
        console.log("Reward pre-loaded:", rewardAmount);


        vm.stopBroadcast();
    }
}