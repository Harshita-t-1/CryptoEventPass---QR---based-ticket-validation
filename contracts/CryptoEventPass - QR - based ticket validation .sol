// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title CryptoEventPass - QR-based Ticket Validation
 * @notice A blockchain-based smart contract for issuing and verifying event tickets using unique QR hashes.
 * @dev Each ticket is uniquely bound to a user's address and can only be validated once.
 */
contract CryptoEventPass {
    // Structure to represent a ticket
    struct Ticket {
        address owner;
        string qrHash;       // Hashed QR code (could be IPFS hash or encoded string)
        bool isValid;
        uint256 issuedAt;
        uint256 eventId;
    }

    // Mapping from ticket ID to Ticket details
    mapping(uint256 => Ticket) private tickets;

    // Event organizer (contract admin)
    address public organizer;
    uint256 private nextTicketId;

    // Events
    event TicketIssued(uint256 indexed ticketId, address indexed owner, uint256 eventId, string qrHash);
    event TicketValidated(uint256 indexed ticketId, address indexed validator);
    event TicketRevoked(uint256 indexed ticketId, address indexed by);

    // Modifiers
    modifier onlyOrganizer() {
        require(msg.sender == organizer, "Access denied: Organizer only");
        _;
    }

    modifier ticketExists(uint256 _ticketId) {
        require(tickets[_ticketId].owner != address(0), "Ticket does not exist");
        _;
    }

    /**
     * @dev Constructor sets the deployer as the event organizer.
     */
    constructor() {
        organizer = msg.sender;
        nextTicketId = 1;
    }

    /**
     * @notice Issue a new event ticket to a user.
     * @param _to Address of the ticket holder.
     * @param _qrHash Encrypted or hashed QR code string.
     * @param _eventId Unique identifier for the event.
     * @return ticketId The unique ID of the issued ticket.
     */
    function issueTicket(
        address _to,
        string calldata _qrHash,
        uint256 _eventId
    ) external onlyOrganizer returns (uint256 ticketId) {
        require(_to != address(0), "Invalid recipient address");
        require(bytes(_qrHash).length > 0, "QR hash required");

        ticketId = nextTicketId++;
        tickets[ticketId] = Ticket({
            owner: _to,
            qrHash: _qrHash,
            isValid: true,
            issuedAt: block.timestamp,
            eventId: _eventId
        });

        emit TicketIssued(ticketId, _to, _eventId, _qrHash);
    }

    /**
     * @notice Validate a ticket using its ID and QR hash.
     * @param _ticketId The ticket ID to validate.
     * @param _qrHash The hashed QR code to match.
     * @return success Boolean indicating if the ticket was successfully validated.
     */
    function validateTicket(uint256 _ticketId, string calldata _qrHash)
        external
        ticketExists(_ticketId)
        returns (bool success)
    {
        Ticket storage t = tickets[_ticketId];
        require(t.isValid, "Ticket already used or revoked");
        require(
            keccak256(abi.encodePacked(t.qrHash)) == keccak256(abi.encodePacked(_qrHash)),
            "Invalid QR hash"
        );

        t.isValid = false; // Mark as used
        emit TicketValidated(_ticketId, msg.sender);
        return true;
    }

    /**
     * @notice Revoke a ticket (e.g., due to fraud or event cancellation).
     * @param _ticketId The ticket ID to revoke.
     */
    function revokeTicket(uint256 _ticketId)
        external
        onlyOrganizer
        ticketExists(_ticketId)
    {
        Ticket storage t = tickets[_ticketId];
        require(t.isValid, "Ticket already invalid");
        t.isValid = false;
        emit TicketRevoked(_ticketId, msg.sender);
    }

    /**
     * @notice Get details of a specific ticket.
     * @param _ticketId The ID of the ticket.
     * @return owner The owner address.
     * @return qrHash The QR hash string.
     * @return isValid Ticket validity status.
     * @return issuedAt Timestamp of issuance.
     * @return eventId The event identifier.
     */
    function getTicket(uint256 _ticketId)
        external
        view
        ticketExists(_ticketId)
        returns (
            address owner,
            string memory qrHash,
            bool isValid,
            uint256 issuedAt,
            uint256 eventId
        )
    {
        Ticket memory t = tickets[_ticketId];
        return (t.owner, t.qrHash, t.isValid, t.issuedAt, t.eventId);
    }
}

