EECS 314 Chess Project 
-------------------
Team Members: 
+ Matt McKee, <mwm67@case.edu> 
+ Patrick Landis, <pal25@case.edu>

Game State
==================
![Alt text](https://raw.github.com/pal25/eecs314/master/images/mips_state_machine.png "MIPS State Machine")

Python
==================
Python is responsible for:
+ Not maintaining state. Python will update state via message passing
+ Starting SPIM and redirect piping to Python
+ Starting first game
+ Writing/parsing messages

1[Alt text](https://raw.github.com/pal25/eecs314/master/images/python_state_machine.png "Python State Machine")

Game Message Passing
==================
NOTE: All bits are MSB->LSB and messages are sent are MSB->LSB

There are three types of messages:
+ **Move Message:** 00 | 3x64bits | \n
+ **Reset:** 01 | \n
+ **Victory:** 10 | 1bit | \n

The 3bits in the move message are divided up as follows: 
+ **MSB:** Is the piece there? (0=no, 1=yes)
+ **Middle Bit:** Team? (0=black, 1=red)
+ **LSB:** Rank? (0=pawn, 1=king)

Data Structure
=================
The game will consist of 3 64-bit arrays.
+ **1st Array:** Array with marks if a piece is at the location (0=no, 1=yes)
+ **2nd Array:** Array with marks for the team (0=black, 1=red)
+ **3rd Array:** Array with marks for the rank (0=pawn, 1=king)

AI Thoughts
================
Use Alpha/Beta search (hopefully) with the following metrics:
+ Can take piece (Jumps opponent)
+ Move to side of board (Jump proof)
+ Can king (Make it to top/bottom of board)
+ Block opponent jump (Opponent cant take a piece)
+ Wont be jumped (Opponent cant take this piece)