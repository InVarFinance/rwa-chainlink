// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Chainlink } from "chainlink-brownie-contracts/Chainlink.sol";
import { ChainlinkClient } from "chainlink-brownie-contracts/ChainlinkClient.sol";
import { ConfirmedOwner } from "chainlink-brownie-contracts/ConfirmedOwner.sol";
import { LinkTokenInterface } from "chainlink-brownie-contracts/interfaces/LinkTokenInterface.sol";

error ErrorResponse();

contract ApiClient is ChainlinkClient, ConfirmedOwner {
    using Chainlink for Chainlink.Request;

    // Goerli Link Token
    address constant LINK = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;
    // v0.6 Oracle.sol
    address constant ORACLE = 0x9D78116FE93149117A2d41C68d0C538182dB95d7;

    uint256 public assetValue;
    // need to delete "-" from external jobId
    string private jobId;
    uint256 private fee;
    string private api;

    constructor(string memory _jobId, string memory _api) ConfirmedOwner(msg.sender) {
        setChainlinkToken(LINK);
        setChainlinkOracle(ORACLE);
        fee = (1 * LINK_DIVISIBILITY) / 10;
        jobId = _jobId;
        api = _api;
    }

    function setApi(string memory _api) external onlyOwner {
        api = _api;        
    }

    function requestAssetData() external returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(
            stringToBytes32(jobId),
            address(this),
            this.fulfillAssetData.selector
        );

        // Set the URL to perform the GET request on
        req.add("get", api);

        // response format:
        // {rwaValue: xxxxxx}
        req.add("path", "rwaValue");

        return sendChainlinkRequest(req, fee);
    }

    function fulfillAssetData(bytes32 _requestId, uint256 _assetValue) external recordChainlinkFulfillment(_requestId) {
        if (_assetValue < 1) revert ErrorResponse();
        assetValue = _assetValue;
    }

    function withdrawLINK() external onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        uint256 balance = link.balanceOf(address(this));
        link.transfer(owner(), balance);
    }

    function stringToBytes32(
        string memory source
    ) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            // solhint-disable-line no-inline-assembly
            result := mload(add(source, 32))
        }
    }
}
