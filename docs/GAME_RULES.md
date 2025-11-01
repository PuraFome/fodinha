# Fodinha Game Rules

## Overview

Fodinha is a popular Brazilian card game, similar to Truco. It's a trick-taking game where players bid on the number of tricks they expect to win in each round.

## Setup

- **Players**: 2-6 players
- **Deck**: 40 cards (4 suits × 10 ranks)
- **Cards per Round**: Varies from 1 to 10 cards, then back to 1

## Card Hierarchy

From lowest to highest value:
1. 4 (Four)
2. 5 (Five)
3. 6 (Six)
4. 7 (Seven)
5. Q (Queen/Dama)
6. J (Jack/Valete)
7. K (King/Rei)
8. A (Ace/Ás)
9. 2 (Two)
10. 3 (Three)

## Game Flow

### 1. Dealing

- The dealer shuffles the deck
- Cards are dealt to each player based on the current round number
- A trump card is revealed (determines the trump suit)
- The dealer position rotates each round

### 2. Bidding Phase

- Starting from the player to the left of the dealer
- Each player bids the number of tricks they think they'll win
- Bids range from 0 to the number of cards in hand
- The dealer's bid cannot make the total bids equal to the number of available tricks (to ensure someone will fail)

### 3. Playing Phase

- The player to the left of the dealer leads the first trick
- Players must follow suit if possible
- If unable to follow suit, any card may be played
- The highest card of the led suit wins, unless a trump card is played
- Trump cards beat all non-trump cards
- The winner of each trick leads the next trick

### 4. Scoring

After all tricks are played:

- **Made Bid**: If a player wins exactly their bid number of tricks, they score **10 + bid points**
  - Example: Bid 3, won 3 → Score 13 points
  
- **Missed Bid**: If a player wins more or fewer tricks than bid, they score **-5 points for each trick off**
  - Example: Bid 3, won 5 → Score -10 points (2 tricks × -5)
  - Example: Bid 3, won 1 → Score -10 points (2 tricks × -5)

### 5. Round Progression

The game progresses through rounds with increasing then decreasing cards:
- Round 1: 1 card
- Round 2: 2 cards
- ...
- Round 10: 10 cards
- Round 11: 9 cards
- ...
- Round 19: 1 card
- Round 20: Game ends

**Note**: The maximum round number depends on the number of players (fewer players = more rounds possible)

## Winning

The player with the highest score after all rounds wins the game.

## Strategy Tips

1. **Bid Carefully**: It's often better to bid conservatively, especially in early rounds
2. **Remember Trump**: Trump cards are powerful but limited
3. **Count Cards**: Keep track of which high cards have been played
4. **Watch Others**: Pay attention to other players' bids and plays
5. **Dealer Advantage**: The dealer has information advantage but also the constraint on bidding

## Variations

Different regions may have slight variations in:
- Scoring system
- Trump selection method
- Bidding rules
- Number of rounds

This implementation uses the most common ruleset.

## Example Game

### Round 1 (1 card each, 4 players)

**Trump**: ♥7

**Bidding**:
- Player 1: Bids 0
- Player 2: Bids 1
- Player 3: Bids 0
- Player 4 (dealer): Bids 0 (total = 1, which is valid)

**Playing**:
- Player 1 plays: ♦5
- Player 2 plays: ♠K (highest non-trump)
- Player 3 plays: ♣4
- Player 4 plays: ♥4 (trump, wins!)

**Scoring**:
- Player 1: Made bid (0) → **10 points**
- Player 2: Missed bid (0 instead of 1) → **-5 points**
- Player 3: Made bid (0) → **10 points**
- Player 4: Missed bid (1 instead of 0) → **-5 points**

## FAQ

**Q: Can I play any card if I can't follow suit?**
A: Yes, you can play any card from your hand.

**Q: What if two trump cards are played?**
A: The highest trump card wins.

**Q: Can I bid zero?**
A: Yes, bidding zero is allowed and can be strategic.

**Q: What happens if I disconnect during a game?**
A: Your spot may be taken by another player, or the game may be paused depending on server implementation.

**Q: Is there a time limit for bidding or playing?**
A: The current implementation doesn't enforce time limits, but servers may add this feature.
