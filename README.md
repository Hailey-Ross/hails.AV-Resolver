# hails.AV-resolver

An LSL utility script for Second Life that resolves avatar information by UUID or by name, and returns:

- Display Name (if available)
- Legacy Name
- Account Age (in days)
- UUID
- A clickable About link (secondlife:///app/agent/[uuid]/about)

The script provides both private (owner-only) lookups and public (local chat) lookups using a simple prefix system.

--------------------------------------------------------------------

## How It Works

The script listens on channel 2 for commands. When you request a lookup:

1. The avatar is resolved via UUID or name.
2. The script requests:
   - DATA_NAME
   - DATA_BORN
3. It calculates account age using basic date math.
4. It prints a formatted info block either:
   - Privately to the owner (llOwnerSay)
   - Publicly to local chat (llSay(0)) if you use the "p" version of the command

The script also safely handles multiple simultaneous lookups.

--------------------------------------------------------------------

## Commands

ALL commands are issued on channel 2:

    /2 <command>

### PRIVATE COMMANDS (owner only)

These output ONLY to you.

Lookup by UUID:

    /2 lookup avatar <uuid>

Lookup by name:

    /2 lookup name <first> [last]

If no last name is provided, “Resident” is assumed automatically.

Example:

    /2 lookup name Hailey
    /2 lookup name Hailey Enfield
    /2 lookup name Hailey.Enfield

If the name is missing:

    Usage: lookup name <first> [last]

--------------------------------------------------------------------

## PUBLIC COMMANDS (visible to everyone nearby)

Commands beginning with “p” produce PUBLIC output in local chat.

Public lookup by UUID:

    /2 p lookup avatar <uuid>

Public lookup by name:

    /2 p lookup name <first> [last]

If missing arguments:

    Usage: p lookup name <first> [last]

--------------------------------------------------------------------

## Output Format

A successful lookup prints:

    Avatar:
    • Display Name: hails
    • Legacy Name: hailey.enfield
    • Account Age: 7297 days
    • UUID: 0fc458f0-50c4-4d6f-95a6-965be6e977ad
    • About: secondlife:///app/agent/0fc458f0-50c4-4d6f-95a6-965be6e977ad/about

Notes:
- Display Name is omitted if empty.
- PUBLIC commands send the above block via llSay(0).

--------------------------------------------------------------------

## Clearing Script State

Reset all pending lookups and internal data:

    /2 hails clear

You will see:

    Cleared pending lookups and state.
