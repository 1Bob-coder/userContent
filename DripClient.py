#!/usr/bin/python
import socket
import sys
import time
import threading
import binascii




# Function convertStatusToString()
# Purpose: Converts Status hex value to string.
# Input: Status hex value
# Output: String
#---------------------------------------------
def convertStatusToString(x):
    return {
        '0000' : 'OK',
        '0100' : 'BAD_CRC',
        '0200' : 'BAD_LENGTH',
        '0300' : 'BAD_IP_MSG',
        '0400' : 'NO_MATCH_UA',
        '0500' : 'BAD_TID',
        '0600' : 'NA'
        }[x]


# Function convertMsgTypeToString()
# Purpose: Converts MsgType value to string.
# Input: Number from 1-12
# Output: String
#---------------------------------------------
def convertMsgTypeToString(x):
    return {
        1 : 'RMT',
        2 : 'DIAG',
        3 : 'IP_ADDR',
        4 : 'MSP_MSG',
        5 : 'REBOOT',
        6 : 'BOOT_PARAMS',
        7 : 'FRONT_PANEL',
        8 : 'LAST_REPORT',
        9 : 'MSG_TYPE_STATS',
        10 : 'MSG_TYPE_DEBUG',
        11 : 'NEPTUNE_TEST',
        12 : 'UNSOLICITED'
    }[x]


# Function convertRemoteKey()
# Purpose: Converts int to Remote Key command.
# Input: An int from 1 to 53
# Output: A string for the key
#---------------------------------------------
def convertRemoteKey(x):
    return {
	      1: 'ARROW_RIGHT',
	      2: 'MUTE',
	      3: 'RED',
	      4: 'VOL_DOWN',
	      5: 'EXIT',
	      6: 'POWER',
	      7: 'VOL_UP',
	      8: 'GREEN',
	      9: 'DIGIT8',
	      10: 'DIGIT7',
	      11: 'CHAN_UP',
	      12: 'YELLOW',
	      13: 'PPV',
	      14: 'DIGIT9',
	      15: 'DIGIT1',
	      16: 'CHAN_DOWN',
	      17: 'DIGIT2',
	      18 :'DIGIT3',
	      19: 'BLUE',
	      20: 'OPTIONS',
	      21: 'LIST',
	      22: 'GO_BACK',
	      23: 'DIGIT4',
	      24: 'LAST_CHAN',
	      25: 'DIGIT5',
	      26: 'INTERESTS',
	      27: 'DIGIT6',
	      28: 'ENTER',
	      29: 'ARROW_LEFT',
	      30: 'GUIDE',
	      31: 'HELP',
	      32: 'ARROW_DOWN',
	      33: 'BROWSE',
	      34: 'FAVOURITES',
	      35: 'ARROW_UP',
	      36: 'DIGIT0',
	      37: 'SOURCE',
	      38: 'SELECT',
	      39: 'INFO',
	      40: 'FAST_FWD',
	      41: 'REWIND',
	      42: 'RECORD',
	      43: 'LOCKS',
	      44: 'PAUSE',
	      45: 'STOP',
	      46: 'PLAY',
	      47: 'SKIP_AHEAD',
	      48: 'SKIP_BACK',
	      49: 'ASPECT',
	      52: 'INTERACTIVE',
	      53: 'DEBUG_LOGS'
          }[x]



# Function calculateChecksum(x)
# Purpose: Calculates the checksum of a list of numbers.
# Input: List of numbers
# Output: Checksum
#---------------------------------------------
def calculateChecksum( values ):
       # Calculate the checksum
       checksum = 0
       for value in values:
           checksum = checksum - value
       while checksum < 0:
           checksum = checksum + 256    
       return checksum


