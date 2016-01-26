#!/usr/bin/awk -f
BEGIN { FS=";" }
{ SUM += $5 }
END { print SUM }
