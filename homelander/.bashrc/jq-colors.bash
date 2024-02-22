#To configure alternative colors just set the JQ_COLORS environment variable to colon-delimited list of partial terminal escape sequences like "1;31", in this order:

#color for null
#color for false
#color for true
#color for numbers
#color for strings
#color for arrays
#color for objects
#The default color scheme is the same as setting "JQ_COLORS=1;30:0;39:0;39:0;39:0;32:1;39:1;39".

#This is not a manual for VT100/ANSI escapes. However, each of these color specifications should consist of two numbers separated by a semi-colon, where the first number is one of these:

#1 (bright)
#2 (dim)
#4 (underscore)
#5 (blink)
#7 (reverse)
#8 (hidden)
#and the second is one of these:

#30 (black)
#31 (red)
#32 (green)
#33 (yellow)
#34 (blue)
#35 (magenta)
#36 (cyan)
#37 (white)
export JQ_COLORS="1;31:2;31:2;32:0;39:0;32:1;39:1;39"
