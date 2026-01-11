#!/bin/bash
# Stop hook for strayfiles-ping
# Reminds Claude to send a ping notification to the user

echo '{
  "decision": "block",
  "reason": "If the user asked to be notified when done, use the ping tool to send them a notification now.",
  "systemMessage": "Task complete - send ping notification if requested"
}'
exit 0
