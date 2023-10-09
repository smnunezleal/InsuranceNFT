// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract InsuranceOracle is ChainlinkClient, Ownable {
    using Chainlink for Chainlink.Request;

    mapping(uint256 => bool) public policyClaimable;
    mapping(bytes32 => uint256) public requestToPolicy;

    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
    
    event PolicyUpdated(uint256 policyId, bool isClaimable);
    event ChainlinkRequested(bytes32 requestId);
    event ChainlinkFulfilled(bytes32 requestId);
    event ChainlinkFailed(bytes32 requestId);

    constructor(address _oracle, bytes32 _jobId, uint256 _fee) {
        setPublicChainlinkToken();
        oracle = _oracle;
        jobId = _jobId;
        fee = _fee;
    }
    
    function updatePolicyClaimable(uint256 _policyId, bool _isClaimable) external onlyOwner {
        policyClaimable[_policyId] = _isClaimable;
        emit PolicyUpdated(_policyId, _isClaimable);
    }
    
    function requestPolicyStatus(uint256 _policyId, string memory _url, string memory _path) external onlyOwner {
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        req.add("get", _url);
        req.add("path", _path);
        bytes32 requestId = sendChainlinkRequestTo(oracle, req, fee);
        
        requestToPolicy[requestId] = _policyId;
        emit ChainlinkRequested(requestId);
    }
    
    function fulfill(bytes32 _requestId, bool _isClaimable) external recordChainlinkFulfillment(_requestId) {
        uint256 policyId = requestToPolicy[_requestId];
        require(policyId != 0, "No policy found for request ID");
        
        policyClaimable[policyId] = _isClaimable;
        emit PolicyUpdated(policyId, _isClaimable);
        emit ChainlinkFulfilled(_requestId);
        
        delete requestToPolicy[_requestId]; // Clean up mapping
    }
    
    function cancelRequest(
        bytes32 _requestId,
        uint256 _payment,
        bytes4 _callbackFunctionId,
        uint256 _expiration
    ) external onlyOwner {
        cancelChainlinkRequest(_requestId, _payment, _callbackFunctionId, _expiration);
        emit ChainlinkFailed(_requestId);
        
        delete requestToPolicy[_requestId]; // Clean up mapping
    }
    
    function updateOracleDetails(address _oracle, bytes32 _jobId, uint256 _fee) external onlyOwner {
        oracle = _oracle;
        jobId = _jobId;
        fee = _fee;
    }
}
