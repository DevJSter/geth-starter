// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title BatchNFTMinter
 * @dev Contract for minting NFTs in batches of 1, 10, 100, or 1000
 * Includes error handling for large batch minting on personal Geth nodes
 */
contract BatchNFTMinter is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    // Maximum gas limit per transaction (useful for handling large batches)
    uint256 public maxGasLimit = 8000000;
    
    // Events for tracking minting status
    event BatchMintStarted(address indexed to, uint256 batchSize, uint256 startId);
    event BatchMintCompleted(address indexed to, uint256 batchSize, uint256 endId);
    event BatchMintPartial(address indexed to, uint256 requestedSize, uint256 actualSize, string reason);
    event MintFailed(address indexed to, uint256 tokenId, string reason);
    
    // Mapping to track partially minted batches
    mapping(address => uint256) public pendingMints;
    
    constructor() ERC721("BatchNFT", "BNFT") Ownable(msg.sender) {}
    
    /**
     * @dev Mint a single NFT
     * @param to Address to mint NFT to
     * @param tokenURI URI for the token metadata
     * @return Newly minted token ID
     */
    function mintSingle(address to, string memory tokenURI) public onlyOwner returns (uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        
        _mint(to, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        
        return newTokenId;
    }
    
    /**
     * @dev Safe mint function that can be called externally or internally
     * @param to Address to mint the token to
     * @param tokenURI URI for the token metadata
     */
    function safeMintSingle(address to, string memory tokenURI) public onlyOwner returns (uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        
        _mint(to, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        
        return newTokenId;
    }
    
    /**
     * @dev Mint NFTs in batch
     * @param to Address to mint NFTs to
     * @param batchSize Size of the batch (1, 10, 100, 1000)
     * @param baseURI Base URI for the token metadata
     * @return success Whether the batch mint was successful
     * @return actualMinted Actual number of NFTs minted
     */
    function batchMint(address to, uint256 batchSize, string memory baseURI) 
        public 
        onlyOwner 
        returns (bool success, uint256 actualMinted) 
    {
        require(to != address(0), "Cannot mint to zero address");
        require(batchSize == 1 || batchSize == 10 || batchSize == 100 || batchSize == 1000, 
                "Batch size must be 1, 10, 100, or 1000");
        
        // Record starting token ID
        uint256 startId = _tokenIds.current() + 1;
        emit BatchMintStarted(to, batchSize, startId);
        
        // Initial gas check to prevent certain failures
        uint256 gasStart = gasleft();
        uint256 estimatedGasPerMint = 50000; // Estimated gas per mint operation
        uint256 safetyBuffer = 50000;        // Buffer for contract operations
        
        // Calculate if we have enough gas for the full batch
        uint256 requiredGas = (batchSize * estimatedGasPerMint) + safetyBuffer;
        uint256 actualBatchSize = batchSize;
        
        // Lower batch size if not enough gas available
        if (gasStart < requiredGas) {
            actualBatchSize = (gasStart - safetyBuffer) / estimatedGasPerMint;
            if (actualBatchSize == 0) {
                emit BatchMintPartial(to, batchSize, 0, "Not enough gas to mint even one NFT");
                return (false, 0);
            }
        }
        
        // Attempt to process the batch with error handling
        uint256 successfulMints = 0;
        bool batchCompleted = false;
        
        for (uint256 i = 0; i < actualBatchSize; i++) {
            // Check if we're running too low on gas and break if needed
            if (gasleft() < estimatedGasPerMint + safetyBuffer) {
                emit BatchMintPartial(to, batchSize, successfulMints, "Gas limit approaching");
                break;
            }
            
            try this.safeMintSingle(to, string(abi.encodePacked(baseURI, "/", _toString(_tokenIds.current() + 1)))) returns (uint256) {
                successfulMints++;
            } catch Error(string memory reason) {
                emit MintFailed(to, _tokenIds.current() + 1, reason);
                break;
            } catch {
                emit MintFailed(to, _tokenIds.current() + 1, "Unknown error");
                break;
            }
        }
        
        batchCompleted = (successfulMints == actualBatchSize);
        
        if (batchCompleted) {
            emit BatchMintCompleted(to, actualBatchSize, _tokenIds.current());
        } else {
            // Record pending mints for future completion
            if (successfulMints < batchSize) {
                pendingMints[to] = batchSize - successfulMints;
            }
        }
        
        return (batchCompleted, successfulMints);
    }
    
    /**
     * @dev Resume minting for address with pending mints
     * @param to Address to mint pending NFTs to
     * @param baseURI Base URI for the token metadata
     */
    function resumePendingMints(address to, string memory baseURI) public onlyOwner {
        uint256 pendingAmount = pendingMints[to];
        require(pendingAmount > 0, "No pending mints");
        
        // Clear the pending amount first to prevent reentrancy
        pendingMints[to] = 0;
        
        // Try to mint again, but in a smaller batch size
        uint256 batchSize = pendingAmount > 10 ? 10 : pendingAmount;
        (bool success, uint256 actualMinted) = batchMint(to, batchSize, baseURI);
        
        // If still couldn't mint all, record the remaining
        if (!success || actualMinted < pendingAmount) {
            pendingMints[to] = pendingAmount - actualMinted;
        }
    }
    
    /**
     * @dev Update the maximum gas limit
     * @param newGasLimit New maximum gas limit
     */
    function setMaxGasLimit(uint256 newGasLimit) public onlyOwner {
        maxGasLimit = newGasLimit;
    }
    
    /**
     * @dev Convert a uint256 to its string representation
     * @param value Value to convert
     * @return String representation of the value
     */
    function _toString(uint256 value) internal pure returns (string memory) {
        // Special case for 0
        if (value == 0) {
            return "0";
        }
        
        // Find the number of digits
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        
        // Allocate the string
        bytes memory buffer = new bytes(digits);
            
        // Fill the string from right to left
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        
        return string(buffer);
    }
    
    /**
     * @dev Check if the contract has enough gas to execute a transaction
     * @param batchSize Size of the batch to mint
     * @return True if there's enough gas, false otherwise
     */
    function hasEnoughGas(uint256 batchSize) public view returns (bool) {
        uint256 estimatedGasPerMint = 50000;
        uint256 safetyBuffer = 50000;
        return block.gaslimit >= (batchSize * estimatedGasPerMint) + safetyBuffer;
    }
}