# Function handleCommand()
# Purpose: Handles the 'wait' and 'send' commands from DRIP scripts.
# Input: A string of the following form (example):
#        wait 3000  (for 3000 ms)
#        send 1 23  (for remote, DRIP key 23)
#---------------------------------------------
def handleCommand( wordStr ):
   # split the string into a list
   wordlist = wordStr.split()

   # wait command in milliseconds
   if 'wait' in wordlist:
     waitTime = float(wordlist[1])
     print "pause", waitTime, "ms"
     time.sleep(waitTime/1000.0)

   # send command to DRIP Server
   if 'send' in wordlist:
     firstInt = int(wordlist[1])
     secondInt = int(wordlist[2])

     # Handle RCU Keypresses
     # e.g., send 1,33 -->  0 1 0 21 0 1 19 c4   Remote key 3
     #if convertMsgTypeToString(firstInt) == 'RMT' :  # RCU Keypress Commands
     if firstInt == 1 :  # RCU Keypress Commands
       print convertMsgTypeToString(firstInt), convertRemoteKey(secondInt)
       values = [0, 0, 0, 0, 0, 0, 0, 0]
       values[1] = firstInt   # MsgType = RMT
       values[5] = 1          # Body length = 1
       values[6] = secondInt  # Body = keycode

       # Handle Unsolicited Enable message.
       # e.g., send:1,53 -->  0 c 0 16 0 1 1 dc  Unsolicited Enable
       if secondInt == 53:  # Unsolicited Message
           values[1] = 12   # MsgType = 12 for Unsolicited
           values[6] = 1    # Enable = 1

       # Calculate the checksum
       values[7] = calculateChecksum(values)
       
       # Send command to DRIP Server
       arr = bytearray(values)
       sock.sendto(arr, (UDP_IP, UDP_PORT))

     #  Handle the reboot command
     #  e.g., send:22,2 --> 0 5 0 17 0 0 e4  Reboot Command
     if firstInt == 22:
       values = [0, 0, 0, 0, 0, 0, 0]
       values[1] = 5  # MsgType = 5 for Reboot command

       # Calculate the checksum
       values[6] = calculateChecksum(values)

       # Send command to DRIP Server
       arr = bytearray(values)
       sock.sendto(arr, (UDP_IP, UDP_PORT))

     #  Handle the Diag Info requests
     # e.g., send:5,14 --> 0 2 0 2 0 2 1 1 f8  Diag A.1 Request
     # e.g., send:5,15 --> 0 2 0 3 0 2 1 2 f6  Diag A.2 Request
     if firstInt == 5:
       values = [0, 2, 0, 0, 0, 2, 0, 0, 0] # MsgType = 2 for DiagA Request
       values[6] = 1        # Diag Screen A
       if secondInt == 14:  
           values[7] = 1    # Diag screen line 1
       if secondInt == 15:  
           values[7] = 2    # Diag screen line 2

       # Calculate the checksum
       values[8] = calculateChecksum(values)

       # Send command to DRIP Server
       arr = bytearray(values)
       sock.sendto(arr, (UDP_IP, UDP_PORT))

   return



# Function recvLoop()
# Purpose: Handles the recv command.  Blocking call, so in a separate task.
#---------------------------------------------
def recvLoop( ):
  while True:
    data = sock.recv(1024)
    TYPE = data[0:2]
    ID = data[2:4]
    STATUS = data[4:6]
    LENGTH = data[6:8]
    STATUS = STATUS.encode('hex')
    LENGTH = LENGTH.encode('hex')
    bodyLen = int(LENGTH,16)
    if bodyLen == 0:
       STATUS_STR = convertStatusToString(STATUS)
       print "  >>>>", STATUS_STR
    if bodyLen > 0:
       print "  ", data[8:8+bodyLen]
  return




# Main entry point
# Function: Parse a DRIP script and execute it.  Allows DRIP Scripts to be
# executed in Linux using Python.
# Inputs:  Filename of the DRIP Script
# Note:  The DRIP Script is created by the DRIP Client program.
#---------------------------------------------
length = int(len(sys.argv))
if length == 1 :
    print('Run a DRIP Script ')
    print('Useage: python DripClient.py filename')
    print('        where filename is any DRIP script file recorded by the DRIP_Client program')

else:
    fname = ' '
    UDP_IP = ' '
    UDP_PORT = 5002 # number
    loops = 1
    x = 1

    while x < length:
        if sys.argv[x] == '/f' or sys.argv[x] == '/F':
            fname = sys.argv[x+1] 
            print 'Filename =', fname
        if sys.argv[x] == '/i' or sys.argv[x] == '/I':
            UDP_IP = sys.argv[x+1] 
            print 'IP Address =', UDP_IP
        if sys.argv[x] == '/l' or sys.argv[x] == '/L':
            loops = int(sys.argv[x+1])
            print 'Number of Loops =', loops
        x = x+1

    # Make UDP Socket.
    sock = socket.socket(socket.AF_INET, # Internet
                         socket.SOCK_DGRAM) # UDP

    # Launch recvLoop() in a separate thread because it blocks on recv().
    t = threading.Thread(target=recvLoop)
    t.daemon = True
    t.start()

    # Read DRIP test script line by line.
    while loops:
      with open(fname,'r') as f:
        for line in f:
          # Split string in the space.  Makes two strings.
          for wordstr in line.split():
             # Change separation characters into spaces.
             wordstr = wordstr.replace(':',' ')
             wordstr = wordstr.replace(',',' ')
             wordstr = wordstr.replace('.','')
             wordstr = wordstr.replace(';',' ')
             # Send to handler
             handleCommand(wordstr)
      loops = loops - 1
      print 'Loops remaining =', loops
      f.close()

