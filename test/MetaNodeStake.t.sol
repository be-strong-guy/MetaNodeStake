// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MetaNodeToken.sol";
import "../src/MetaNodeStake.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// 简单 ERC20 用于第二个池子
contract FakeERC20 is ERC20 {
    constructor() ERC20("Fake","FAKE") {}
    function mint(address to,uint256 amt) external { _mint(to,amt); }
}

contract MetaNodeStakeTest is Test {
    MetaNodeStake stake;
    MetaNodeToken reward;
    FakeERC20 stToken;
    address alice = address(0x1234);

    function setUp() public {
        reward   = new MetaNodeToken();
        stToken  = new FakeERC20();

        // 部署实现 + 代理
        MetaNodeStake impl = new MetaNodeStake();
        bytes memory init = abi.encodeWithSelector(
            MetaNodeStake.initialize.selector,
            address(reward),
            block.number + 100,
            block.number + 1000,
            10 ether
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), init);
        stake = MetaNodeStake(address(proxy));

        // 预置奖励
        reward.mint(address(stake), 1_000_000 ether);
    }

    /* 1. 第一个池必须是 ETH，第二个池才是 ERC20 */
    function testAddPool() public {
        // 先加 ETH 池（0x0）
        stake.addPool(address(0), 100, 0, 10, false); // pid = 0
        // 再加 ERC20 池
        stake.addPool(address(stToken), 100, 1 ether, 10, false);
        assertEq(stake.poolLength(), 2);
    }

    /* 2. 用 ERC20 池（pid = 1）做其余测试 */
    function testDeposit() public {
        testAddPool(); // 已创建 pid = 1
        stToken.mint(alice, 1000 ether);
        vm.startPrank(alice);
        stToken.approve(address(stake), 1000 ether);
        stake.deposit(1, 500 ether);
        assertEq(stake.stakingBalance(1, alice), 500 ether);
        vm.stopPrank();
    }

    function testUnstakeWithdraw() public {
        testDeposit();
        vm.startPrank(alice);
        stake.unstake(1, 200 ether);
        vm.roll(block.number + 11);
        stake.withdraw(1);
        assertEq(stake.stakingBalance(1, alice), 300 ether);
        vm.stopPrank();
    }

    function testClaim() public {
        testDeposit();
        vm.roll(block.number + 200);
        vm.prank(alice);
        stake.claim(1);
        assertGt(reward.balanceOf(alice), 0);
    }

    function testRole() public {
        vm.prank(alice);
        vm.expectRevert();
        stake.addPool(address(0x9999), 100, 1 ether, 10, false);
    }
}